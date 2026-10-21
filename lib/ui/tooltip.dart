// Hover text tooltip (custom-drawn; Flutter's built-in Tooltip is not used).
//
// Why not the built-in one:
//   · It follows the Material theme — radius, shadow and font size do not match
//     this UI.
//   · It inserts an Overlay layer and manages its own timer, which tends to
//     leave uncleaned state in tests.
//
// This widget does one thing: after the pointer rests for [wait], show a small
// line of text next to it; hide it on exit. It does not take focus or clicks
// (the overlay uses IgnorePointer).

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class LauncherTooltip extends StatefulWidget {
  const LauncherTooltip({
    super.key,
    required this.text,
    required this.child,
    this.wait = const Duration(milliseconds: 350),
  });

  final String text;
  final Widget child;

  /// Delay before showing; too short makes it flicker while the mouse moves.
  final Duration wait;

  @override
  State<LauncherTooltip> createState() => _LauncherTooltipState();
}

class _LauncherTooltipState extends State<LauncherTooltip> {
  Timer? _timer;
  OverlayEntry? _entry;

  @override
  void dispose() {
    _timer?.cancel();
    _remove();
    super.dispose();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    if (_entry != null) {
      _remove();
      setState(() {});
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(widget.wait, _show);
  }

  TextStyle _style(LauncherPalette p) =>
      LauncherFonts.meta.copyWith(color: p.text, fontSize: 10);

  void _show() {
    if (!mounted || _entry != null) return;
    final RenderObject? ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;
    final RenderBox box = ro;
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);

    final LauncherPalette p = LauncherTheme.of(context);
    final TextStyle style = _style(p);

    // Measure the text only to decide where to place the overlay (centered,
    // never outside the window). Do not pin the overlay size: its width follows
    // the text, otherwise being one pixel off would clip the last character
    // (the old bug: fixed width = measured width + padding, plus
    // maxLines/ellipsis, so a tiny mismatch produced “…”).
    final TextPainter tp = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double w = tp.width + LauncherSpace.s2 * 2;

    final Size screen = MediaQuery.sizeOf(context);
    final Offset at = box.localToGlobal(Offset.zero);
    const double gap = 6;
    const double edge = 6;

    // Above by default; below when there is no room above.
    double top = at.dy - (tp.height + LauncherSpace.s1 * 2) - gap;
    if (top < edge) top = at.dy + box.size.height + gap;
    double left = at.dx + box.size.width / 2 - w / 2;
    left = left.clamp(
      edge,
      (screen.width - w - edge).clamp(edge, double.infinity),
    );

    _entry = OverlayEntry(
      builder: (BuildContext c) => Positioned(
        left: left,
        top: top,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LauncherSpace.s2,
              vertical: LauncherSpace.s1,
            ),
            decoration: BoxDecoration(
              color: p.surface,
              border: LauncherShape.border(p.border),
              borderRadius: LauncherShape.br,
            ),
            // No wrapping or clipping: width and height follow the text.
            child: Text(
              widget.text,
              style: style,
              softWrap: false,
              textScaler: MediaQuery.textScalerOf(context),
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _schedule(),
      onExit: (_) => _cancel(),
      child: widget.child,
    );
  }
}
