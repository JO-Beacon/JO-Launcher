import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'icons.dart';
import 'tooltip.dart';

/// Animation primitive for clickable areas: hover / press. The builder draws
/// from the state it receives. The minimal style is restrained: 120ms, only
/// background and border change.
class LauncherTap extends StatefulWidget {
  const LauncherTap({
    super.key,
    required this.onTap,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
    this.opaque = true,
  });

  final VoidCallback onTap;
  final Widget Function(BuildContext context, bool hover, bool down) builder;
  final MouseCursor cursor;
  final bool opaque;

  @override
  State<LauncherTap> createState() => _LauncherTapState();
}

class _LauncherTapState extends State<LauncherTap> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: GestureDetector(
        behavior: widget.opaque
            ? HitTestBehavior.opaque
            : HitTestBehavior.deferToChild,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: widget.builder(context, _hover, _down),
      ),
    );
  }
}

/// Animation duration (one place, easy to tune).
const Duration kTapMs = Duration(milliseconds: 120);

/// Clickable text (optional thin border).
/// A symbol-only action (toolbar, back button).
///
/// Hover / press: background lifts (text color 9% / 20%) and the icon brightens
/// from secondary to primary. No border — that would make every icon a little
/// box, unlike the rest of the toolbar.
///
/// **tip is required**: every icon in the UI must reveal its name on hover.
///
/// [inverted] uses a solid accent background with a background-colored icon
/// for primary actions (e.g. send).
class LauncherIconAction extends StatelessWidget {
  const LauncherIconAction({
    super.key,
    required this.icon,
    required this.tip,
    required this.onTap,
    this.size = 16,
    this.inverted = false,
  });

  final IconData icon;

  /// Name shown on hover. Required; must not be empty.
  final String tip;

  final VoidCallback onTap;
  final double size;

  /// Inverted: solid accent background + background-colored icon; for primary actions.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return LauncherTooltip(
      text: tip,
      child: LauncherTap(
        onTap: onTap,
        opaque: false,
        builder: (BuildContext c, bool hover, bool down) {
          final double a = down ? 0.20 : (hover ? 0.09 : 0.0);
          // Inverted background: blend toward the text color, so the dark theme
          // gets lighter and the light theme gets darker — both more prominent.
          // Blending with the background directly would invert the effect.
          final Color bgColor = inverted
              ? Color.alphaBlend(
                  p.text.withValues(alpha: hover || down ? 0.28 : 0.0),
                  p.accent,
                )
              : p.icon.withValues(alpha: a);
          final Color fgColor = inverted
              ? p.bg
              : ((hover || down) ? p.text : p.icon);
          return AnimatedContainer(
            duration: kTapMs,
            curve: Curves.easeOut,
            // Padding is equal on all four sides. Asymmetric padding makes the
            // icon off-center.
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bgColor),
            child: Icon(icon, size: size, color: fgColor),
          );
        },
      ),
    );
  }
}

class LauncherButton extends StatelessWidget {
  const LauncherButton({
    super.key,
    required this.text,
    required this.onTap,
    this.color,
    this.bordered = false,
    this.tip,
    this.enabled = true,
  });

  final String text;
  final VoidCallback onTap;
  final Color? color;
  final bool bordered;

  /// Hover text tooltip; for symbol-only buttons such as × or ↺.
  final String? tip;

