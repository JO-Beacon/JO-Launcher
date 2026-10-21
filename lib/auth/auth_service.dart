// Microsoft account sign-in: device code flow → Xbox Live → XSTS → Minecraft.
//
// Strictly follows the genuine-account chain; no offline or bypass entry point.
//
// Auth chain:
//   1. POST /consumers/oauth2/v2.0/devicecode   get user_code + device_code
//   2. POST /consumers/oauth2/v2.0/token        poll for Microsoft access_token + refresh_token
//   3. POST user.auth.xboxlive.com/user/authenticate
//   4. POST xsts.auth.xboxlive.com/xsts/authorize
//   5. POST api.minecraftservices.com/authentication/login_with_xbox
//   6. GET  api.minecraftservices.com/minecraft/profile
//
// Known external blocker: Mojang's application allowlist has not approved this
// app, so step 5 returns 403 `Invalid app registration`. Errors are surfaced
// as-is; nothing is swallowed and nothing bypasses the check.

import 'dart:convert';
import 'dart:io';

import 'account.dart';
import 'http_transport.dart';

/// Sign-in failure. `key` is a localization-table key; `args` are placeholder values.
class AuthException implements Exception {
  const AuthException(this.key, [this.args = const <String, Object>{}]);

  final String key;
  final Map<String, Object> args;

  @override
  String toString() => key;
}

/// The user cancelled (or closed the window).
class AuthCancelled implements Exception {
  const AuthCancelled();
}

