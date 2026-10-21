// Actually starts a process: computes the plan, calls `Process.start`, and
// streams stdout/stderr into the log stream.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../auth/account.dart';
import '../mc/version.dart';
import '../mc/version_config.dart';
import 'java.dart';
import 'launch_error.dart';
import 'manifest.dart';
import 'plan.dart';

class GameProcess {
  GameProcess({
    required this.version,
    required this.process,
    required this.startedAt,
  }) {
    _bind();
  }

  final McVersion version;
  final Process process;
  final DateTime startedAt;

  final List<String> _lines = <String>[];
  final StreamController<String> _logs = StreamController<String>.broadcast();

  Stream<String> get logs => _logs.stream;
  List<String> get lines => List<String>.unmodifiable(_lines);
  Future<int> get exitCode => process.exitCode;

  void _bind() {
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_add);
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_add);
    unawaited(
      process.exitCode.then((int code) {
        _add('--- exit $code ---');
        if (!_logs.isClosed) _logs.close();
      }),
    );
  }

  void _add(String line) {
    _lines.add(line);
    if (!_logs.isClosed) _logs.add(line);
  }

  Future<void> stop() async {
    process.kill();
  }
}

class LaunchService {
  LaunchService({
    JavaFinder? javaFinder,
    LaunchContext? context,
    this.launcherVersion = '0.0.1',
    this.clientId = '',
  }) : _java = javaFinder ?? JavaFinder(),
       _context = context ?? LaunchContext.host();

  final JavaFinder _java;
  final LaunchContext _context;
  final String launcherVersion;
  final String clientId;

  /// Parses the manifest, finds Java and builds the command line without
  /// starting a process.
  Future<LaunchPlan> prepare({
    required String gameDir,
    required McVersion version,
    required MinecraftAccount account,
    required VersionConfig config,
  }) async {
    final VersionManifest manifest = await resolveManifest(
      gameDir,
      version.name,
    );
    final JavaRuntime java = await _java.find(
      manualPath: config.javaPath,
      gameDir: gameDir,
      requiredMajor: manifest.javaMajor,
    );
    return buildLaunchPlan(
      gameDir: gameDir,
      version: version,
      account: account,
      config: config,
      manifest: manifest,
      java: java,
      context: _context,
      launcherVersion: launcherVersion,
      clientId: clientId,
    );
  }

  Future<GameProcess> start({
    required String gameDir,
    required McVersion version,
    required MinecraftAccount account,
    required VersionConfig config,
  }) async {
    final LaunchPlan plan = await prepare(
      gameDir: gameDir,
      version: version,
      account: account,
      config: config,
    );
    try {
      final Process process = await Process.start(
        plan.executable,
        plan.arguments,
        workingDirectory: plan.workingDirectory,
      );
      return GameProcess(
        version: version,
        process: process,
        startedAt: DateTime.now(),
      );
    } catch (error) {
      throw LaunchException('launch.error.start', <String, Object>{
        'error': '$error',
      });
    }
  }
}
