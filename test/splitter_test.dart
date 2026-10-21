// Splitter between panes.
//
// The point is not “it can drag”, but that it drags correctly:
//   1. Which direction widens the pane (left and right rails are opposite);
//   2. **No stickiness**: the width must be computed from “press position to
//      current mouse position”, so hitting the max and dragging back keeps the
//      edge aligned with the mouse. The old frame-by-frame delta approach
//      shifted the edge after hitting a limit;
//   3. Bounds (min/max), double-click reset and persisted width.
//
// Note: drag recognition has a threshold, and the initial movement is consumed
// by the recognizer, so assertions use the relative movement from the drag start.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/theme/settings_store.dart';
import 'package:jolauncher/theme/tokens.dart';
import 'package:jolauncher/ui/splitter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(Widget child) => MaterialApp(
  home: LauncherTheme(
    settings: const LauncherSettings(),
    palette: LauncherPalette.dark,
    child: Scaffold(
      body: Row(
        children: <Widget>[
          child,
          const Expanded(child: SizedBox.expand()),
        ],
      ),
    ),
  ),
);

/// Builds a splitter that keeps its width in State, and returns a shell that
/// exposes the current width.
class Rig {
  Rig(this.build, this.width, this.savedOf);

  final Widget Function() build;
  final double Function() width;
  final double? Function() savedOf;
}

Rig rig({
  double initial = 200,
  bool growsRight = true,
  double min = 100,
  double max = 400,
  double def = 220,
}) {
  double w = initial;
  double? saved;
  Widget build() => host(
    StatefulBuilder(
      builder: (BuildContext c, void Function(void Function()) setState) {
        return LauncherSplitter(
          palette: LauncherPalette.dark,
          width: w,
          minWidth: min,
          maxWidth: max,
          defaultWidth: def,
          growsRight: growsRight,
          onResize: (double v) => setState(() => w = v),
          onResizeEnd: () => saved = w,
        );
      },
    ),
  );
  return Rig(build, () => w, () => saved);
}

/// Grabs the splitter, crosses the recognition threshold, then lets the caller
/// continue dragging.
Future<TestGesture> grab(WidgetTester t, {double dir = 1}) async {
  final TestGesture g = await t.startGesture(
    t.getCenter(find.byType(LauncherSplitter)),
    kind: PointerDeviceKind.mouse,
  );
  await t.pump();
  await g.moveBy(Offset(40 * dir, 0));
  await t.pump();
  return g;
}

double widthOf(WidgetTester t) =>
    t.widget<LauncherSplitter>(find.byType(LauncherSplitter)).width;

/// Waits after release: the double-click recognizer keeps a 300ms timer, and
/// the test fails with “timer still pending” without this wait.
Future<void> release(WidgetTester t, TestGesture g) async {
  await g.up();
  await t.pump(const Duration(milliseconds: 400));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('left rail: dragging right widens it', (WidgetTester t) async {
    final r = rig(initial: 200, max: 400);
    await t.pumpWidget(r.build());
    final TestGesture g = await grab(t, dir: 1);
    final double w0 = r.width();
    await g.moveBy(const Offset(60, 0));
    await t.pump();
    expect(r.width(), w0 + 60);
    expect(widthOf(t), w0 + 60);
    await release(t, g);
  });

  testWidgets('right rail: dragging left widens it', (WidgetTester t) async {
    final r = rig(initial: 200, growsRight: false, max: 400);
    await t.pumpWidget(r.build());
    final TestGesture g = await grab(t, dir: -1);
    final double w0 = r.width();
    await g.moveBy(const Offset(-60, 0));
    await t.pump();
    expect(r.width(), w0 + 60);
    await release(t, g);
  });

  testWidgets('stops at the upper limit and follows the mouse back', (
    WidgetTester t,
  ) async {
    final r = rig(initial: 300, max: 300); // starts at the upper limit
    await t.pumpWidget(r.build());

    // The gesture already moved 40px right (consumed by the recognizer);
    // measure from here.
    final TestGesture g = await grab(t, dir: 1);
    expect(r.width(), 300);

    await g.moveBy(const Offset(40, 0));
    await t.pump();
    expect(r.width(), 300, reason: 'should stop at the upper limit');

    // Drag back to the press position: the delta approach would shrink by the
    // overshoot, while the absolute approach stays at 300.
    await g.moveBy(const Offset(-40, 0));
    await t.pump();
    expect(
      r.width(),
      300,
      reason: 'back at the press position it should be the original width',
    );

    // Moving further left actually narrows it.
    await g.moveBy(const Offset(-40, 0));
    await t.pump();
    expect(r.width(), 260);
    await g.moveBy(const Offset(-20, 0));
    await t.pump();
    expect(r.width(), 240);
    await release(t, g);
  });

  testWidgets('stops at the lower limit too', (WidgetTester t) async {
    final r = rig(initial: 150, min: 150, max: 400);
    await t.pumpWidget(r.build());
    final TestGesture g = await grab(t, dir: 1);
    await g.moveBy(const Offset(-200, 0));
    await t.pump();
    expect(r.width(), 150);
    await release(t, g);
  });

  testWidgets('double-click restores the default width', (
    WidgetTester t,
  ) async {
    final r = rig(initial: 380, def: 220);
    await t.pumpWidget(r.build());
    final Offset at = t.getCenter(find.byType(LauncherSplitter));
    await t.tapAt(at);
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(at);
    await t.pumpAndSettle();
    expect(r.width(), 220);
  });

  testWidgets('saves on release', (WidgetTester t) async {
    final r = rig(initial: 200);
    await t.pumpWidget(r.build());
    final TestGesture g = await grab(t, dir: 1);
    await g.moveBy(const Offset(40, 0));
    await t.pump();
    expect(r.savedOf(), isNull, reason: 'must not save while still pressed');
    await release(t, g);
    expect(r.savedOf(), r.width());
  });

  test('rail width can be saved and read back', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsStore store = await SettingsStore.open();
    // Nothing stored yet: pass null so the UI uses its default.
    expect(store.loadRailW(), isNull);

    await store.saveRailW(233);
    final SettingsStore again = await SettingsStore.open();
    expect(again.loadRailW(), 233);
  });
}
