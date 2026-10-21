import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/l10n/app_localizations.dart';
import 'package:jolauncher/l10n/version_labels.dart';
import 'package:jolauncher/mc/game_dir.dart';
import 'package:jolauncher/mc/paths.dart';
import 'package:jolauncher/mc/scan.dart';
import 'package:jolauncher/mc/version.dart';
import 'package:jolauncher/mc/version_config.dart';

/// Regression tests for version scanning and version settings.
///
/// Manifest fixtures mirror real files: the NeoForge one has no `inheritsFrom`
/// and also contains a `net.minecraftforge:srgutils` entry, which must not make
/// it be detected as Forge.
void main() {
  McVersion parse(Map<String, Object?> json, {String name = 'x'}) =>
      McVersion.fromManifest(json, name: name, dir: '/tmp/$name');

  group('Manifest parsing', () {
    test('vanilla', () {
      final McVersion v = parse(<String, Object?>{
        'id': '1.20.1',
        'type': 'release',
        'mainClass': 'net.minecraft.client.main.Main',
        'releaseTime': '2023-06-12T12:00:00+00:00',
        'libraries': <Object?>[
          <String, Object?>{'name': 'org.ow2.asm:asm:9.6'},
        ],
      }, name: '1.20.1');
      expect(v.loader, McLoader.vanilla);
      expect(v.gameVersion, '1.20.1');
      expect(v.loaderVersion, isNull);
      expect(v.loaderText(const AppLocalizations(Locale('en'))), 'Vanilla');
      expect(v.meta(const AppLocalizations(Locale('en'))), '1.20.1 · Vanilla');
      expect(v.releaseTime, DateTime.utc(2023, 6, 12, 12));
    });

    test('Fabric: game version comes from inheritsFrom', () {
      final McVersion v = parse(<String, Object?>{
        'id': 'fabric-loader-0.16.9-1.21.1',
        'inheritsFrom': '1.21.1',
        'mainClass': 'net.fabricmc.loader.impl.launch.knot.KnotClient',
        'libraries': <Object?>[
          <String, Object?>{'name': 'net.fabricmc:fabric-loader:0.16.9'},
          <String, Object?>{'name': 'net.fabricmc:intermediary:1.21.1'},
        ],
      });
      expect(v.loader, McLoader.fabric);
      expect(v.loaderVersion, '0.16.9');
      expect(v.gameVersion, '1.21.1');
    });

    test(
      'Fabric: infer from name when inheritsFrom is missing; do not use loader version as game version',
      () {
        final McVersion v = parse(<String, Object?>{
          'id': 'fabric-loader-0.16.9-1.21.1',
          'mainClass': 'net.fabricmc.loader.impl.launch.knot.KnotClient',
          'libraries': <Object?>[
            <String, Object?>{'name': 'net.fabricmc:fabric-loader:0.16.9'},
          ],
        });
        expect(v.loader, McLoader.fabric);
        expect(v.gameVersion, '1.21.1');
      },
    );

    test(
      'NeoForge: merged manifest without inheritsFrom, with Forge common libraries',
      () {
        final McVersion v = parse(<String, Object?>{
          'id': '1.21.1-NeoForge_21.1.259',
          'mainClass': 'cpw.mods.bootstraplauncher.BootstrapLauncher',
          'arguments': <String, Object?>{
            'game': <Object?>[
              '--fml.neoForgeVersion',
              '21.1.259',
              '--fml.fmlVersion',
              '4.0.45',
              '--fml.mcVersion',
              '1.21.1',
            ],
          },
          'libraries': <Object?>[
            <String, Object?>{
              'name': 'net.neoforged.fancymodloader:loader:4.0.45',
            },
            <String, Object?>{'name': 'net.minecraftforge:srgutils:0.4.15'},
          ],
        }, name: '1.21.1-NeoForge_21.1.259');
        expect(v.loader, McLoader.neoforge);
        expect(v.loaderVersion, '21.1.259');
        expect(v.gameVersion, '1.21.1');
      },
    );

    test('old Forge: legacy 1.12 minecraftArguments form', () {
      final McVersion v = parse(<String, Object?>{
        'id': '1.12.2-forge-14.23.5.2859',
        'inheritsFrom': '1.12.2',
        'mainClass': 'net.minecraft.launchwrapper.Launch',
        'minecraftArguments':
            r'--username ${auth_player_name} '
            r'--version ${version_name}',
        'libraries': <Object?>[
          <String, Object?>{
            'name': 'net.minecraftforge:forge:1.12.2-14.23.5.2859',
          },
        ],
      });
      expect(v.loader, McLoader.forge);
      expect(v.gameVersion, '1.12.2');
    });

    test('Quilt', () {
      final McVersion v = parse(<String, Object?>{
        'id': 'quilt-loader-0.23.1-1.20.4',
        'inheritsFrom': '1.20.4',
        'mainClass': 'org.quiltmc.loader.impl.launch.knot.KnotClient',
        'libraries': <Object?>[
          <String, Object?>{'name': 'org.quiltmc:quilt-loader:0.23.1'},
        ],
      });
      expect(v.loader, McLoader.quilt);
      expect(v.loaderVersion, '0.23.1');
      expect(v.gameVersion, '1.20.4');
    });

    test('snapshot: use the manifest id when no comparable version exists', () {
      final McVersion v = parse(<String, Object?>{
        'id': '24w14a',
        'mainClass': 'net.minecraft.client.main.Main',
      }, name: '24w14a');
      expect(v.loader, McLoader.vanilla);
      expect(v.gameVersion, '24w14a');
    });
  });

  group('Directory scan', () {
    late Directory game;

    setUp(() async {
      game = await Directory.systemTemp.createTemp('jolauncher-scan-');
    });

    tearDown(() async {
      if (await game.exists()) await game.delete(recursive: true);
    });

    Directory versionDir(String name) =>
        Directory(joinPath(joinPath(game.path, 'versions'), name));

    /// Builds a `versions/<name>/<name>.json`. When [manifest] is null only an
    /// empty folder is created; a string is written verbatim (to create invalid JSON).
    Future<void> writeVersion(String name, Object? manifest) async {
      final Directory dir = versionDir(name);
      await dir.create(recursive: true);
      if (manifest == null) return;
      final String text = manifest is String ? manifest : jsonEncode(manifest);
      await File(joinPath(dir.path, '$name.json')).writeAsString(text);
    }

    test('scans four versions at once', () async {
      await writeVersion('1.20.1', <String, Object?>{
        'id': '1.20.1',
        'mainClass': 'net.minecraft.client.main.Main',
        'releaseTime': '2023-06-12T12:00:00+00:00',
      });
      await writeVersion('fabric-loader-0.16.9-1.21.1', <String, Object?>{
        'id': 'fabric-loader-0.16.9-1.21.1',
        'inheritsFrom': '1.21.1',
        'libraries': <Object?>[
          <String, Object?>{'name': 'net.fabricmc:fabric-loader:0.16.9'},
        ],
      });
      await writeVersion('1.21.1-NeoForge_21.1.259', <String, Object?>{
        'id': '1.21.1-NeoForge_21.1.259',
        'arguments': <String, Object?>{
          'game': <Object?>[
            '--fml.neoForgeVersion',
            '21.1.259',
            '--fml.mcVersion',
            '1.21.1',
          ],
        },
      });
      await writeVersion('1.12.2-forge-14.23.5.2859', <String, Object?>{
        'id': '1.12.2-forge-14.23.5.2859',
        'inheritsFrom': '1.12.2',
        'libraries': <Object?>[
          <String, Object?>{
            'name': 'net.minecraftforge:forge:1.12.2-14.23.5.2859',
          },
        ],
      });

      final VersionScanResult r = await scanVersions(game.path);
      expect(r.exists, isTrue);
      expect(r.broken, isEmpty);
      expect(r.versionsDir, joinPath(game.path, 'versions'));
      expect(
        <String, McLoader>{
          for (final McVersion v in r.versions) v.name: v.loader,
        },
        <String, McLoader>{
          '1.20.1': McLoader.vanilla,
          'fabric-loader-0.16.9-1.21.1': McLoader.fabric,
          '1.21.1-NeoForge_21.1.259': McLoader.neoforge,
          '1.12.2-forge-14.23.5.2859': McLoader.forge,
        },
      );
    });

    test('newest first; entries without time last', () async {
      await writeVersion('old', <String, Object?>{
        'id': 'old',
        'releaseTime': '2020-01-01T00:00:00Z',
      });
      await writeVersion('new', <String, Object?>{
        'id': 'new',
        'releaseTime': '2025-01-01T00:00:00Z',
      });
      await writeVersion('undated', <String, Object?>{'id': 'undated'});

      final VersionScanResult r = await scanVersions(game.path);
      expect(r.versions.map((McVersion v) => v.name).toList(), <String>[
        'new',
        'old',
        'undated',
      ]);
    });

    test(
      'missing manifest and invalid JSON are tracked without affecting others',
      () async {
        await writeVersion('good', <String, Object?>{'id': 'good'});
        await writeVersion('empty', null);
        await writeVersion('truncated', '{"id": ');

        final VersionScanResult r = await scanVersions(game.path);
        expect(r.versions.map((McVersion v) => v.name), <String>['good']);
        expect(r.broken, <String>['empty', 'truncated']);
      },
    );

    test(
      'reads a differently named manifest when the folder has one json',
      () async {
        await writeVersion('MyPack', null);
        final Directory dir = versionDir('MyPack');
        await File(
          joinPath(dir.path, 'pack.json'),
        ).writeAsString('{"id": "1.20.1"}');

        final VersionScanResult r = await scanVersions(game.path);
        expect(r.versions.single.name, 'MyPack');
        expect(r.versions.single.gameVersion, '1.20.1');
      },
    );

    test('scan also reads jolauncher.json', () async {
      await writeVersion('mc', <String, Object?>{'id': '1.20.1'});
      await File(
        joinPath(versionDir('mc').path, VersionConfig.fileName),
      ).writeAsString('{"javaPath": "C:\\\\Java\\\\bin\\\\javaw.exe"}');

      final VersionScanResult r = await scanVersions(game.path);
      expect(r.versions.single.config.javaPath, r'C:\Java\bin\javaw.exe');
    });

    test(
      'missing versions directory is an empty result, not an error',
      () async {
        final VersionScanResult r = await scanVersions(game.path);
        expect(r.exists, isFalse);
        expect(r.versions, isEmpty);
        expect(r.broken, isEmpty);
      },
    );
  });

  group('Version settings file', () {
    late Directory version;

    setUp(() async {
      version = await Directory.systemTemp.createTemp('jolauncher-version-');
    });

    tearDown(() async {
      if (await version.exists()) await version.delete(recursive: true);
    });

    File configFile() => File(joinPath(version.path, VersionConfig.fileName));

    test('file name is jolauncher.json', () {
      expect(VersionConfig.fileName, 'jolauncher.json');
    });

    test('all automatic when no config file exists', () async {
      final VersionConfig c = await VersionConfig.read(version.path);
      expect(c.javaPath, isNull);
      expect(c.minMemoryMb, isNull);
      expect(c.maxMemoryMb, isNull);
      expect(c.jvmArgs, '');
    });

    test('reads Java, memory and JVM arguments', () async {
      await configFile().writeAsString(
        '{"javaPath": "C:\\\\Java\\\\bin\\\\javaw.exe", '
        '"minMemoryMb": 1024, "maxMemoryMb": 4096, '
        '"jvmArgs": ["-XX:+UseG1GC", "-Dfoo=bar"]}',
      );
      final VersionConfig c = await VersionConfig.read(version.path);
      expect(c.javaPath, r'C:\Java\bin\javaw.exe');
      expect(c.minMemoryMb, 1024);
      expect(c.maxMemoryMb, 4096);
      expect(c.jvmArgs, '-XX:+UseG1GC -Dfoo=bar');
    });

    test('wrong field types fall back to automatic', () async {
      await configFile().writeAsString(
        '{"javaPath": 7, "minMemoryMb": "lots", "maxMemoryMb": 0, '
        '"jvmArgs": 3}',
      );
      final VersionConfig c = await VersionConfig.read(version.path);
      expect(c.javaPath, isNull);
      expect(c.minMemoryMb, isNull);
      expect(c.maxMemoryMb, isNull);
      expect(c.jvmArgs, '');
    });

    test('invalid JSON falls back to defaults without blocking', () async {
      await configFile().writeAsString('{');
      final VersionConfig c = await VersionConfig.read(version.path);
      expect(c.javaPath, isNull);
      expect(c.jvmArgs, '');
    });

    test('writes back preserving unknown fields and updating values', () async {
      await configFile().writeAsString(
        '{"custom": 7, "future": {"a": 1}, "schema": 1}',
      );
      await saveVersionConfig(
        version.path,
        const VersionConfig(
          javaPath: 'C:\\Java\\bin\\java.exe',
          minMemoryMb: 2048,
          maxMemoryMb: 8192,
          jvmArgs: '-XX:+UseG1GC',
        ),
      );

      final Map<String, Object?> raw =
          jsonDecode(await configFile().readAsString()) as Map<String, Object?>;
      expect(raw['javaPath'], r'C:\Java\bin\java.exe');
      expect(raw['minMemoryMb'], 2048);
      expect(raw['maxMemoryMb'], 8192);
      expect(raw['jvmArgs'], '-XX:+UseG1GC');
      expect(raw['schema'], VersionConfig.schema);
      expect(raw['custom'], 7);
      expect(raw['future'], <String, Object?>{'a': 1});
    });

    test('automatic = write null', () async {
      await saveVersionConfig(version.path, const VersionConfig());
      final Map<String, Object?> raw =
          jsonDecode(await configFile().readAsString()) as Map<String, Object?>;
      expect(raw['javaPath'], isNull);
      expect(raw['minMemoryMb'], isNull);
      expect(raw['maxMemoryMb'], isNull);
      expect(raw['jvmArgs'], '');
    });
  });

  group('Default game directory', () {
    test('Windows uses APPDATA', () {
      final String dir = defaultGameDir(
        environment: <String, String>{
          'APPDATA': r'C:\Users\me\AppData\Roaming',
        },
        operatingSystem: 'windows',
      );
      expect(dir, startsWith(r'C:\Users\me\AppData\Roaming'));
      expect(baseName(dir), '.minecraft');
    });

    test('Linux uses HOME', () {
      final String dir = defaultGameDir(
        environment: <String, String>{'HOME': '/home/me'},
        operatingSystem: 'linux',
      );
      expect(dir, startsWith('/home/me'));
      expect(baseName(dir), '.minecraft');
    });

    test(
      'returns a relative path when nothing is available, never a fake absolute path',
      () {
        expect(
          defaultGameDir(
            environment: <String, String>{},
            operatingSystem: 'windows',
          ),
          '.minecraft',
        );
      },
    );
  });
}