  /// When unavailable it is shown greyed out and does not respond to clicks.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    final Color tint = color ?? p.secondary;
    final Color base = enabled ? tint : tint.withValues(alpha: 0.45);
    final EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: LauncherSpace.s3,
      vertical: LauncherSpace.s1 + 2,
    );
    final Widget button = enabled
        ? LauncherTap(
            onTap: onTap,
            opaque: false,
            builder: (BuildContext context, bool hover, bool down) {
              final double a = down ? 0.20 : (hover ? 0.09 : 0.0);
              return AnimatedContainer(
                duration: kTapMs,
                curve: Curves.easeOut,
                padding: padding,
                decoration: BoxDecoration(
                  color: a == 0
                      ? Colors.transparent
                      : base.withValues(alpha: a),
                  border: bordered
                      ? LauncherShape.border(hover || down ? base : p.border)
                      : null,
                  borderRadius: LauncherShape.br,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: kTapMs,
                  curve: Curves.easeOut,
                  style: LauncherFonts.meta.copyWith(
                    color: hover || down ? (color ?? p.text) : base,
                  ),
                  child: Text(text),
                ),
              );
            },
          )
        : Container(
            padding: padding,
            decoration: BoxDecoration(
              border: bordered ? LauncherShape.border(p.border) : null,
              borderRadius: LauncherShape.br,
            ),
            child: Text(text, style: LauncherFonts.meta.copyWith(color: base)),
          );
    return tip == null ? button : LauncherTooltip(text: tip!, child: button);
  }
}

/// Segmented control (a row of thin cells).
class LauncherSegment<T> extends StatelessWidget {
  const LauncherSegment({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<({String label, T value})> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < options.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: LauncherSpace.s2),
          _cell(context, p, options[i]),
        ],
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    LauncherPalette p,
    ({String label, T value}) o,
  ) {
    final bool on = o.value == value;
    return LauncherTap(
      onTap: () => onChanged(o.value),
      opaque: false,
      builder: (BuildContext context, bool hover, bool down) {
        return AnimatedContainer(
          duration: kTapMs,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: LauncherSpace.s3,
            vertical: LauncherSpace.s1 + 2,
          ),
          decoration: BoxDecoration(
            color: on
                ? p.surface
                : (hover
                      ? p.surface.withValues(alpha: 0.6)
                      : Colors.transparent),
            border: LauncherShape.border(on || hover ? p.accent : p.border),
            borderRadius: LauncherShape.br,
          ),
          child: AnimatedDefaultTextStyle(
            duration: kTapMs,
            curve: Curves.easeOut,
            style: LauncherFonts.meta.copyWith(
              color: on ? p.accent : p.secondary,
            ),
            child: Text(o.label),
          ),
        );
      },
    );
  }
}

/// Settings section: small title + content.
class LauncherSection extends StatelessWidget {
  const LauncherSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: LauncherSpace.s2),
          child: Text(
            title,
            style: LauncherFonts.meta.copyWith(
              color: p.secondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            border: LauncherShape.border(p.border),
            borderRadius: LauncherShape.br,
          ),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) Divider(height: 1, thickness: 1, color: p.border),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Settings row: label on the left, control on the right.
class LauncherField extends StatelessWidget {
  const LauncherField({
    super.key,
    required this.label,
    this.hint,
    required this.child,
  });

  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LauncherSpace.s4,
        vertical: LauncherSpace.s3,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: LauncherFonts.ui.copyWith(fontSize: 14, color: p.text),
                ),
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      hint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LauncherFonts.meta.copyWith(color: p.secondary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: LauncherSpace.s3),
          child,
        ],
      ),
    );
  }
}