/// Data returned by the first stage of the device-code flow.
class DeviceCodeInfo {
  const DeviceCodeInfo({
    required this.userCode,
    required this.deviceCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  /// Short code the user enters on the authorization page.
  final String userCode;

  /// Long polling code; never shown to the user.
  final String deviceCode;

  /// Authorization page URL.
  final String verificationUri;

  final int expiresIn;

  /// Polling interval in seconds.
  final int interval;
}

/// The UI depends only on this interface; tests substitute a fake implementation.
abstract class Authenticator {
  /// Runs the complete device-code sign-in. Calls [onCode] when the code is
  /// available; when [isCancelled] returns true, exits promptly with
  /// [AuthCancelled].
  Future<MinecraftAccount> loginWithDeviceCode({
    required void Function(DeviceCodeInfo info) onCode,
    required bool Function() isCancelled,
  });

  /// Silently refreshes with the refresh_token and exchanges a new Minecraft token.
  Future<MinecraftAccount> refresh(MinecraftAccount account);
}

/// The Microsoft application client_id **does not go into the repository**:
/// read the `JO_MS_CLIENT_ID` environment variable at runtime, or pass it at
/// build time.
/// `--dart-define=JO_MS_CLIENT_ID=...`。
const String _clientIdFromDefine = String.fromEnvironment('JO_MS_CLIENT_ID');

String _resolveClientId() {
  if (_clientIdFromDefine.trim().isNotEmpty) return _clientIdFromDefine;
  return Platform.environment['JO_MS_CLIENT_ID'] ?? '';
}

const String _scope = 'XboxLive.signin offline_access';
final Uri _deviceCodeUri = Uri.parse(
  'https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode',
);
final Uri _tokenUri = Uri.parse(
  'https://login.microsoftonline.com/consumers/oauth2/v2.0/token',
);
final Uri _xblUri = Uri.parse(
  'https://user.auth.xboxlive.com/user/authenticate',
);
final Uri _xstsUri = Uri.parse('https://xsts.auth.xboxlive.com/xsts/authorize');
final Uri _mcLoginUri = Uri.parse(
  'https://api.minecraftservices.com/authentication/login_with_xbox',
);
final Uri _profileUri = Uri.parse(
  'https://api.minecraftservices.com/minecraft/profile',
);

Future<void> _defaultSleep(Duration d) => Future<void>.delayed(d);

class AuthService implements Authenticator {
  AuthService({
    HttpTransport? transport,
    String? clientId,
    this.sleep = _defaultSleep,
  }) : _http = transport ?? IoHttpTransport(),
       clientId = (clientId ?? _resolveClientId()).trim();

  final HttpTransport _http;
  final String clientId;

  /// Poll wait. Tests use an implementation that does not wait.
  final Future<void> Function(Duration) sleep;

  @override
  Future<MinecraftAccount> loginWithDeviceCode({
    required void Function(DeviceCodeInfo info) onCode,
    required bool Function() isCancelled,
  }) async {
    _requireClientId();
    final DeviceCodeInfo info = await _requestDeviceCode();
    onCode(info);

    Duration wait = Duration(seconds: info.interval.clamp(1, 60));
    final DateTime deadline = DateTime.now().add(
      Duration(seconds: info.expiresIn),
    );
    while (true) {
      if (isCancelled()) throw const AuthCancelled();
      if (DateTime.now().isAfter(deadline)) {
        throw const AuthException('auth.error.timeout');
      }
      await sleep(wait);
      if (isCancelled()) throw const AuthCancelled();
      try {
        final MsTokens? tokens = await _pollToken(info.deviceCode);
        if (tokens != null) return await _exchange(tokens);
      } on _SlowDown {
        wait += const Duration(seconds: 5);
      }
    }
  }

  @override
  Future<MinecraftAccount> refresh(MinecraftAccount account) async {
    _requireClientId();
    final HttpResult response = await _postForm(_tokenUri, <String, String>{
      'client_id': clientId,
      'grant_type': 'refresh_token',
      'refresh_token': account.refreshToken,
      'scope': _scope,
    });
    final Map<String, Object?> json = _decode(response.body);
    if (!response.ok) {
      if (json['error'] == 'invalid_grant') {
        throw const AuthException('auth.error.refreshExpired');
      }
      throw AuthException('auth.error.refresh', <String, Object>{
        'detail': _detail(json, response.statusCode),
      });
    }
    final MsTokens? tokens = _tokensFrom(json);
    if (tokens == null) {
      throw const AuthException('auth.error.refreshIncomplete');
    }
    return _exchange(tokens);
  }

  /// Without a client_id, do not send a request: explain how to configure it
  /// instead of showing the user an HTTP 400.
  void _requireClientId() {
    if (clientId.isEmpty) {
      throw const AuthException('auth.error.noClientId');
    }
  }

  Future<DeviceCodeInfo> _requestDeviceCode() async {
    final HttpResult response = await _postForm(
      _deviceCodeUri,
      <String, String>{'client_id': clientId, 'scope': _scope},
    );
    final Map<String, Object?> json = _decode(response.body);
    if (!response.ok) {
      throw AuthException('auth.error.deviceCode', <String, Object>{
        'detail': _detail(json, response.statusCode),
      });
    }
    final Object? userCode = json['user_code'];
    final Object? deviceCode = json['device_code'];
    final Object? verificationUri = json['verification_uri'];
    final Object? expiresIn = json['expires_in'];
    final Object? interval = json['interval'];
    if (userCode is! String ||
        deviceCode is! String ||
        verificationUri is! String ||
        expiresIn is! num ||
        interval is! num) {
      throw const AuthException('auth.error.deviceCodeIncomplete');
    }
    return DeviceCodeInfo(
      userCode: userCode,
      deviceCode: deviceCode,
      verificationUri: verificationUri,
      expiresIn: expiresIn.toInt(),
      interval: interval.toInt(),
    );
  }

  /// Polls once. Returns null while pending; throws on rejection or expiry.
  Future<MsTokens?> _pollToken(String deviceCode) async {
    final HttpResult response = await _postForm(_tokenUri, <String, String>{
      'client_id': clientId,
      'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      'device_code': deviceCode,
    });
    final Map<String, Object?> json = _decode(response.body);
    if (response.ok) {
      final MsTokens? tokens = _tokensFrom(json);
      if (tokens == null) {
        throw const AuthException('auth.error.tokenIncomplete');
      }
      return tokens;
    }
    switch (json['error']) {
      case 'authorization_pending':
        return null;
      case 'slow_down':
        throw const _SlowDown();
      case 'authorization_declined':
        throw const AuthException('auth.error.declined');
      case 'expired_token':
        throw const AuthException('auth.error.codeExpired');
      case 'bad_verification_code':
        throw const AuthException('auth.error.codeInvalid');
    }
    throw AuthException('auth.error.ms', <String, Object>{
      'detail': _detail(json, response.statusCode),
    });
  }

  Future<MinecraftAccount> _exchange(MsTokens tokens) async {
    final XblToken xbl = await _xboxLive(tokens.accessToken);
    final XstsToken xsts = await _xsts(xbl);
    final McToken mc = await _minecraftLogin(xsts);
    final Profile profile = await _profile(mc.accessToken);
    return MinecraftAccount(
      name: profile.name,
      uuid: profile.id,
      refreshToken: tokens.refreshToken,
      accessToken: mc.accessToken,
      accessExpiresAt: DateTime.now().add(Duration(seconds: mc.expiresIn)),
    );
  }

  Future<XblToken> _xboxLive(String msAccessToken) async {
    final HttpResult response = await _postJson(_xblUri, <String, Object?>{
      'Properties': <String, Object?>{
        'AuthMethod': 'RPS',
        'SiteName': 'user.auth.xboxlive.com',
        'RpsTicket': 'd=$msAccessToken',
      },
      'RelyingParty': 'http://auth.xboxlive.com',
      'TokenType': 'JWT',
    }, xbl: true);
    final Map<String, Object?> json = _decode(response.body);
    final String? token = _string(json['Token']);
    final String? userHash = _userHash(json);
    if (!response.ok || token == null || userHash == null) {
      throw AuthException('auth.error.xbox', <String, Object>{
        'detail': _detail(json, response.statusCode),
      });
    }
    return XblToken(token: token, userHash: userHash);
  }

  Future<XstsToken> _xsts(XblToken xbl) async {
    final HttpResult response = await _postJson(_xstsUri, <String, Object?>{
      'Properties': <String, Object?>{
        'SandboxId': 'RETAIL',
        'UserTokens': <String>[xbl.token],
      },
      'RelyingParty': 'rp://api.minecraftservices.com/',
      'TokenType': 'JWT',
    }, xbl: true);
    final Map<String, Object?> json = _decode(response.body);
    if (response.statusCode == 401) {
      final Object? xerr = json['XErr'];
      if (xerr is num) {
        throw _xstsException(xerr.toInt());
      }
      throw const AuthException('auth.error.xboxRejected');
    }
    final String? token = _string(json['Token']);
    final String? userHash = _userHash(json);
    if (!response.ok || token == null || userHash == null) {
      throw AuthException('auth.error.xsts', <String, Object>{
        'detail': _detail(json, response.statusCode),
      });
    }
    return XstsToken(token: token, userHash: userHash);
  }

  Future<McToken> _minecraftLogin(XstsToken xsts) async {
    final HttpResult response = await _postJson(_mcLoginUri, <String, Object?>{
      'identityToken': 'XBL3.0 x=${xsts.userHash};${xsts.token}',
    });
    final Map<String, Object?> json = _decode(response.body);
    if (response.statusCode == 403) {
      final Object? message = json['errorMessage'];
      if (message is String && message.contains('Invalid app registration')) {
        throw const AuthException('auth.error.whitelist');
      }
      throw AuthException('auth.error.minecraftRejected', <String, Object>{
        'detail': message is String && message.isNotEmpty
            ? message
            : 'HTTP 403',
      });
    }
    if (!response.ok) {
      throw AuthException('auth.error.minecraft', <String, Object>{
        'detail': _detail(json, response.statusCode),
      });
    }
    final String? access = _string(json['access_token']);
    final Object? expires = json['expires_in'];
    if (access == null || expires is! num) {
      throw const AuthException('auth.error.minecraftTokenIncomplete');
    }
    return McToken(accessToken: access, expiresIn: expires.toInt());
  }

  Future<Profile> _profile(String accessToken) async {
    final HttpResult response = await _http.get(
      _profileUri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 404) {
      throw const AuthException('auth.error.noJavaEdition');
    }
    final Map<String, Object?> json = _decode(response.body);
    if (!response.ok) {
      throw AuthException('auth.error.profile', <String, Object>{
        'detail': _detail(json, response.statusCode),
      });
    }
    final String? id = _string(json['id']);
    final String? name = _string(json['name']);
    if (id == null || name == null) {
      throw const AuthException('auth.error.profileIncomplete');
    }
    return Profile(id: id, name: name);
  }

  Future<HttpResult> _postForm(Uri url, Map<String, String> form) {
    final String body = form.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeQueryComponent(e.key)}='
              '${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return _http.post(
      url,
      headers: const <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: body,
    );
  }

