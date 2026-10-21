import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/shell/left_rail.dart';
import 'package:jolauncher/shell/nav.dart';

import 'test_app.dart';

/// Left rail account area: "Microsoft sign-in" entry when signed out; player name when signed in.
void main() {
  void size(WidgetTester t) {
    t.view.physicalSize = const Size(1200, 800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
  }

  testWidgets('signed out: Microsoft sign-in row is tappable', (
    WidgetTester t,
  ) async {
    size(t);
    bool tapped = false;
    await t.pumpWidget(
      testApp(
        LauncherRail(
          tab: LauncherTab.launch,
          onTabChanged: (_) {},
          onLogin: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Microsoft sign-in'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    await t.tap(find.text('Microsoft sign-in'));
    expect(tapped, isTrue);
  });

  testWidgets('signed in: shows player name', (WidgetTester t) async {
    size(t);
    await t.pumpWidget(
      testApp(
        LauncherRail(
          tab: LauncherTab.launch,
          onTabChanged: (_) {},
          playerName: 'Steve',
          onLogin: () {},
        ),
      ),
    );

    expect(find.text('Steve'), findsOneWidget);
    expect(find.text('Microsoft sign-in'), findsNothing);
  });

  testWidgets('download entry does not exist', (WidgetTester t) async {
    size(t);
    await t.pumpWidget(
      testApp(LauncherRail(tab: LauncherTab.launch, onTabChanged: (_) {})),
    );

    expect(find.text('Download'), findsNothing);
    expect(find.text('Game'), findsNothing);
    expect(find.text('Mods'), findsNothing);
  });
}
