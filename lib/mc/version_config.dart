// Per-version settings: `<version dir>/jolauncher.json`.
//
// A version is one game directory (`versions/<name>/`). Settings follow the
// directory, so two versions on the same machine can use different Java,
// memory and JVM arguments.
//
// The file is meant to be read and edited by humans, so:
//   · write with 2-space indentation;
//   · **preserve unknown fields** when reading and write them back;
//   · write `.tmp` first and rename, so a power loss cannot leave half a file;
//   · fall back to defaults when the file is broken, without discarding the version.

import 'dart:convert';
import 'dart:io';

import 'paths.dart';

class VersionConfig {
  const VersionConfig({
    this.javaPath,
    this.minMemoryMb,
    this.maxMemoryMb,
    this.jvmArgs = '',
    this.raw = const <String, Object?>{},
  });

  /// Config file name. **Do not abbreviate.**
  static const String fileName = 'jolauncher.json';

  /// File format version.
  static const int schema = 1;

  /// Java executable path. null = automatic.
  final String? javaPath;

  /// Minimum / maximum memory (MB). null = automatic.
  final int? minMemoryMb;
  final int? maxMemoryMb;

  /// JVM arguments as one space-separated string. Empty = none.
  final String jvmArgs;

  /// All fields from the file, including unknown ones; preserved on write.
  final Map<String, Object?> raw;

  /// Reads from JSON. Missing fields or wrong types fall back to automatic.
  factory VersionConfig.parse(Map<String, Object?> json) {
    int? memory(Object? value) {
      if (value is num && value >= 1) return value.toInt();
      return null;
    }

    final Object? java = json['javaPath'];
    final String? javaPath = java is String && java.trim().isNotEmpty
        ? java.trim()
        : null;

    final Object? args = json['jvmArgs'];
    String jvmArgs = '';
    if (args is String) {
      jvmArgs = args.trim();
    } else if (args is List) {
      jvmArgs = args.whereType<String>().join(' ').trim();
    }

    return VersionConfig(
      javaPath: javaPath,
      minMemoryMb: memory(json['minMemoryMb']),
      maxMemoryMb: memory(json['maxMemoryMb']),
      jvmArgs: jvmArgs,
      raw: json,
    );
  }

  /// Reads settings from a version directory. Missing file, read failure or
  /// invalid JSON all return defaults.
  static Future<VersionConfig> read(String versionDir) async {
    final File file = File(joinPath(versionDir, fileName));
    try {
      if (!await file.exists()) return const VersionConfig();
      final Object? raw = jsonDecode(await file.readAsString());
      if (raw is Map<String, Object?>) return VersionConfig.parse(raw);
    } catch (_) {
      // A broken config must not block startup.
    }
    return const VersionConfig();
  }

  /// Writes back to the version directory, preserving unknown fields.
  Future<void> write(String versionDir) async {
    final File target = File(joinPath(versionDir, fileName));
    final File temp = File('${target.path}.tmp');
    final Map<String, Object?> json = <String, Object?>{
      ...raw,
      'schema': schema,
      'javaPath': javaPath,
      'minMemoryMb': minMemoryMb,
      'maxMemoryMb': maxMemoryMb,
      'jvmArgs': jvmArgs,
    };
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await temp.writeAsString('${encoder.convert(json)}\n', flush: true);
    await temp.rename(target.path);
  }
}

/// Reads a version's settings by directory.
Future<VersionConfig> readVersionConfig(String versionDir) =>
    VersionConfig.read(versionDir);

/// Writes a version's settings by directory. Re-reads before writing so
/// unknown fields changed elsewhere are preserved.
Future<void> saveVersionConfig(String versionDir, VersionConfig config) async {
  final VersionConfig onDisk = await VersionConfig.read(versionDir);
  await VersionConfig(
    javaPath: config.javaPath,
    minMemoryMb: config.minMemoryMb,
    maxMemoryMb: config.maxMemoryMb,
    jvmArgs: config.jvmArgs,
    raw: onDisk.raw,
  ).write(versionDir);
}
