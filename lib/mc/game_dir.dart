// Default game directory (`.minecraft`).
//
// Only provides the platform-conventional default; it does not guess or search
// elsewhere. A user-selected directory (standalone PCL / HMCL installs) comes
// from SettingsStore.
//
// Environment variables and platform names are injected so tests can pin the
// result for each platform.

import 'dart:io';

import 'paths.dart';

/// Windows：`%APPDATA%\.minecraft`；
/// Linux：`~/.minecraft`；
/// macOS：`~/Library/Application Support/minecraft`。
///
/// Falls back to `~/.minecraft` when the environment variable is missing;
/// when even the home directory is unavailable, returns the relative path
/// `.minecraft` (better than inventing a fake absolute path).
String defaultGameDir({
  Map<String, String>? environment,
  String? operatingSystem,
}) {
  final Map<String, String> env = environment ?? Platform.environment;
  final String os = operatingSystem ?? Platform.operatingSystem;
  final String? home = _firstNonEmpty(<String?>[
    env['HOME'],
    env['USERPROFILE'],
  ]);

  if (os == 'windows') {
    final String? appData = env['APPDATA'];
    if (appData != null && appData.trim().isNotEmpty) {
      return joinPath(appData, '.minecraft');
    }
  } else if (os == 'macos') {
    if (home != null) {
      return joinPath(home, 'Library/Application Support/minecraft');
    }
  }

  if (home != null) return joinPath(home, '.minecraft');
  return '.minecraft';
}

String? _firstNonEmpty(List<String?> values) {
  for (final String? value in values) {
    if (value != null && value.trim().isNotEmpty) return value;
  }
  return null;
}
