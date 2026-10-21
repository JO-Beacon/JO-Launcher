import 'package:shared_preferences/shared_preferences.dart';

import 'tokens.dart';

/// Settings persistence (local storage).
///
/// Currently stores five things: appearance, language, rail width, game
/// directory and current version. Sign-in state and other modules can be added
/// as they are connected.
class SettingsStore {
  const SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _kDark = 'appearance.dark';
  static const String _kFollow = 'ui.followSystem';
  static const String _kLocale = 'ui.locale';
  static const String _kRailW = 'layout.railW';
  static const String _kGameDir = 'mc.dir';
  static const String _kCurrentVersion = 'mc.version';

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());

  LauncherSettings load() {
    return LauncherSettings(
      isDark: _prefs.getBool(_kDark) ?? true,
      followSystem: _prefs.getBool(_kFollow) ?? false,
      locale: _prefs.getString(_kLocale) ?? 'system',
    );
  }

  Future<void> save(LauncherSettings s) async {
    await _prefs.setBool(_kDark, s.isDark);
    await _prefs.setBool(_kFollow, s.followSystem);
    await _prefs.setString(_kLocale, s.locale);
  }

  /// Rail width (from the splitter). Null means the UI uses its default.
  ///
  /// This is the width the user **wants**: drawing shrinks it when the window
  /// is narrow, and it can be restored when the window grows again.
  double? loadRailW() => _prefs.getDouble(_kRailW);

  Future<void> saveRailW(double width) async {
    await _prefs.setDouble(_kRailW, width);
  }

  /// Game directory selected by the user. Null means the UI uses the system default.
  String? loadGameDir() {
    final String? dir = _prefs.getString(_kGameDir);
    if (dir == null || dir.trim().isEmpty) return null;
    return dir;
  }

  Future<void> saveGameDir(String dir) async {
    await _prefs.setString(_kGameDir, dir);
  }

  /// Current version name. Null when nothing was selected.
  String? loadCurrentVersion() {
    final String? name = _prefs.getString(_kCurrentVersion);
    if (name == null || name.trim().isEmpty) return null;
    return name;
  }

  /// Stores the current version; null clears it (used when the game directory changes).
  Future<void> saveCurrentVersion(String? name) async {
    if (name == null) {
      await _prefs.remove(_kCurrentVersion);
    } else {
      await _prefs.setString(_kCurrentVersion, name);
    }
  }
}
