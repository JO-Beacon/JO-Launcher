import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/pages/app_settings_page.dart';
import 'package:jolauncher/theme/tokens.dart';

import 'test_app.dart';

/// Settings page: appearance present, game directory changeable, account shown as signed out.
void main() {
  Widget wrap(Widget child) => testApp(child);

  void size(WidgetTester t) {
    t.view.physicalSize = const Size(1200, 1000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  testWidgets('shows appearance, current directory and signed-out state', (
    WidgetTester t,
  ) async {
    size(t);
    await t.pumpWidget(
      wrap(
        SettingsPage(
          settings: const LauncherSettings(),
          onChanged: (_) {},
          gameDir: r'C:\Users\me\AppData\Roaming\.minecraft',
          onGameDirChanged: (_) {},
          accountName: null,
          onLogin: () {},
          onLogout: () {},
          chooseDirectory: (String _) async => null,
        ),
      ),
    );

    expect(find.text('Appearance'), findsOneWidget);
    expect(
      find.text(r'C:\Users\me\AppData\Roaming\.minecraft'),
      findsOneWidget,
    );
    expect(find.text('Microsoft account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('changes the game directory and returns the pick', (
    WidgetTester t,
  ) async {
    size(t);
    String? picked;
    await t.pumpWidget(
      wrap(
        SettingsPage(
          settings: const LauncherSettings(),
          onChanged: (_) {},
          gameDir: r'C:\old\.minecraft',
          onGameDirChanged: (String dir) => picked = dir,
          accountName: null,
          onLogin: () {},
          onLogout: () {},
          chooseDirectory: (String _) async => r'D:\new\.minecraft',
        ),
      ),
    );

    await t.tap(find.text('Change'));
    await t.pumpAndSettle();

    expect(picked, r'D:\new\.minecraft');
  });

  testWidgets('delete account: cancel keeps data, confirm calls back', (
    WidgetTester t,
  ) async {
    size(t);
    bool deleted = false;
    await t.pumpWidget(
      wrap(
        SettingsPage(
          settings: const LauncherSettings(),
          onChanged: (_) {},
          gameDir: r'C:\mc',
          onGameDirChanged: (_) {},
          accountName: 'Steve',
          onLogin: () {},
          onLogout: () {},
          onDeleteAccount: () async => deleted = true,
          chooseDirectory: (String _) async => null,
        ),
      ),
    );

    expect(find.text('Delete account and local data'), findsOneWidget);
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    expect(find.text('Delete account and local data?'), findsOneWidget);

    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(deleted, isFalse);

    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete').last);
    await t.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
