// Local record of privacy consent.
//
// Consent is device/app-level, not tied to a Microsoft account: switching
// accounts under the same Windows user does not require consent again, while
// a new privacy-policy version does.

import 'package:shared_preferences/shared_preferences.dart';

const int kPrivacyVersion = 1;

class PrivacyStore {
  const PrivacyStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _kVersion = 'privacy.version';
  static const String _kAcceptedAt = 'privacy.acceptedAt';

  static Future<PrivacyStore> open() async =>
      PrivacyStore(await SharedPreferences.getInstance());

  bool get accepted => _prefs.getInt(_kVersion) == kPrivacyVersion;

  DateTime? get acceptedAt {
    final String? raw = _prefs.getString(_kAcceptedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> accept() async {
    await _prefs.setInt(_kVersion, kPrivacyVersion);
    await _prefs.setString(
      _kAcceptedAt,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
