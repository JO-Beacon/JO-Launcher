import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/mc/scan.dart';
import 'package:jolauncher/mc/version.dart';
import 'package:jolauncher/pages/launch_page.dart';

import 'test_app.dart';

/// Launch page: current version, switching, empty states.
void main() {
  const McVersion forge = McVersion(
    name: '1.21.1-forge-47.2.0',
    gameVersion: '1.21.1',
    loader: McLoader.forge,
    loaderVersion: '47.2.0',
    dir: r'C:\mc\versions\1.21.1-forge-47.2.0',
  );
  const McVersion vanilla = McVersion(
    name: '1.20.1',
    gameVersion: '1.20.1',
    loader: McLoader.vanilla,
    dir: r'C:\mc\versions\1.20.1',
  );

  VersionScanResult result(
    List<McVersion> versions, {
    List<String> broken = const <String>[],
  }) {
    return VersionScanResult(
      versionsDir: r'C:\mc\versions',
      exists: true,
      versions: versions,
      broken: broken,
    );
  }

  Widget wrap(Widget child) => testApp(child);

  void size(WidgetTester t) {
    t.view.physicalSize = const Size(1200, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  testWidgets('current version card', (WidgetTester t) async {
    size(t);
    await t.pumpWidget(
      wrap(
        LaunchPage(
          gameDir: r'C:\mc',
          currentVersionName: forge.name,
          onCurrentVersionChanged: (_) {},
          scan: (String _) async => result(<McVersion>[forge, vanilla]),
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text(forge.name), findsOneWidget);
    expect(find.text('1.21.1 · Forge 47.2.0'), findsOneWidget);
    expect(find.text('Switch'), findsOneWidget);
    expect(find.text('Launch game'), findsOneWidget);
    expect(find.text('Sign in to launch the game.'), findsOneWidget);
    expect(find.text('No games are running.'), findsOneWidget);
  });

  testWidgets('switch version', (WidgetTester t) async {
    size(t);
    String? picked;
    await t.pumpWidget(
      wrap(
        LaunchPage(
          gameDir: r'C:\mc',
          currentVersionName: forge.name,
          onCurrentVersionChanged: (String name) => picked = name,
          scan: (String _) async => result(<McVersion>[forge, vanilla]),
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text(vanilla.name), findsNothing);
    await t.tap(find.text('Switch'));
    await t.pumpAndSettle();
    expect(find.text(vanilla.name), findsOneWidget);

    await t.tap(find.text(vanilla.name));
    await t.pumpAndSettle();
    expect(picked, vanilla.name);
    expect(find.text(vanilla.name), findsNothing);
  });

  testWidgets('no current version shows the list', (WidgetTester t) async {
    size(t);
    String? picked;
    await t.pumpWidget(
      wrap(
        LaunchPage(
          gameDir: r'C:\mc',
          currentVersionName: null,
          onCurrentVersionChanged: (String name) => picked = name,
          scan: (String _) async => result(<McVersion>[forge, vanilla]),
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('Choose a version to launch'), findsOneWidget);
    expect(find.text(forge.name), findsOneWidget);
    expect(find.text(vanilla.name), findsOneWidget);

    await t.tap(find.text(vanilla.name));
    await t.pumpAndSettle();
    expect(picked, vanilla.name);
  });

  testWidgets('missing versions folder', (WidgetTester t) async {
    size(t);
    await t.pumpWidget(
      wrap(
        LaunchPage(
          gameDir: r'C:\mc',
          currentVersionName: null,
          onCurrentVersionChanged: (_) {},
          scan: (String _) async => const VersionScanResult(
            versionsDir: r'C:\mc\versions',
            exists: false,
            versions: <McVersion>[],
            broken: <String>[],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(
      find.text('There is no versions folder in this directory.'),
      findsOneWidget,
    );
    expect(find.text('Go to Downloads'), findsNothing);
  });

  testWidgets('no versions installed', (WidgetTester t) async {
    size(t);
    await t.pumpWidget(
      wrap(
        LaunchPage(
          gameDir: r'C:\mc',
          currentVersionName: null,
          onCurrentVersionChanged: (_) {},
          scan: (String _) async => result(const <McVersion>[]),
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('No launchable versions yet.'), findsOneWidget);
    expect(find.text('Go to Downloads'), findsNothing);
  });
}
