import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/privacy/privacy_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('privacy consent is device-level and versioned', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final PrivacyStore store = PrivacyStore(prefs);

    expect(store.accepted, isFalse);
    expect(store.acceptedAt, isNull);

    await store.accept();

    expect(store.accepted, isTrue);
    expect(prefs.getInt('privacy.version'), kPrivacyVersion);
    expect(store.acceptedAt, isNotNull);
  });
}
