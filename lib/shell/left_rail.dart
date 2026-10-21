import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import 'nav.dart';

/// Left rail: three entries and the account area at the bottom.
///
/// The width is controlled by the parent (the splitter changes the outer
/// value); this widget only lays out its contents.
class LauncherRail extends StatelessWidget {
  const LauncherRail({
    super.key,
    required this.tab,
    required this.onTabChanged,
    this.playerName,
    this.onLogin,
  });

  final LauncherTab tab;
  final ValueChanged<LauncherTab> onTabChanged;

  /// Player name when signed in; null otherwise.
  final String? playerName;

  /// Sign-in callback when signed out; null hides the button.
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: LauncherSpace.s3),
        for (final LauncherTab t in LauncherTab.values)
          _NavItem(tab: t, selected: t == tab, onTap: () => onTabChanged(t)),
        const Spacer(),
        _account(context, p),
      ],
    );
  }

  Widget _account(BuildContext context, LauncherPalette p) {
    final bool signedIn = playerName != null;
    final VoidCallback? action = signedIn ? null : onLogin;

    Widget content(bool hover) {
      return Container(
        padding: const EdgeInsets.fromLTRB(
          LauncherSpace.s4,
          LauncherSpace.s3,
          LauncherSpace.s4,
          LauncherSpace.s4,
        ),
        decoration: BoxDecoration(
          color: hover ? p.surface.withValues(alpha: 0.4) : null,
          border: Border(top: LauncherShape.side(p.border)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: p.surface,
                border: LauncherShape.border(p.border),
                borderRadius: LauncherShape.br,
              ),
              child: Icon(
                LauncherIcons.user,
                size: 16,
                color: hover ? p.accent : p.icon,
              ),
            ),
            const SizedBox(width: LauncherSpace.s3),
            Expanded(
              child: Text(
                playerName ?? context.t('rail.microsoftLogin'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LauncherFonts.ui.copyWith(
                  fontSize: 13,
                  color: signedIn ? p.text : (hover ? p.text : p.secondary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (action == null) return content(false);
    return LauncherTap(
      onTap: action,
      builder: (BuildContext context, bool hover, bool down) =>
          content(hover || down),
    );
  }
}

/// A navigation entry. When selected: raised background + left accent bar +
/// accent text color.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final LauncherTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LauncherSpace.s2),
      child: LauncherTap(
        onTap: onTap,
        builder: (BuildContext context, bool hover, bool down) {
          final bool lit = selected || hover;
          return AnimatedContainer(
            duration: kTapMs,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: LauncherSpace.s3,
              vertical: LauncherSpace.s2 + 2,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? p.surface
                  : (hover ? p.surface.withValues(alpha: 0.5) : null),
              border: Border(
                left: BorderSide(
                  color: selected ? p.accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  tab.icon,
                  size: 16,
                  color: lit ? (selected ? p.accent : p.text) : p.icon,
                ),
                const SizedBox(width: LauncherSpace.s3),
                Expanded(
                  child: Text(
                    context.t(tab.labelKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LauncherFonts.ui.copyWith(
                      fontSize: 14,
                      color: selected
                          ? p.accent
                          : (hover ? p.text : p.secondary),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
