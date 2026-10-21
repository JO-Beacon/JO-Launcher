// Local account storage.
//
// The complete account record (name, UUID, tokens and expiry) is written to
// the system secure store instead of plaintext shared_preferences. The legacy
// `account.ms` key is migrated on first read and removed after a successful
// migration.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'account.dart';
import 'secure_store.dart';

class AccountStore {
  const AccountStore(this._prefs, this._secure);

  final SharedPreferences _prefs;
  final SecureStore _secure;

  static const String _kLegacy = 'account.ms';
  static const String _kSecure = 'account.ms.secure';

  static Future<AccountStore> open() async => AccountStore(
    await SharedPreferences.getInstance(),
    const PlatformSecureStore(),
  );

  /// Reads the last signed-in account. Falls back to the legacy plaintext
  /// record when the secure store has no account yet.
  Future<MinecraftAccount?> load() async {
    String? raw;
    try {
      raw = await _secure.read(_kSecure);
    } catch (_) {
      // If the secure store is temporarily unavailable, still try the legacy
      // record instead of dropping the account.
    }
    final MinecraftAccount? secure = _parse(raw);
    if (secure != null) return secure;

    final MinecraftAccount? legacy = _parse(_prefs.getString(_kLegacy));
    if (legacy == null) return null;

    // Migrate only after the secure write succeeds; remove the old plaintext
    // key afterwards.
    try {
      await _secure.write(_kSecure, jsonEncode(legacy.toJson()));
      await _prefs.remove(_kLegacy);
    } catch (_) {
      // Keep the legacy record and return the account; retry next launch.
    }
    return legacy;
  }

  /// Saves an account; null means sign out and clear the local account record.
  Future<void> save(MinecraftAccount? account) async {
    if (account == null) {
      await delete();
      return;
    }
    await _secure.write(_kSecure, jsonEncode(account.toJson()));
    await _prefs.remove(_kLegacy);
  }

  /// Deletes the account and local account data. Game files and version
  /// settings are outside this scope.
  Future<void> delete() async {
    await _secure.delete(_kSecure);
    await _prefs.remove(_kLegacy);
  }

  MinecraftAccount? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return MinecraftAccount.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }
}
