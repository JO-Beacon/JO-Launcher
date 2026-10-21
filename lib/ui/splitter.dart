// The draggable gap between panes.
//
// Based on JO-Composer (docking + multi_split_view). Four rules matter:
//
//   1. **Easy to grab**: the hit area is much wider than the painted line.
//      The line is 1px (2px on hover), but the grab area is 10px — it used to
//      be 6px, which required precise pointing.
//   2. **No stickiness**: on press, record the current width and mouse x; on
//      every move compute `current mouse - press position` to derive an
//      absolute width, **not** frame-by-frame deltas. Delta-based drags get
//      stuck at a minimum width and need to “pay back” overshoot when moving
//      back; absolute values do not drift.
//   3. **Bounds**: both the rail and the adjacent pane have minimum widths; the
//      canvas in the middle must not be squeezed away. The maximum is computed
//      from the current window width, so shrinking the window cannot overflow.
//   4. **Feedback**: hover makes the line thicker/brighter, press keeps it lit;
//      double-click resets to the default width.

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'common.dart';

/// Hit width of the splitter (the painted line stays 1–2px).
const double kSplitterHit = 10;

/// Total horizontal space taken by both splitters (used for canvas width).
const double kSplitterTotal = kSplitterHit * 2;

class LauncherSplitter extends StatefulWidget {
  const LauncherSplitter({
    super.key,
    required this.palette,
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.defaultWidth,
    required this.growsRight,
    required this.onResize,
    this.onResizeEnd,
  });

  final LauncherPalette palette;

  /// Current width of the rail controlled by this splitter (recorded on press).
  final double width;

  final double minWidth;

  /// Maximum width, computed by the parent from the window width.
  final double maxWidth;

  /// Width restored on double-click.
  final double defaultWidth;

  /// Dragging right increases width (left rail, true) or decreases it
  /// (right rail, false).
  final bool growsRight;

  /// Reports the desired width while dragging.
  final ValueChanged<double> onResize;

  /// Called on release (for persistence).
  final VoidCallback? onResizeEnd;

  @override
  State<LauncherSplitter> createState() => _LauncherSplitterState();
}

class _LauncherSplitterState extends State<LauncherSplitter> {
  /// At press time: rail width + mouse x. The whole drag is computed from
  /// these two absolute values.
  double _startWidth = 0;
  double _startX = 0;

  bool _hover = false;
  bool _active = false;

  double get _clamped =>
      widget.width.clamp(widget.minWidth, _safeMax).toDouble();

  /// maxWidth should not be smaller than minWidth; if it is, use min to avoid
  /// `lower > upper` in clamp.
  double get _safeMax =>
      widget.maxWidth < widget.minWidth ? widget.minWidth : widget.maxWidth;

  void _apply(double want) =>
      widget.onResize(want.clamp(widget.minWidth, _safeMax));

  void _start(DragStartDetails d) {
    _startWidth = _clamped;
    _startX = d.globalPosition.dx;
    setState(() => _active = true);
  }

  void _update(DragUpdateDetails d) {
    final double moved = d.globalPosition.dx - _startX;
    _apply(widget.growsRight ? _startWidth + moved : _startWidth - moved);
  }

  void _end() {
    setState(() => _active = false);
    widget.onResizeEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = widget.palette;
    final bool lit = _hover || _active;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _start,
        onHorizontalDragUpdate: _update,
        onHorizontalDragEnd: (_) => _end(),
        onHorizontalDragCancel: _end,
        onDoubleTap: () => _apply(widget.defaultWidth),
        child: SizedBox(
          width: kSplitterHit,
          height: double.infinity,
          child: Center(
            // Normally a divider line; hover/press makes it thicker and brighter
            // to show that it can be dragged.
            child: AnimatedContainer(
              duration: kTapMs,
              curve: Curves.easeOut,
              width: lit ? 2 : 1,
              color: lit ? p.accent : p.border,
            ),
          ),
        ),
      ),
    );
  }
}
