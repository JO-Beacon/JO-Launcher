import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Shared frame for right-pane pages: header + scrollable content.
///
/// Content is width-limited and centered by `maxContentWidth`; a launcher
/// window can be very wide, and 2000px lines are unreadable.
class LauncherPageFrame extends StatelessWidget {
  const LauncherPageFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
    this.maxContentWidth = 760,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(
            LauncherSpace.s6,
            LauncherSpace.s5,
            LauncherSpace.s6,
            LauncherSpace.s4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: LauncherFonts.ui.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: LauncherSpace.s1),
                      Text(
                        subtitle!,
                        style: LauncherFonts.meta.copyWith(color: p.secondary),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              LauncherSpace.s6,
              0,
              LauncherSpace.s6,
              LauncherSpace.s6,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Placeholder block: a user-facing sentence explaining that this area is
/// not available yet.
///
/// **Do not put the todo list here** — todos are for the project docs, not
/// the binary.
class LauncherPending extends StatelessWidget {
  const LauncherPending({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(LauncherSpace.s4),
      decoration: BoxDecoration(
        color: p.surface,
        border: LauncherShape.border(p.border),
        borderRadius: LauncherShape.br,
      ),
      child: Text(
        text,
        style: LauncherFonts.meta.copyWith(color: p.secondary, height: 1.6),
      ),
    );
  }
}
