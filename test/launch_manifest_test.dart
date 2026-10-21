import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/launch/launch_error.dart';
import 'package:jolauncher/launch/manifest.dart';
import 'package:jolauncher/mc/paths.dart';

/// Version manifest parsing, rule evaluation and inheritance merging.
void main() {
  test(
    'parses mainClass / libraries / arguments / asset index / Java version',
    () {
      final VersionManifest m = VersionManifest.fromJson(<String, Object?>{
        'id': '1.20.1',
        'mainClass': 'net.minecraft.client.main.Main',
        'assetIndex': <String, Object?>{'id': '5'},
        'javaVersion': <String, Object?>{'majorVersion': 17},
        'libraries': <Object?>[
          <String, Object?>{
            'name': 'org.example:lib:1.0',
            'downloads': <String, Object?>{
              'artifact': <String, Object?>{
                'path': 'org/example/lib/1.0/lib-1.0.jar',
                'url': 'https://example.invalid/lib.jar',
                'sha1': 'abc',
                'size': 123,
              },
            },
          },
        ],
        'arguments': <String, Object?>{
          'game': <Object?>[
            '--username',
            r'${auth_player_name}',
            <String, Object?>{
              'rules': <Object?>[
                <String, Object?>{
                  'action': 'allow',
                  'os': <String, Object?>{'name': 'windows'},
                },
              ],
              'value': '--win-only',
            },
          ],
          'jvm': <Object?>['-cp', r'${classpath}'],
        },
      });

      expect(m.id, '1.20.1');
      expect(m.mainClass, 'net.minecraft.client.main.Main');
      expect(m.assetIndex, '5');
      expect(m.javaMajor, 17);
      expect(
        m.libraries.single.artifact!.path,
        'org/example/lib/1.0/lib-1.0.jar',
      );
      expect(m.gameArguments.length, 3);
      expect(m.gameArguments[2].rules.single.osName, 'windows');
      expect(m.jvmArguments.length, 2);
    },
  );

  test('rules: empty list allows; later deny overrides allow', () {
    final LaunchContext win = LaunchContext(
      osName: 'windows',
      osArch: 'x86_64',
    );
    expect(rulesAllow(const <Rule>[], win), isTrue);
    expect(rulesAllow(const <Rule>[Rule(osName: 'windows')], win), isTrue);
    expect(rulesAllow(const <Rule>[Rule(osName: 'linux')], win), isFalse);
    expect(
      rulesAllow(const <Rule>[
        Rule(),
        Rule(action: 'disallow', osName: 'windows'),
      ], win),
      isFalse,
    );
  });

  test(
    'inheritance merges parent libraries, arguments, assets and Java version',
    () async {
      final Directory root = await Directory.systemTemp.createTemp(
        'jolauncher-manifest-',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });

      await _writeVersion(root, '1.20.1', <String, Object?>{
        'id': '1.20.1',
        'mainClass': 'net.minecraft.client.main.Main',
        'assetIndex': <String, Object?>{'id': '5'},
        'javaVersion': <String, Object?>{'majorVersion': 17},
        'libraries': <Object?>[
          <String, Object?>{'name': 'org.example:parent:1.0'},
        ],
        'arguments': <String, Object?>{
          'game': <Object?>['--parent'],
        },
      });
      await _writeVersion(root, 'fabric-x', <String, Object?>{
        'id': 'fabric-x',
        'inheritsFrom': '1.20.1',
        'mainClass': 'net.fabricmc.loader.impl.launch.knot.KnotClient',
        'libraries': <Object?>[
          <String, Object?>{'name': 'org.example:child:1.0'},
        ],
        'arguments': <String, Object?>{
          'game': <Object?>['--child'],
          'jvm': <Object?>['-cp', r'${classpath}'],
        },
      });

      final VersionManifest m = await resolveManifest(root.path, 'fabric-x');
      expect(m.id, 'fabric-x');
      expect(m.mainClass, 'net.fabricmc.loader.impl.launch.knot.KnotClient');
      expect(m.assetIndex, '5');
      expect(m.javaMajor, 17);
      expect(m.libraries.map((Library l) => l.name), <String>[
        'org.example:parent:1.0',
        'org.example:child:1.0',
      ]);
      expect(m.gameArguments.length, 2);
    },
  );

  test('inheritance cycles and missing parents are reported clearly', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'jolauncher-manifest-',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    await _writeVersion(root, 'a', <String, Object?>{
      'id': 'a',
      'inheritsFrom': 'b',
    });
    await _writeVersion(root, 'b', <String, Object?>{
      'id': 'b',
      'inheritsFrom': 'a',
    });

    await expectLater(
      resolveManifest(root.path, 'a'),
      throwsA(
        isA<LaunchException>().having(
          (LaunchException e) => e.key,
          'key',
          'launch.error.inheritCycle',
        ),
      ),
    );

    await expectLater(
      resolveManifest(root.path, 'missing'),
      throwsA(
        isA<LaunchException>().having(
          (LaunchException e) => e.key,
          'key',
          'launch.error.manifestMissing',
        ),
      ),
    );
  });
}

Future<void> _writeVersion(
  Directory root,
  String name,
  Map<String, Object?> json,
) async {
  final Directory dir = Directory(
    joinPath(joinPath(root.path, 'versions'), name),
  );
  await dir.create(recursive: true);
  await File(joinPath(dir.path, '$name.json')).writeAsString(jsonEncode(json));
}
