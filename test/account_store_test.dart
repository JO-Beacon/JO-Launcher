import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/auth/account.dart';
import 'package:jolauncher/auth/account_store.dart';
import 'package:jolauncher/auth/secure_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemorySecureStore implements SecureStore {
  final Map<String, String> values = <String, String>{};
  bool failWrites = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('secure store unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

MinecraftAccount account() {
  return MinecraftAccount(
    name: 'Steve',
    uuid: '069a79f444e94726a5befca90e38aaf5',
    refreshToken: 'refresh-token',
    accessToken: 'access-token',
    accessExpiresAt: DateTime.utc(2030),
  );
}

void main() {
  late SharedPreferences prefs;
  late MemorySecureStore secure;
  late AccountStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    secure = MemorySecureStore();
    store = AccountStore(prefs, secure);
  });

  test('new account is written only to secure storage', () async {
    await store.save(account());

    final MinecraftAccount? loaded = await store.load();
    expect(loaded?.name, 'Steve');
    expect(loaded?.accessToken, 'access-token');
    expect(secure.values, contains('account.ms.secure'));
    expect(prefs.getString('account.ms'), isNull);
  });

  test('legacy account.ms migrates and plaintext is removed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'account.ms': jsonEncode(account().toJson()),
    });
    prefs = await SharedPreferences.getInstance();
    secure = MemorySecureStore();
    store = AccountStore(prefs, secure);

    final MinecraftAccount? loaded = await store.load();

    expect(loaded?.name, 'Steve');
    expect(secure.values, contains('account.ms.secure'));
    expect(prefs.getString('account.ms'), isNull);
  });

  test('failed migration keeps legacy data and the account', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'account.ms': jsonEncode(account().toJson()),
    });
    prefs = await SharedPreferences.getInstance();
    secure = MemorySecureStore()..failWrites = true;
    store = AccountStore(prefs, secure);

    final MinecraftAccount? loaded = await store.load();

    expect(loaded?.name, 'Steve');
    expect(prefs.getString('account.ms'), isNotNull);
    expect(secure.values, isEmpty);
  });

  test('deleting an account clears secure storage and legacy data', () async {
    await store.save(account());
    await store.delete();

    expect(await store.load(), isNull);
    expect(secure.values, isEmpty);
    expect(prefs.getString('account.ms'), isNull);
  });
}