  Future<HttpResult> _postJson(
    Uri url,
    Map<String, Object?> json, {
    bool xbl = false,
  }) {
    return _http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (xbl) 'x-xbl-contract-version': '1',
      },
      body: jsonEncode(json),
    );
  }
}

class _SlowDown implements Exception {
  const _SlowDown();
}

class MsTokens {
  const MsTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
}

MsTokens? _tokensFrom(Map<String, Object?> json) {
  final String? access = _string(json['access_token']);
  final String? refresh = _string(json['refresh_token']);
  final Object? expires = json['expires_in'];
  if (access == null || refresh == null || expires is! num) return null;
  return MsTokens(
    accessToken: access,
    refreshToken: refresh,
    expiresIn: expires.toInt(),
  );
}

class XblToken {
  const XblToken({required this.token, required this.userHash});

  final String token;
  final String userHash;
}

class XstsToken {
  const XstsToken({required this.token, required this.userHash});

  final String token;
  final String userHash;
}

class McToken {
  const McToken({required this.accessToken, required this.expiresIn});

  final String accessToken;
  final int expiresIn;
}

class Profile {
  const Profile({required this.id, required this.name});

  final String id;
  final String name;
}

String? _userHash(Map<String, Object?> json) {
  final Object? claims = json['DisplayClaims'];
  if (claims is! Map) return null;
  final Object? xui = claims['xui'];
  if (xui is! List || xui.isEmpty) return null;
  final Object? first = xui.first;
  if (first is! Map) return null;
  return _string(first['uhs']);
}

AuthException _xstsException(int xerr) {
  return switch (xerr) {
    2148916233 => const AuthException('auth.error.xboxNoProfile'),
    2148916235 => const AuthException('auth.error.xboxRegion'),
    2148916238 => const AuthException('auth.error.xboxChild'),
    _ => AuthException('auth.error.xboxCode', <String, Object>{'xerr': xerr}),
  };
}

Map<String, Object?> _decode(String body) {
  try {
    final Object? raw = jsonDecode(body);
    if (raw is Map<String, Object?>) return raw;
  } catch (_) {
    // Treat non-JSON as an empty object; the caller reports by status code.
  }
  return const <String, Object?>{};
}

String? _msMessage(Map<String, Object?> json) {
  final String? description = _string(json['error_description']);
  if (description != null) return description;
  return _string(json['error']);
}

/// Error detail: use the server message when provided, otherwise fall back to
/// the HTTP status code.
String _detail(Map<String, Object?> json, int status) =>
    _msMessage(json) ?? 'HTTP $status';

String? _string(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
