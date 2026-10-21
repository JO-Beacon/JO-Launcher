import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/mc/scan.dart';
import 'package:jolauncher/mc/version.dart';
import 'package:jolauncher/mc/version_config.dart';
import 'package:jolauncher/pages/version_settings_page.dart';
import 'package:jolauncher/ui/common.dart';

import 'test_app.dart';

/// Version settings page: read config, edit config, validation, no current version.
void main() {
  const McVersion version = McVersion(
    name: '1.21.1-NeoForge_21.1.259',
    gameVersion: '1.21.1',
    loader: McLoader.neoforge,
    loaderVersion: '21.1.259',
    dir: r'C:\mc\versions\1.21.1-NeoForge_21.1.259',
  );

  VersionScanResult scanResult() {
    return const VersionScanResult(
      versionsDir: r'C:\mc\versions',
      exists: true,
      versions: <McVersion>[version],
      broken: <String>[],
    );
  }

  Widget wrap(Widget child) => testApp(child);

  void size(WidgetTester t) {
    t.view.physicalSize = const Size(1200, 1200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  List<String> fieldTexts(WidgetTester t) {
    return t
        .widgetList<EditableText>(find.byType(EditableText))
        .map((EditableText e) => e.controller.text)
        .toList();
  }

  testWidgets('reads Java, memory and JVM arguments', (WidgetTester t) async {
    size(t);
    await t.pumpWidget(
      wrap(
        VersionSettingsPage(
          gameDir: r'C:\mc',
          currentVersionName: version.name,
          onOpenLaunch: () {},
          scan: (String _) async => scanResult(),
          readConfig: (String _) async => const VersionConfig(
            javaPath: r'C:\Java\bin\javaw.exe',
            minMemoryMb: 1024,
            maxMemoryMb: 4096,
            jvmArgs: '-XX:+UseG1GC',
          ),
          saveConfig: (String _, VersionConfig _) async {},
          openFolder: (String _) async => true,
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('Version settings'), findsOneWidget);
    expect(find.text('1.21.1-NeoForge_21.1.259'), findsWidgets);
    expect(find.text('NeoForge 21.1.259'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LauncherSegment<bool>),
        matching: find.text('Automatic'),
      ),
      findsOneWidget,
    );
    expect(find.text('Manual'), findsOneWidget);
    expect(fieldTexts(t), <String>[
      r'C:\Java\bin\javaw.exe',
      '1024',
      '4096',
      '-XX:+UseG1GC',
    ]);
    expect(find.text('Saved.'), findsNothing);
  });

  testWidgets('saves memory and JVM arguments', (WidgetTester t) async {
    size(t);
    VersionConfig? saved;
    await t.pumpWidget(
      wrap(
        VersionSettingsPage(
          gameDir: r'C:\mc',
          currentVersionName: version.name,
          onOpenLaunch: () {},
          scan: (String _) async => scanResult(),
          readConfig: (String _) async => const VersionConfig(),
          saveConfig: (String _, VersionConfig config) async {
            saved = config;
          },
          openFolder: (String _) async => true,
        ),
      ),
    );
    await t.pumpAndSettle();

    // With automatic Java there is no path field: min memory, max memory and JVM arguments.
    await t.enterText(find.byType(EditableText).at(0), '1024');
    await t.enterText(find.byType(EditableText).at(1), '4096');
    await t.enterText(find.byType(EditableText).at(2), '-Dfoo=bar');

    await t.ensureVisible(find.text('Save'));
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.javaPath, isNull);
    expect(saved!.minMemoryMb, 1024);
    expect(saved!.maxMemoryMb, 4096);
    expect(saved!.jvmArgs, '-Dfoo=bar');
    expect(find.text('Saved.'), findsOneWidget);
  });

  testWidgets('memory 0 is rejected with a clear reason', (
    WidgetTester t,
  ) async {
    size(t);
    VersionConfig? saved;
    await t.pumpWidget(
      wrap(
        VersionSettingsPage(
          gameDir: r'C:\mc',
          currentVersionName: version.name,
          onOpenLaunch: () {},
          scan: (String _) async => scanResult(),
          readConfig: (String _) async => const VersionConfig(),
          saveConfig: (String _, VersionConfig config) async {
            saved = config;
          },
          openFolder: (String _) async => true,
        ),
      ),
    );
    await t.pumpAndSettle();

    await t.enterText(find.byType(EditableText).at(0), '0');
    await t.ensureVisible(find.text('Save'));
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();

    expect(saved, isNull);
    expect(find.text('Memory must be greater than 0.'), findsOneWidget);
  });

  testWidgets('no current version: go to the Launch page', (
    WidgetTester t,
  ) async {
    size(t);
    bool opened = false;
    await t.pumpWidget(
      wrap(
        VersionSettingsPage(
          gameDir: r'C:\mc',
          currentVersionName: null,
          onOpenLaunch: () => opened = true,
          scan: (String _) async => scanResult(),
          readConfig: (String _) async => const VersionConfig(),
          saveConfig: (String _, VersionConfig _) async {},
          openFolder: (String _) async => true,
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(
      find.text('Choose a version on the Launch page first.'),
      findsOneWidget,
    );
    await t.tap(find.text('Go to Launch'));
    expect(opened, isTrue);
  });
}
