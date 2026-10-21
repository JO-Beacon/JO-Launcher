// Finds Java: manual path first, then JAVA_HOME, the runtime inside the game
// directory, common JDK install locations and PATH. Once found, runs
// `java -version` once to validate the major version.

import 'dart:io';

import '../mc/paths.dart';
import 'launch_error.dart';

class CommandResult {
  const CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract class CommandRunner {
  Future<CommandResult> run(String executable, List<String> arguments);
}

class IoCommandRunner implements CommandRunner {
  @override
  Future<CommandResult> run(String executable, List<String> arguments) async {
    final ProcessResult result = await Process.run(executable, arguments);
    return CommandResult(
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }
}

class JavaRuntime {
  const JavaRuntime({
    required this.path,
    required this.version,
    required this.major,
  });

  final String path;
  final String version;
  final int major;
}

class JavaFinder {
  JavaFinder({
    CommandRunner? runner,
    String? operatingSystem,
    Map<String, String>? environment,
  }) : _runner = runner ?? IoCommandRunner(),
       _os = operatingSystem ?? Platform.operatingSystem,
       _env = environment ?? Platform.environment;

  final CommandRunner _runner;
  final String _os;
  final Map<String, String> _env;

  bool get _isWindows => _os == 'windows';
  bool get _isMacOS => _os == 'macos';

  String get _javaName => _isWindows ? 'java.exe' : 'java';
  String get _javawName => _isWindows ? 'javaw.exe' : 'java';

  /// Runs `-version` and reads the version from its output. Returns null when
  /// the path does not exist or is not Java.
  Future<JavaRuntime?> probe(String path) async {
    if (!await File(path).exists()) return null;
    final CommandResult result;
    try {
      result = await _runner.run(path, const <String>['-version']);
    } catch (_) {
      return null;
    }
    final RegExpMatch? match = RegExp(
      r'version "([^"]+)"',
    ).firstMatch('${result.stdout}\n${result.stderr}');
    if (match == null) return null;
    final String version = match.group(1)!;
    final int? major = _majorOf(version);
    if (major == null) return null;
    return JavaRuntime(path: path, version: version, major: major);
  }

  /// Finds the most suitable Java.
  ///
  /// When [manualPath] is non-null, only it is accepted; [requiredMajor] is the
  /// major version required by the manifest.
  Future<JavaRuntime> find({
    String? manualPath,
    String? gameDir,
    int? requiredMajor,
  }) async {
    if (manualPath != null && manualPath.trim().isNotEmpty) {
      final String path = manualPath.trim();
      final JavaRuntime? runtime = await probe(path);
      if (runtime == null) {
        throw LaunchException('launch.error.javaPath', <String, Object>{
          'path': path,
        });
      }
      _checkMajor(runtime, requiredMajor);
      return runtime;
    }

    final List<JavaRuntime> found = <JavaRuntime>[];
    for (final String path in await _candidates(gameDir)) {
      final JavaRuntime? runtime = await probe(path);
      if (runtime != null) found.add(runtime);
    }
    if (found.isEmpty) {
      throw const LaunchException('launch.error.noJava');
    }
    found.sort((JavaRuntime a, JavaRuntime b) => b.major.compareTo(a.major));

    JavaRuntime chosen = found.first;
    if (requiredMajor != null) {
      final Iterable<JavaRuntime> exact = found.where(
        (JavaRuntime j) => j.major == requiredMajor,
      );
      if (exact.isNotEmpty) {
        chosen = exact.first;
      } else {
        final Iterable<JavaRuntime> newer = found.where(
          (JavaRuntime j) => j.major > requiredMajor,
        );
        if (newer.isNotEmpty) chosen = newer.last;
      }
    }
    _checkMajor(chosen, requiredMajor);
    return chosen;
  }

  void _checkMajor(JavaRuntime runtime, int? requiredMajor) {
    if (requiredMajor != null && runtime.major < requiredMajor) {
      throw LaunchException('launch.error.javaTooOld', <String, Object>{
        'required': requiredMajor,
        'found': runtime.major,
      });
    }
  }

  Future<List<String>> _candidates(String? gameDir) async {
    final Set<String> out = <String>{};

    void addBin(String home) {
      out.add(joinPath(joinPath(home, 'bin'), _javaName));
      out.add(joinPath(joinPath(home, 'bin'), _javawName));
    }

    final String? javaHome = _env['JAVA_HOME'];
    if (javaHome != null && javaHome.trim().isNotEmpty) {
      addBin(javaHome.trim());
    }

    if (gameDir != null && gameDir.trim().isNotEmpty) {
      final Directory runtime = Directory(joinPath(gameDir, 'runtime'));
      await _collectBin(runtime, out, maxDepth: 5);
    }

    if (_isWindows) {
      for (final String key in <String>[
        'ProgramFiles',
        'ProgramFiles(x86)',
        'LOCALAPPDATA',
      ]) {
        final String? root = _env[key];
        if (root == null || root.trim().isEmpty) continue;
        for (final String vendor in <String>[
          'Java',
          'Eclipse Adoptium',
          'Microsoft',
          'Zulu',
          'BellSoft',
          'Amazon Corretto',
          'Programs',
        ]) {
          await _collectBin(
            Directory(joinPath(root, vendor)),
            out,
            maxDepth: 3,
          );
        }
      }
    } else if (_isMacOS) {
      await _collectBin(
        Directory('/Library/Java/JavaVirtualMachines'),
        out,
        maxDepth: 3,
      );
    } else {
      await _collectBin(Directory('/usr/lib/jvm'), out, maxDepth: 2);
    }

    final String? pathVar = _env['PATH'] ?? _env['Path'];
    if (pathVar != null) {
      final String separator = _isWindows ? ';' : ':';
      for (final String entry in pathVar.split(separator)) {
        if (entry.trim().isEmpty) continue;
        out.add(joinPath(entry.trim(), _javaName));
      }
    }

    // Keep only files that exist so later checks do not spawn a process for each.
    final List<String> files = <String>[];
    for (final String path in out) {
      if (await File(path).exists()) files.add(path);
    }
    return files;
  }

  /// Finds `bin/java` under a directory (only a few levels deep, to avoid
  /// scanning the whole disk).
  Future<void> _collectBin(
    Directory root,
    Set<String> out, {
    int maxDepth = 2,
  }) async {
    if (maxDepth < 0) return;
    if (!await root.exists()) return;
    try {
      await for (final FileSystemEntity entity in root.list(
        followLinks: false,
      )) {
        if (entity is File) {
          final String name = baseName(entity.path);
          if (name == _javaName || name == _javawName) {
            // Only accept files under bin/, not other executables bundled nearby.
            if (baseName(File(entity.path).parent.path) == 'bin') {
              out.add(entity.path);
            }
          }
        } else if (entity is Directory) {
          await _collectBin(entity, out, maxDepth: maxDepth - 1);
        }
      }
    } catch (_) {
      // Skip directories without permission.
    }
  }

  static int? _majorOf(String version) {
    final List<String> parts = version.split(RegExp(r'[._+-]'));
    if (parts.isEmpty) return null;
    if (parts[0] == '1' && parts.length > 1) {
      return int.tryParse(parts[1]);
    }
    return int.tryParse(parts[0]);
  }
}
