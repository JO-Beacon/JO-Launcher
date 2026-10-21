import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/auth/account.dart';
import 'package:jolauncher/launch/java.dart';
import 'package:jolauncher/launch/launch_error.dart';
import 'package:jolauncher/launch/manifest.dart';
import 'package:jolauncher/launch/plan.dart';
import 'package:jolauncher/mc/paths.dart';
import 'package:jolauncher/mc/version.dart';
import 'package:jolauncher/mc/version_config.dart';

/// Launch plan: classpath, natives, argument substitution, memory and errors.
///
/// Does not start a process or touch the real game directory; all fixtures use
/// temporary directories.
void main() {
  late Directory root;
  late Directory versionDir;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('jolauncher-plan-');
    versionDir = Directory(joinPath(joinPath(root.path, 'versions'), '1.20.1'));
    await versionDir.create(recursive: true);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  McVersion version() => McVersion(
    name: '1.20.1',
    gameVersion: '1.20.1',
    loader: McLoader.vanilla,
    dir: versionDir.path,
  );

  MinecraftAccount account() => MinecraftAccount(
    name: 'Steve',
    uuid: '069a79f444e94726a5befca90e38aaf5',
    refreshToken: 'r',
    accessToken: 'mc-token',
    accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
  );

  JavaRuntime java({int major = 17}) => JavaRuntime(
    path: joinPath(versionDir.path, 'java'),
    version: '$major.0.1',
    major: major,
  );

  VersionManifest manifest({int javaMajor = 17, bool withNatives = true}) {
    return VersionManifest.fromJson(<String, Object?>{
      'id': '1.20.1',
      'mainClass': 'net.minecraft.client.main.Main',
      'assetIndex': <String, Object?>{'id': '5'},
      'javaVersion': <String, Object?>{'majorVersion': javaMajor},
      'arguments': <String, Object?>{
        'game': <Object?>[
          '--username',
          r'${auth_player_name}',
          '--uuid',
          r'${auth_uuid}',
          '--accessToken',
          r'${auth_access_token}',
          '--gameDir',
          r'${game_directory}',
          '--assetsDir',
          r'${assets_root}',
          '--assetIndex',
          r'${assets_index_name}',
        ],
        'jvm': <Object?>[
          r'-Djava.library.path=${natives_directory}',
          '-cp',
          r'${classpath}',
          r'-Dminecraft.launcher.brand=${launcher_name}',
        ],
      },
      'libraries': <Object?>[
        <String, Object?>{
          'name': 'org.example:lib:1.0',
          'downloads': <String, Object?>{
            'artifact': <String, Object?>{
              'path': 'org/example/lib/1.0/lib-1.0.jar',
            },
          },
        },
        <String, Object?>{
          'name': 'org.example:win:1.0',
          'rules': <Object?>[
            <String, Object?>{
              'action': 'allow',
              'os': <String, Object?>{'name': 'windows'},
            },
          ],
          'downloads': <String, Object?>{
            'artifact': <String, Object?>{
              'path': 'org/example/win/1.0/win-1.0.jar',
            },
          },
        },
        <String, Object?>{
          'name': 'org.example:linux:1.0',
          'rules': <Object?>[
            <String, Object?>{
              'action': 'allow',
              'os': <String, Object?>{'name': 'linux'},
            },
          ],
          'downloads': <String, Object?>{
            'artifact': <String, Object?>{
              'path': 'org/example/linux/1.0/linux-1.0.jar',
            },
          },
        },
        if (withNatives)
          <String, Object?>{
            'name': 'org.example:native:1.0',
            'natives': <String, Object?>{'windows': 'natives-windows'},
            'downloads': <String, Object?>{
              'artifact': <String, Object?>{
                'path': 'org/example/native/1.0/native-1.0.jar',
              },
              'classifiers': <String, Object?>{
                'natives-windows': <String, Object?>{
                  'path':
                      'org/example/native/1.0/native-1.0-natives-windows.jar',
                },
              },
            },
          },
      ],
    });
  }

  Future<void> createFile(String relative) async {
    final File file = File(joinPath(root.path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(<int>[1, 2, 3]);
  }

  Future<void> createNativeZip() async {
    final Archive archive = Archive();
    archive.addFile(ArchiveFile('foo.dll', 3, <int>[1, 2, 3]));
    final File file = File(
      joinPath(
        root.path,
        'libraries/org/example/native/1.0/native-1.0-natives-windows.jar',
      ),
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive));
  }

  Future<void> prepareFiles() async {
    await createFile('versions/1.20.1/1.20.1.jar');
    await createFile('libraries/org/example/lib/1.0/lib-1.0.jar');
    await createFile('libraries/org/example/win/1.0/win-1.0.jar');
    await createFile('libraries/org/example/native/1.0/native-1.0.jar');
    await createNativeZip();
    final File index = File(joinPath(root.path, 'assets/indexes/5.json'));
    await index.parent.create(recursive: true);
    await index.writeAsString('{}');
  }

  test('Windows: classpath, rules, natives, arguments and memory', () async {
    await prepareFiles();
    const LaunchContext ctx = LaunchContext(
      osName: 'windows',
      osArch: 'x86_64',
    );
    final LaunchPlan plan = await buildLaunchPlan(
      gameDir: root.path,
      version: version(),
      account: account(),
      config: const VersionConfig(
        minMemoryMb: 512,
        maxMemoryMb: 2048,
        jvmArgs: '-Dfoo=bar',
      ),
      manifest: manifest(),
      java: java(),
      context: ctx,
      launcherVersion: '0.0.1',
      clientId: 'client-id',
    );

    expect(plan.executable, java().path);
    expect(plan.workingDirectory, versionDir.path);
    expect(plan.arguments, contains('net.minecraft.client.main.Main'));
    expect(
      plan.arguments,
      containsAllInOrder(<String>[
        '--username',
        'Steve',
        '--uuid',
        '069a79f444e94726a5befca90e38aaf5',
        '--accessToken',
        'mc-token',
      ]),
    );
    expect(plan.arguments, contains(versionDir.path));
    expect(plan.arguments, contains(joinPath(root.path, 'assets')));
    expect(plan.arguments, contains('5'));
    expect(
      plan.arguments,
      contains('-Djava.library.path=${joinPath(versionDir.path, 'natives')}'),
    );
    expect(plan.arguments, contains('-Dminecraft.launcher.brand=JO-Launcher'));
    expect(plan.arguments, contains('-Xms512M'));
    expect(plan.arguments, contains('-Xmx2048M'));
    expect(plan.arguments, contains('-Dfoo=bar'));

    final String classpath = plan.arguments[plan.arguments.indexOf('-cp') + 1];
    expect(classpath, contains('lib-1.0.jar'));
    expect(classpath, contains('win-1.0.jar'));
    expect(classpath, contains('native-1.0.jar'));
    expect(classpath, contains('1.20.1.jar'));
    expect(classpath, isNot(contains('linux-1.0.jar')));
    expect(
      File(
        joinPath(joinPath(versionDir.path, 'natives'), 'foo.dll'),
      ).existsSync(),
      isTrue,
    );
  });

  test('insufficient Java version is reported clearly', () async {
    await prepareFiles();
    await expectLater(
      buildLaunchPlan(
        gameDir: root.path,
        version: version(),
        account: account(),
        config: const VersionConfig(),
        manifest: manifest(javaMajor: 17),
        java: java(major: 8),
        context: const LaunchContext(osName: 'windows', osArch: 'x86_64'),
      ),
      throwsA(
        isA<LaunchException>().having(
          (LaunchException e) => e.key,
          'key',
          'launch.error.javaTooOld',
        ),
      ),
    );
  });

  test(
    'missing library / client jar / asset index are reported separately',
    () async {
      await prepareFiles();
      const LaunchContext ctx = LaunchContext(
        osName: 'windows',
        osArch: 'x86_64',
      );

      File(
        joinPath(root.path, 'libraries/org/example/lib/1.0/lib-1.0.jar'),
      ).deleteSync();
      await expectLater(
        buildLaunchPlan(
          gameDir: root.path,
          version: version(),
          account: account(),
          config: const VersionConfig(),
          manifest: manifest(),
          java: java(),
          context: ctx,
        ),
        throwsA(
          isA<LaunchException>().having(
            (LaunchException e) => e.key,
            'key',
            'launch.error.missingLibrary',
          ),
        ),
      );

      await prepareFiles();
      File(joinPath(versionDir.path, '1.20.1.jar')).deleteSync();
      await expectLater(
        buildLaunchPlan(
          gameDir: root.path,
          version: version(),
          account: account(),
          config: const VersionConfig(),
          manifest: manifest(),
          java: java(),
          context: ctx,
        ),
        throwsA(
          isA<LaunchException>().having(
            (LaunchException e) => e.key,
            'key',
            'launch.error.missingClient',
          ),
        ),
      );

      await prepareFiles();
      File(joinPath(root.path, 'assets/indexes/5.json')).deleteSync();
      await expectLater(
        buildLaunchPlan(
          gameDir: root.path,
          version: version(),
          account: account(),
          config: const VersionConfig(),
          manifest: manifest(),
          java: java(),
          context: ctx,
        ),
        throwsA(
          isA<LaunchException>().having(
            (LaunchException e) => e.key,
            'key',
            'launch.error.missingAssets',
          ),
        ),
      );
    },
  );
}