/// Page header: title + back.
class LauncherPageHeader extends StatelessWidget {
  const LauncherPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: LauncherSpace.s4),
      decoration: BoxDecoration(
        border: Border(bottom: LauncherShape.side(p.border)),
      ),
      child: Row(
        children: <Widget>[
          // Back button: icon instead of text (left arrow in the top-left).
          LauncherIconAction(
            icon: LauncherIcons.arrowLeft,
            tip: context.t('common.back'),
            onTap: onBack,
          ),
          const SizedBox(width: LauncherSpace.s4),
          Text(
            title,
            style: LauncherFonts.ui.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Text input (self-contained; the parent can reset it by changing the key).
/// Shortcut input: click to capture, then press the key combination you want.
///
/// No typing “Ctrl+E” by hand.
/// Esc cancels capture (it does not record Esc).
class LauncherKeyField extends StatefulWidget {
  const LauncherKeyField({
    super.key,
    required this.spec,
    required this.onChanged,
  });

  /// Current key spec, e.g. 'Ctrl+E'. Empty = unset.
  final String spec;
  final ValueChanged<String> onChanged;

  @override
  State<LauncherKeyField> createState() => _LauncherKeyFieldState();
}

class _LauncherKeyFieldState extends State<LauncherKeyField> {
  final FocusNode _focus = FocusNode();
  bool _capturing = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Translates a key event into 'Ctrl+E'. Returns null when only modifiers
  /// are pressed (keep waiting).
  String? _specOf(KeyEvent e) {
    final LogicalKeyboardKey k = e.logicalKey;
    if (k == LogicalKeyboardKey.controlLeft ||
        k == LogicalKeyboardKey.controlRight ||
        k == LogicalKeyboardKey.shiftLeft ||
        k == LogicalKeyboardKey.shiftRight ||
        k == LogicalKeyboardKey.altLeft ||
        k == LogicalKeyboardKey.altRight ||
        k == LogicalKeyboardKey.metaLeft ||
        k == LogicalKeyboardKey.metaRight) {
      return null;
    }
    final HardwareKeyboard kb = HardwareKeyboard.instance;
    final List<String> parts = <String>[];
    if (kb.isControlPressed) parts.add('Ctrl');
    if (kb.isShiftPressed) parts.add('Shift');
    if (kb.isAltPressed) parts.add('Alt');
    final String label = k.keyLabel;
    if (label.isEmpty) return null;
    parts.add(label);
    return parts.join('+');
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _capturing = true);
          _focus.requestFocus();
        },
        child: Focus(
          focusNode: _focus,
          onFocusChange: (bool has) {
            if (!has && _capturing) setState(() => _capturing = false);
          },
          onKeyEvent: (FocusNode node, KeyEvent e) {
            // Pressing Esc while capturing clears this entry (sets it to unset).
            // When not capturing, leave it alone and let the event propagate
            // (dialogs can still use Esc to close).
            if (_capturing && e.logicalKey == LogicalKeyboardKey.escape) {
              if (e is KeyDownEvent) {
                widget.onChanged('');
                setState(() => _capturing = false);
              }
              return KeyEventResult.handled;
            }
            if (!_capturing) return KeyEventResult.ignored;
            if (e is! KeyDownEvent) return KeyEventResult.handled;
            final String? spec = _specOf(e);
            if (spec == null) return KeyEventResult.handled;
            widget.onChanged(spec);
            setState(() => _capturing = false);
            return KeyEventResult.handled;
          },
          child: Container(
            height: 32,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: LauncherSpace.s3),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: _capturing ? p.accent : p.border),
            ),
            child: Text(
              _capturing
                  ? context.t('common.keyPress')
                  : (widget.spec.trim().isEmpty
                        ? context.t('common.keyUnset')
                        : widget.spec),
              style: LauncherFonts.ui.copyWith(
                fontSize: 13,
                color: _capturing
                    ? p.accent
                    : (widget.spec.trim().isEmpty ? p.secondary : p.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LauncherInput extends StatefulWidget {
  const LauncherInput({
    super.key,
    required this.initial,
    required this.onChanged,
    this.hint,
    this.compact = false,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool compact;

  @override
  State<LauncherInput> createState() => _LauncherInputState();
}

class _LauncherInputState extends State<LauncherInput> {
  late final TextEditingController _c;
  late String _sent;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    // Must be set in initState. Do not use late lazy initialization: the
    // first lazy access happens in didUpdateWidget, when widget.initial is
    // already the new value, so external changes can never be detected.
    _sent = widget.initial;
  }

  @override
  void didUpdateWidget(LauncherInput old) {
    super.didUpdateWidget(old);
    // External value changed (e.g. group rename) → follow it; text typed by
    // the user is left alone so the cursor does not jump.
    if (widget.initial != _sent) {
      _sent = widget.initial;
      _c.text = widget.initial;
      _c.selection = TextSelection.collapsed(offset: _c.text.length);
    }
  }

  void _onChanged(String v) {
    _sent = v;
    widget.onChanged(v);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    final double size = widget.compact ? 12 : 13;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LauncherSpace.s3,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        border: LauncherShape.border(p.border),
        borderRadius: LauncherShape.br,
      ),
      child: LauncherTextField(
        controller: _c,
        onChanged: _onChanged,
        style: LauncherFonts.ui.copyWith(fontSize: size, color: p.text),
        hint: widget.hint,
        hintStyle: LauncherFonts.ui.copyWith(
          fontSize: size,
          color: p.secondary,
        ),
      ),
    );
  }
}

/// Input field: `EditableText` + hint, **without Material**.
///
/// Why not the built-in `TextField`: it requires a `Material` ancestor. This
/// UI is custom-drawn and has no `Material` in the tree, so debug builds throw
/// a red screen (the check is compiled out in release, but ink / focus
/// highlight / default text styles are all missing). Every input goes through
/// here; border, background and padding come from the outer Container.
///
/// **`EditableText` alone cannot select text**: drag selection, double-click
/// word selection, triple-click line selection, Shift+click extension and the
/// context menu are gestures added by `TextField`. This widget restores them
/// with [TextSelectionGestureDetectorBuilder] (public API).
///
/// Height matches the old `TextField(isDense: true, border: InputBorder.none)`:
/// it is 8 taller than plain text, so leave 4 top and bottom (adjustable with
/// [verticalPadding]).
class LauncherTextField extends StatefulWidget {
  const LauncherTextField({
    super.key,
    required this.controller,
    required this.style,
    this.hint,
    this.hintStyle,
    this.obscureText = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.verticalPadding = 4,
  });

  final TextEditingController controller;
  final TextStyle style;
  final String? hint;
  final TextStyle? hintStyle;
  final bool obscureText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// `null` = unlimited lines (multiline). Must be 1 when [obscureText] is true.
  final int? maxLines;

  /// Minimum number of lines (follows content when null). Multiline boxes use
  /// it to reserve the initial height.
  final int? minLines;

  /// Pass a node when the parent manages focus (e.g. submit on blur);
  /// otherwise one is created internally.
  final FocusNode? focusNode;

  final double verticalPadding;

  @override
  State<LauncherTextField> createState() => _LauncherTextFieldState();
}

class _LauncherTextFieldState extends State<LauncherTextField> {
  FocusNode? _ownFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    // Use the UI accent for the selection color: Cupertino reads it from
    // `DefaultSelectionStyle`, whose default is system blue and clashes with
    // this dark UI.
    return DefaultSelectionStyle(
      selectionColor: p.accent.withValues(alpha: 0.3),
      cursorColor: p.accent,
      child: CupertinoTextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        obscureText: widget.obscureText,
        style: widget.style,
        placeholder: widget.hint,
        placeholderStyle:
            widget.hintStyle ?? widget.style.copyWith(color: p.secondary),
        cursorColor: p.accent,
        // Background, border and radius are provided by the outer Container;
        // draw nothing here.
        decoration: const BoxDecoration(),
        // Padding inside the box so the whole box is clickable, not just the
        // text line.
        padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        // Customize the menu appearance: Cupertino's default is a large rounded
        // grey panel that does not match this UI.
        // **Layout** remains Flutter's job (`TextSelectionToolbar` places the
        // menu above/below the selection); only the shell is restyled.
        contextMenuBuilder: (BuildContext c, EditableTextState st) =>
            _toolbar(st, p),
      ),
    );
  }

  /// Menu shown after selecting text: square corners, same surface/border as
  /// cards, and the UI font.
  ///
  /// Actions call `EditableTextState` methods directly; they dismiss the menu
  /// themselves.
  Widget _toolbar(EditableTextState st, LauncherPalette p) {
    final MaterialLocalizations m = MaterialLocalizations.of(context);
    final TextEditingValue v = widget.controller.value;
    final TextSelection sel = v.selection;
    final bool hasSel = sel.isValid && !sel.isCollapsed;
    final bool hasText = v.text.isNotEmpty;
    final bool allSel = hasText && sel.start == 0 && sel.end == v.text.length;
    final TextSelectionToolbarAnchors a = st.contextMenuAnchors;

    final List<({String label, VoidCallback? onTap})> items =
        <({String label, VoidCallback? onTap})>[
          if (!widget.obscureText)
            (
              label: m.cutButtonLabel,
              onTap: hasSel
                  ? () => st.cutSelection(SelectionChangedCause.toolbar)
                  : null,
            ),
          if (!widget.obscureText)
            (
              label: m.copyButtonLabel,
              onTap: hasSel
                  ? () => st.copySelection(SelectionChangedCause.toolbar)
                  : null,
            ),
          (
            label: m.pasteButtonLabel,
            onTap: () => st.pasteText(SelectionChangedCause.toolbar),
          ),
          (
            label: m.selectAllButtonLabel,
            onTap: hasText && !allSel
                ? () => st.selectAll(SelectionChangedCause.toolbar)
                : null,
          ),
        ];

    return TextSelectionToolbar(
      anchorAbove: a.primaryAnchor,
      anchorBelow: a.secondaryAnchor ?? a.primaryAnchor,
      toolbarBuilder: (BuildContext ctx, Widget child) => Container(
        decoration: BoxDecoration(
          color: p.surface,
          border: LauncherShape.border(p.border),
          // Square corners: same tiny 2px radius as cards, not Cupertino's large radius.
          borderRadius: LauncherShape.br,
        ),
        child: child,
      ),
      children: <Widget>[
        for (final ({String label, VoidCallback? onTap}) it in items)
          _LauncherToolbarButton(palette: p, label: it.label, onTap: it.onTap),
      ],
    );
  }
}

/// A text button in the selection menu (custom-drawn, not Material `TextButton`).
class _LauncherToolbarButton extends StatefulWidget {
  const _LauncherToolbarButton({
    required this.palette,
    required this.label,
    required this.onTap,
  });

  final LauncherPalette palette;
  final String label;

  /// `null` = currently unavailable (greyed out; clicking does nothing).
  final VoidCallback? onTap;

  @override
  State<_LauncherToolbarButton> createState() => _LauncherToolbarButtonState();
}

class _LauncherToolbarButtonState extends State<_LauncherToolbarButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = widget.palette;
    final bool on = widget.onTap != null;
    return MouseRegion(
      cursor: on ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LauncherSpace.s3,
            vertical: 6,
          ),
          color: on && _hover ? p.border.withValues(alpha: 0.5) : null,
          child: Text(
            widget.label,
            style: LauncherFonts.ui.copyWith(
              fontSize: 12,
              color: on ? p.text : p.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle: text style (`Enabled` / `Disabled`), not a slider.
class LauncherToggle extends StatelessWidget {
  const LauncherToggle({
    super.key,
    required this.on,
    required this.onChanged,
    this.onLabel,
    this.offLabel,
  });

  final bool on;
  final ValueChanged<bool> onChanged;

  /// When null, use the localized Enabled / Disabled labels.
  final String? onLabel;
  final String? offLabel;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!on),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LauncherSpace.s3,
            vertical: LauncherSpace.s1 + 2,
          ),
          decoration: BoxDecoration(
            color: on ? p.surface : Colors.transparent,
            border: LauncherShape.border(on ? p.accent : p.border),
            borderRadius: LauncherShape.br,
          ),
          child: Text(
            on
                ? (onLabel ?? context.t('common.enabled'))
                : (offLabel ?? context.t('common.disabled')),
            style: LauncherFonts.meta.copyWith(
              color: on ? p.accent : p.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
