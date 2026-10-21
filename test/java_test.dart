import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/launch/java.dart';
import 'package:jolauncher/launch/launch_error.dart';
import 'package:jolauncher/mc/paths.dart';

/// Java detection: version parsing, manual path, automatic runtime lookup, too-old version.
void main() {
  test('parses java -version', () async {
    final Directory dir = await Directory.systemTemp.createTemp(
      'jolauncher-java-',
    );
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final String path = joinPath(dir.path, 'java.exe');
    await File(path).writeAsString('fake');

    final JavaFinder finder = JavaFinder(
      runner: FakeRunner('openjdk version "17.0.8" 2023-07-18'),
      operatingSystem: 'windows',
      environment: const <String, String>{},
    );
    final JavaRuntime? runtime = await finder.probe(path);
    expect(runtime, isNotNull);
    expect(runtime!.major, 17);
    expect(runtime.version, '17.0.8');

    final JavaFinder old = JavaFinder(
      runner: FakeRunner('java version "1.8.0_402"'),
      operatingSystem: 'windows',
      environment: const <String, String>{},
    );
    expect((await old.probe(path))!.major, 8);
  });

  test('finds runtime inside the game directory automatically', () async {
    final Directory game = await Directory.systemTemp.createTemp(
      'jolauncher-game-',
    );
    addTearDown(() async {
      if (await game.exists()) await game.delete(recursive: true);
    });
    final String runtimeDir = joinPath(
      joinPath(
        joinPath(joinPath(game.path, 'runtime'), 'java-runtime-delta'),
        'windows-x64',
      ),
      'java-runtime-delta',
    );
    final String path = joinPath(joinPath(runtimeDir, 'bin'), 'java.exe');
    await File(path).parent.create(recursive: true);
    await File(path).writeAsString('fake');

    final JavaFinder finder = JavaFinder(
      runner: FakeRunner('openjdk version "21.0.1" 2023-10-17'),
      operatingSystem: 'windows',
      environment: const <String, String>{},
    );
    final JavaRuntime runtime = await finder.find(
      gameDir: game.path,
      requiredMajor: 21,
    );
    expect(runtime.path, path);
    expect(runtime.major, 21);
  });

  test(
    'invalid manual path, missing Java and insufficient version are reported',
    () async {
      final Directory dir = await Directory.systemTemp.createTemp(
        'jolauncher-java-',
      );
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final String path = joinPath(dir.path, 'java.exe');
      await File(path).writeAsString('fake');

      final JavaFinder finder = JavaFinder(
        runner: FakeRunner('openjdk version "17.0.8"'),
        operatingSystem: 'windows',
        environment: const <String, String>{},
      );

      await expectLater(
        finder.find(manualPath: joinPath(dir.path, 'missing.exe')),
        throwsA(
          isA<LaunchException>().having(
            (LaunchException e) => e.key,
            'key',
            'launch.error.javaPath',
          ),
        ),
      );

      await expectLater(
        finder.find(gameDir: dir.path),
        throwsA(
          isA<LaunchException>().having(
            (LaunchException e) => e.key,
            'key',
            'launch.error.noJava',
          ),
        ),
      );

      await expectLater(
        finder.find(manualPath: path, requiredMajor: 21),
        throwsA(
          isA<LaunchException>().having(
            (LaunchException e) => e.key,
            'key',
            'launch.error.javaTooOld',
          ),
        ),
      );
    },
  );
}

class FakeRunner implements CommandRunner {
  FakeRunner(this.output);

  final String output;

  @override
  Future<CommandResult> run(String executable, List<String> arguments) async {
    return CommandResult(exitCode: 0, stdout: '', stderr: output);
  }
}
