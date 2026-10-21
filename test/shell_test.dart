import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/shell/app_shell.dart';
import 'package:jolauncher/shell/nav.dart';
import 'package:jolauncher/theme/tokens.dart';

import 'test_app.dart';

/// Minimal shell regression: three entries exist and clicking Settings changes
/// the page.
///
/// Structure only, not pixels — colors are subjective and style changes should
/// not fail tests.
void main() {
  Widget build({
    LauncherTab tab = LauncherTab.launch,
    ValueChanged<LauncherTab>? onChanged,
  }) {
    return testApp(
      LauncherShell(
        tab: tab,
        onTabChanged: onChanged ?? (_) {},
        railWidth: LauncherShell.defaultRail,
        onRailResize: (_) {},
        onRailResizeEnd: () {},
        settings: const LauncherSettings(),
        onSettingsChanged: (_) {},
        gameDir: '.',
        onGameDirChanged: (_) {},
        currentVersionName: null,
        onCurrentVersionChanged: (_) {},
        accountName: null,
        onLogin: (_) async {},
        onLogout: () {},
      ),
    );
  }

  testWidgets('all three left-rail entries are present', (
    WidgetTester t,
  ) async {
    t.view.physicalSize = const Size(1200, 800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(build());
    const Map<LauncherTab, String> labels = <LauncherTab, String>{
      LauncherTab.launch: 'Launch',
      LauncherTab.version: 'Version settings',
      LauncherTab.settings: 'Settings',
    };
    for (final MapEntry<LauncherTab, String> entry in labels.entries) {
      expect(
        find.text(entry.value),
        findsWidgets,
        reason: 'left rail should contain "${entry.value}"',
      );
    }
    // Defaults to the Launch page.
    expect(find.text('Launch'), findsWidgets);
  });

  testWidgets('clicking Settings switches to the settings page', (
    WidgetTester t,
  ) async {
    t.view.physicalSize = const Size(1200, 800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    LauncherTab current = LauncherTab.launch;
    await t.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, void Function(VoidCallback) setState) {
          return testApp(
            LauncherShell(
              tab: current,
              onTabChanged: (LauncherTab next) =>
                  setState(() => current = next),
              railWidth: LauncherShell.defaultRail,
              onRailResize: (_) {},
              onRailResizeEnd: () {},
              settings: const LauncherSettings(),
              onSettingsChanged: (_) {},
              gameDir: '.',
              onGameDirChanged: (_) {},
              currentVersionName: null,
              onCurrentVersionChanged: (_) {},
              accountName: null,
              onLogin: (_) async {},
              onLogout: () {},
            ),
          );
        },
      ),
    );
    await t.tap(find.text('Settings').first);
    await t.pumpAndSettle();
    expect(current, LauncherTab.settings);
    expect(find.text('Appearance'), findsOneWidget);
  });
}
