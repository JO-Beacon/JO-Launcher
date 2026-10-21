import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/auth/account.dart';
import 'package:jolauncher/auth/auth_service.dart';
import 'package:jolauncher/auth/http_transport.dart';

/// Authentication-chain regression: all fake responses, no network.
///
/// Covers: device-code polling, slow_down interval, cancellation, XSTS error
/// codes, Mojang allowlist 403, and refresh_token renewal.
void main() {
  const String deviceCodeUrl =
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode';
  const String tokenUrl =
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/token';
  const String xblUrl = 'https://user.auth.xboxlive.com/user/authenticate';
  const String xstsUrl = 'https://xsts.auth.xboxlive.com/xsts/authorize';
  const String mcLoginUrl =
      'https://api.minecraftservices.com/authentication/login_with_xbox';
  const String profileUrl =
      'https://api.minecraftservices.com/minecraft/profile';

  HttpResult json(Map<String, Object?> body, {int status = 200}) {
    return HttpResult(status, jsonEncode(body));
  }

  final Map<String, Object?> deviceCodeJson = <String, Object?>{
    'user_code': 'ABCD-EFGH',
    'device_code': 'device-code',
    'verification_uri': 'https://microsoft.com/devicelogin',
    'expires_in': 900,
    'interval': 1,
  };
  final Map<String, Object?> msTokensJson = <String, Object?>{
    'access_token': 'ms-access',
    'refresh_token': 'ms-refresh',
    'expires_in': 3600,
  };
  final Map<String, Object?> xblJson = <String, Object?>{
    'Token': 'xbl-token',
    'DisplayClaims': <String, Object?>{
      'xui': <Object?>[
        <String, Object?>{'uhs': 'uhs-1'},
      ],
    },
  };
  final Map<String, Object?> xstsJson = <String, Object?>{
    'Token': 'xsts-token',
    'DisplayClaims': <String, Object?>{
      'xui': <Object?>[
        <String, Object?>{'uhs': 'uhs-1'},
      ],
    },
  };
  final Map<String, Object?> mcJson = <String, Object?>{
    'access_token': 'mc-access',
    'expires_in': 86400,
  };
  final Map<String, Object?> profileJson = <String, Object?>{
    'id': '069a79f444e94726a5befca90e38aaf5',
    'name': 'Steve',
  };

  /// One complete successful chain, with individual steps overridable.
  FakeTransport successTransport({
    Map<String, List<HttpResult>> overrides =
        const <String, List<HttpResult>>{},
  }) {
    final Map<String, List<HttpResult>> queues = <String, List<HttpResult>>{
      deviceCodeUrl: <HttpResult>[json(deviceCodeJson)],
      tokenUrl: <HttpResult>[json(msTokensJson)],
      xblUrl: <HttpResult>[json(xblJson)],
      xstsUrl: <HttpResult>[json(xstsJson)],
      mcLoginUrl: <HttpResult>[json(mcJson)],
      profileUrl: <HttpResult>[json(profileJson)],
      ...overrides,
    };
    return FakeTransport(queues);
  }

  test('device code + polling + full chain', () async {
    final FakeTransport transport = successTransport(
      overrides: <String, List<HttpResult>>{
        tokenUrl: <HttpResult>[
          json(<String, Object?>{
            'error': 'authorization_pending',
          }, status: 400),
          json(msTokensJson),
        ],
      },
    );
    final AuthService auth = AuthService(
      transport: transport,
      clientId: 'test-client',
      sleep: (Duration _) async {},
    );

    DeviceCodeInfo? code;
    final MinecraftAccount account = await auth.loginWithDeviceCode(
      onCode: (DeviceCodeInfo info) => code = info,
      isCancelled: () => false,
    );

    expect(code!.userCode, 'ABCD-EFGH');
    expect(code!.verificationUri, 'https://microsoft.com/devicelogin');
    expect(account.name, 'Steve');
    expect(account.uuid, '069a79f444e94726a5befca90e38aaf5');
    expect(account.refreshToken, 'ms-refresh');
    expect(account.accessToken, 'mc-access');
    expect(account.isExpired, isFalse);

    final FakeCall mcCall = transport.calls.firstWhere(
      (FakeCall c) => c.url.toString() == mcLoginUrl,
    );
    expect(
      (jsonDecode(mcCall.body!) as Map<String, Object?>)['identityToken'],
      'XBL3.0 x=uhs-1;xsts-token',
    );
    final FakeCall profileCall = transport.calls.firstWhere(
      (FakeCall c) => c.url.toString() == profileUrl,
    );
    expect(profileCall.headers['Authorization'], 'Bearer mc-access');
  });

  test('slow_down adds 5 seconds to the wait', () async {
    final FakeTransport transport = successTransport(
      overrides: <String, List<HttpResult>>{
        tokenUrl: <HttpResult>[
          json(<String, Object?>{'error': 'slow_down'}, status: 400),
          json(msTokensJson),
        ],
      },
    );
    final List<Duration> waits = <Duration>[];
    final AuthService auth = AuthService(
      transport: transport,
      clientId: 'test-client',
      sleep: (Duration d) async => waits.add(d),
    );

    await auth.loginWithDeviceCode(onCode: (_) {}, isCancelled: () => false);

    expect(waits, <Duration>[
      const Duration(seconds: 1),
      const Duration(seconds: 6),
    ]);
  });

  test('cancellation stops polling', () async {
    final FakeTransport transport = successTransport();
    final AuthService auth = AuthService(
      transport: transport,
      clientId: 'test-client',
      sleep: (Duration _) async {},
    );

    await expectLater(
      auth.loginWithDeviceCode(onCode: (_) {}, isCancelled: () => true),
      throwsA(isA<AuthCancelled>()),
    );
    expect(
      transport.calls.where((FakeCall c) => c.url.toString() == tokenUrl),
      isEmpty,
    );
  });

  test('authorization page denial is reported', () async {
    final FakeTransport transport = successTransport(
      overrides: <String, List<HttpResult>>{
        tokenUrl: <HttpResult>[
          json(<String, Object?>{
            'error': 'authorization_declined',
          }, status: 400),
        ],
      },
    );
    final AuthService auth = AuthService(
      transport: transport,
      clientId: 'test-client',
      sleep: (Duration _) async {},
    );

    await expectLater(
      auth.loginWithDeviceCode(onCode: (_) {}, isCancelled: () => false),
      throwsA(
        isA<AuthException>().having(
          (AuthException e) => e.key,
          'key',
          'auth.error.declined',
        ),
      ),
    );
  });

  test('XSTS reports no Xbox account', () async {
    final FakeTransport transport = successTransport(
      overrides: <String, List<HttpResult>>{
        xstsUrl: <HttpResult>[
          json(<String, Object?>{'XErr': 2148916233}, status: 401),
        ],
      },
    );
    final AuthService auth = AuthService(
      transport: transport,
      clientId: 'test-client',
      sleep: (Duration _) async {},
    );

    await expectLater(
      auth.loginWithDeviceCode(onCode: (_) {}, isCancelled: () => false),
      throwsA(
        isA<AuthException>().having(
          (AuthException e) => e.key,
          'key',
          'auth.error.xboxNoProfile',
        ),
      ),
    );
  });

  test('Mojang allowlist 403 is reported as an unapproved app', () async {
    final FakeTransport transport = successTransport(
      overrides: <String, List<HttpResult>>{
        mcLoginUrl: <HttpResult>[
          json(<String, Object?>{
            'errorMessage': 'Invalid app registration',
          }, status: 403),
        ],
      },
    );
    final AuthService auth = AuthService(
      transport: transport,
      clientId: 'test-client',
      sleep: (Duration _) async {},
    );

    await expectLater(
      auth.loginWithDeviceCode(onCode: (_) {}, isCancelled: () => false),
      throwsA(
        isA<AuthException>().having(
          (AuthException e) => e.key,
          'key',
          'auth.error.whitelist',
        ),
      ),
    );
  });

  test('account does not own Minecraft: Java Edition', () async {
    final FakeTransport transport = successTransport(
      overrides: <String, List<HttpResult>>{
        profileUrl: <HttpResult>[const HttpResult(404, '{}')],
      },
    );
    final AuthService auth = AuthService(
      transport: transport,
      clientId: 'test-client',
      sleep: (Duration _) async {},
    );

    await expectLater(
      auth.loginWithDeviceCode(onCode: (_) {}, isCancelled: () => false),
      throwsA(
        isA<AuthException>().having(
          (AuthException e) => e.key,
          'key',
          'auth.error.noJavaEdition',
        ),
      ),
    );
  });

  test('refresh_token renewal exchanges a new Minecraft token', () async {
    final FakeTransport transport = successTransport(
      overrides: <String, List<HttpResult>>{
        tokenUrl: <HttpResult>[
          json(<String, Object?>{
            'access_token': 'ms-access-2',
            'refresh_token': 'ms-refresh-2',
            'expires_in': 3600,
          }),
        ],
        mcLoginUrl: <HttpResult>[
          json(<String, Object?>{
            'access_token': 'mc-access-2',
            'expires_in': 86400,
          }),
        ],
      },
    );
    final AuthService auth = AuthService(
      transport: transport,
      clientId: 'test-client',
      sleep: (Duration _) async {},
    );
    final MinecraftAccount old = MinecraftAccount(
      name: 'Steve',
      uuid: '069a79f444e94726a5befca90e38aaf5',
      refreshToken: 'ms-refresh',
      accessToken: 'old',
      accessExpiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    final MinecraftAccount fresh = await auth.refresh(old);

    expect(fresh.accessToken, 'mc-access-2');
    expect(fresh.refreshToken, 'ms-refresh-2');
    expect(fresh.isExpired, isFalse);
    final FakeCall tokenCall = transport.calls.firstWhere(
      (FakeCall c) => c.url.toString() == tokenUrl,
    );
    expect(tokenCall.body, contains('grant_type=refresh_token'));
    expect(tokenCall.body, contains('refresh_token=ms-refresh'));
  });

  test('expired refresh_token asks the user to sign in again', () async {
    final FakeTransport transport = FakeTransport(<String, List<HttpResult>>{
      tokenUrl: <HttpResult>[
        json(<String, Object?>{'error': 'invalid_grant'}, status: 400),
      ],
    });
    final AuthService auth = AuthService(
      transport: transport,
      clientId: 'test-client',
      sleep: (Duration _) async {},
    );

    await expectLater(
      auth.refresh(
        MinecraftAccount(
          name: 'Steve',
          uuid: 'uuid',
          refreshToken: 'dead',
          accessToken: 'old',
          accessExpiresAt: DateTime.now(),
        ),
      ),
      throwsA(
        isA<AuthException>().having(
          (AuthException e) => e.key,
          'key',
          'auth.error.refreshExpired',
        ),
      ),
    );
  });

  test('missing client_id explains how to configure it', () async {
    final AuthService auth = AuthService(
      transport: FakeTransport(<String, List<HttpResult>>{}),
      clientId: '',
      sleep: (Duration _) async {},
    );

    await expectLater(
      auth.loginWithDeviceCode(onCode: (_) {}, isCancelled: () => false),
      throwsA(
        isA<AuthException>().having(
          (AuthException e) => e.key,
          'key',
          'auth.error.noClientId',
        ),
      ),
    );
  });

  group('Account JSON', () {
    test('round-trips through save and load', () {
      final MinecraftAccount account = MinecraftAccount(
        name: 'Steve',
        uuid: '069a79f444e94726a5befca90e38aaf5',
        refreshToken: 'r',
        accessToken: 'a',
        accessExpiresAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );
      final MinecraftAccount? back = MinecraftAccount.fromJson(
        account.toJson(),
      );
      expect(back, isNotNull);
      expect(back!.name, 'Steve');
      expect(back.uuid, account.uuid);
      expect(back.refreshToken, 'r');
      expect(back.accessToken, 'a');
      expect(back.accessExpiresAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });

    test('missing fields or invalid time return null', () {
      expect(MinecraftAccount.fromJson(null), isNull);
      expect(MinecraftAccount.fromJson(<String, Object?>{'name': 'x'}), isNull);
      expect(
        MinecraftAccount.fromJson(<String, Object?>{
          'name': 'x',
          'uuid': 'u',
          'refreshToken': 'r',
          'accessToken': 'a',
          'accessExpiresAt': 'not-a-date',
        }),
        isNull,
      );
    });
  });
}

class FakeCall {
  const FakeCall({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
  });

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String? body;
}

class FakeTransport implements HttpTransport {
  FakeTransport(this.queues);

  final Map<String, List<HttpResult>> queues;
  final List<FakeCall> calls = <FakeCall>[];

  HttpResult _take(Uri url) {
    final List<HttpResult>? queue = queues[url.toString()];
    if (queue == null || queue.isEmpty) {
      throw StateError('no response prepared for $url');
    }
    return queue.removeAt(0);
  }

  @override
  Future<HttpResult> post(
    Uri url, {
    Map<String, String> headers = const <String, String>{},
    String? body,
  }) async {
    calls.add(FakeCall(method: 'POST', url: url, headers: headers, body: body));
    return _take(url);
  }

  @override
  Future<HttpResult> get(
    Uri url, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    calls.add(FakeCall(method: 'GET', url: url, headers: headers, body: null));
    return _take(url);
  }
}
