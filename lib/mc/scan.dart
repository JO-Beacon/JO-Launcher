// Scans `<game dir>/versions` and reads every folder as a version.
//
// Read-only: never writes to or modifies the game directory.

import 'dart:convert';
import 'dart:io';

import 'paths.dart';
import 'version.dart';
import 'version_config.dart';
import 'version_json.dart';

/// Result of one scan.
class VersionScanResult {
  const VersionScanResult({
    required this.versionsDir,
    required this.exists,
    required this.versions,
    required this.broken,
  });

  /// Directory actually scanned: `<game dir>/versions`.
  final String versionsDir;

  /// Whether the `versions` directory exists.
  final bool exists;

  /// Parsed versions, newest first.
  final List<McVersion> versions;

  /// Folders whose manifest could not be read: missing `.json`, invalid JSON
  /// or unreadable. They are not passed off as versions and are not silently
  /// dropped; the UI reports how many there are.
  final List<String> broken;
}

/// Scans `versions` under [gameDir].
///
/// A missing directory returns an empty result with `exists: false` instead of
/// throwing; “no game installed” is a normal state, not an error.
Future<VersionScanResult> scanVersions(String gameDir) async {
  final String versionsPath = joinPath(gameDir, 'versions');
  final Directory versionsDir = Directory(versionsPath);
  if (!await versionsDir.exists()) {
    return VersionScanResult(
      versionsDir: versionsPath,
      exists: false,
      versions: const <McVersion>[],
      broken: const <String>[],
    );
  }

  final List<Directory> folders = <Directory>[];
  // Let permission errors propagate: the UI can show the reason instead of
  // pretending there are no versions.
  await for (final FileSystemEntity entity in versionsDir.list(
    followLinks: true,
  )) {
    if (entity is Directory) folders.add(entity);
  }

  final List<McVersion> versions = <McVersion>[];
  final List<String> broken = <String>[];
  for (final Directory folder in folders) {
    final String name = baseName(folder.path);
    final File? manifest = await findVersionJson(folder, name);
    if (manifest == null) {
      broken.add(name);
      continue;
    }
    try {
      final Object? raw = jsonDecode(await manifest.readAsString());
      if (raw is! Map<String, Object?>) {
        broken.add(name);
        continue;
      }
      versions.add(
        McVersion.fromManifest(
          raw,
          name: name,
          dir: folder.path,
          config: await VersionConfig.read(folder.path),
        ),
      );
    } catch (_) {
      // Unreadable / invalid JSON / unparseable structure: only this folder
      // is marked broken.
      broken.add(name);
    }
  }

  versions.sort(_newestFirst);
  broken.sort();
  return VersionScanResult(
    versionsDir: versionsPath,
    exists: true,
    versions: versions,
    broken: broken,
  );
}

/// Newest first; entries without `releaseTime` go last, then by name.
int _newestFirst(McVersion a, McVersion b) {
  final DateTime? ta = a.releaseTime;
  final DateTime? tb = b.releaseTime;
  if (ta != null && tb != null) {
    final int byTime = tb.compareTo(ta);
    if (byTime != 0) return byTime;
  } else if (ta != null) {
    return -1;
  } else if (tb != null) {
    return 1;
  }
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
