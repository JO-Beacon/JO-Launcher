// Hover text tooltip.
//
// Pins three things:
//   1. It waits a moment before appearing (it must not flash while the mouse
//      sweeps across a row);
//   2. The text really appears in the UI (the overlay contains the line);
//   3. Moving away hides it and leaves no timer behind.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/theme/tokens.dart';
import 'package:jolauncher/ui/tooltip.dart';

Widget host(Widget child) => MaterialApp(
  home: LauncherTheme(
    settings: const LauncherSettings(),
    palette: LauncherPalette.dark,
    child: Scaffold(body: Center(child: child)),
  ),
);

Widget anchor({Duration? wait}) => LauncherTooltip(
  text: 'Edit this world',
  wait: wait ?? const Duration(milliseconds: 350),
  child: const SizedBox(
    width: 60,
    height: 30,
    child: ColoredBox(color: Colors.black),
  ),
);

void main() {
  testWidgets('appears after a delay and hides on exit', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(host(anchor()));

    final TestGesture mouse = await t.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await t.pump();

    await mouse.moveTo(t.getCenter(find.byType(SizedBox).last));
    await t.pump();
    // Just hovered: it must not appear yet (it waits so sweeping across icons
    // does not flash).
    expect(find.text('Edit this world'), findsNothing);

    // After [wait], the overlay is inserted.
    await t.pump(const Duration(milliseconds: 400));
    await t.pump();
    expect(find.text('Edit this world'), findsOneWidget);

    // Move away: hide it.
    await mouse.moveTo(const Offset(1, 1));
    await t.pumpAndSettle();
    expect(find.text('Edit this world'), findsNothing);
  });

  testWidgets('leaving early cancels the timer', (WidgetTester t) async {
    await t.pumpWidget(host(anchor()));

    final TestGesture mouse = await t.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await t.pump();

    await mouse.moveTo(t.getCenter(find.byType(SizedBox).last));
    await t.pump();
    await mouse.moveTo(const Offset(1, 1));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Edit this world'), findsNothing);
  });

  testWidgets('wait time is configurable (0 = immediate)', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(host(anchor(wait: Duration.zero)));

    final TestGesture mouse = await t.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await t.pump();

    await mouse.moveTo(t.getCenter(find.byType(SizedBox).last));
    await t.pump();
    await t.pump(const Duration(milliseconds: 1));
    expect(find.text('Edit this world'), findsOneWidget);
  });

  // The overlay size used to be computed as measured width + padding + single
  // line ellipsis; a tiny measurement error clipped the last character with
  // “...”. Now the text decides its own size.
  testWidgets('overlay size follows the text and never truncates', (
    WidgetTester t,
  ) async {
    const String long = 'Deselect this step (a deliberately long tooltip text)';
    const TextScaler scaler = TextScaler.linear(1.5);

    await t.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(textScaler: scaler),
          child: LauncherTooltip(
            text: long,
            wait: Duration.zero,
            child: const SizedBox(width: 24, height: 24),
          ),
        ),
      ),
    );

    final TestGesture mouse = await t.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await t.pump();
    await mouse.moveTo(t.getCenter(find.byType(SizedBox).last));
    await t.pump();
    await t.pump(const Duration(milliseconds: 1));

    final Finder text = find.text(long);
    expect(text, findsOneWidget);

    // Same style and scale factor should produce the same size as real rendering.
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: long,
        style: LauncherFonts.meta.copyWith(
          color: LauncherPalette.dark.text,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final Size rendered = t.getSize(text);
    expect(rendered.width, closeTo(tp.width, 1));
    expect(rendered.height, closeTo(tp.height, 1));

    // The outer panel must not be narrower than the text (that would clip it).
    final Size panel = t.getSize(
      find.ancestor(of: text, matching: find.byType(Container)).last,
    );
    expect(
      panel.width,
      greaterThanOrEqualTo(rendered.width + LauncherSpace.s2 * 2 - 0.5),
    );
    expect(
      panel.height,
      greaterThanOrEqualTo(rendered.height + LauncherSpace.s1 * 2 - 0.5),
    );
  });
}
