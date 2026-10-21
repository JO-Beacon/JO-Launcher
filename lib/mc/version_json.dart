// Finds the version manifest. Scanning and launching share the same rules for
// folder name / unique json / case sensitivity.

import 'dart:io';

import 'paths.dart';

/// Finds the version manifest for this folder.
///
/// Normally `<folder name>.json`; some launchers rename it, so fall back to the
/// only `.json` in the folder, or one whose name differs only by case.
Future<File?> findVersionJson(Directory folder, String name) async {
  final File exact = File(joinPath(folder.path, '$name.json'));
  if (await exact.exists()) return exact;
  if (!await folder.exists()) return null;

  final List<File> jsons = <File>[];
  await for (final FileSystemEntity entity in folder.list(followLinks: true)) {
    if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
      jsons.add(entity);
    }
  }
  if (jsons.length == 1) return jsons.single;
  final String wanted = '$name.json'.toLowerCase();
  for (final File file in jsons) {
    if (baseName(file.path).toLowerCase() == wanted) return file;
  }
  return null;
}
