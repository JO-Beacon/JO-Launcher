// UI language picker dialog.
//
// Options: follow system + seven languages. Language names use their own script
// and are not translated.

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import 'app_localizations.dart';

/// Returns the language code (or `system`) to the caller when a row is clicked.
Future<String?> showLanguagePicker(BuildContext context, String current) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext _) => _LanguageDialog(current: current),
  );
}

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog({required this.current});

  final String current;

  static const List<String> _codes = <String>[
    'system',
    'en',
    'ja',
    'sv',
    'pt',
    'es',
    'fr',
    'de',
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations s = context.l10n;
    final LauncherPalette p = LauncherTheme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(LauncherSpace.s5),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(LauncherSpace.s5),
        decoration: BoxDecoration(
          color: p.surface,
          border: LauncherShape.border(p.border),
          borderRadius: LauncherShape.br,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    s.t('settings.language'),
                    style: LauncherFonts.ui.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                ),
                LauncherIconAction(
                  icon: LauncherIcons.close,
                  tip: s.t('common.close'),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: LauncherSpace.s3),
            for (final String code in _codes)
              _LanguageRow(
                label:
                    AppLocalizations.languageName(code) ??
                    s.t('settings.languageSystem'),
                selected: code == current,
                onTap: () => Navigator.of(context).pop(code),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return LauncherTap(
      onTap: onTap,
      builder: (BuildContext context, bool hover, bool down) {
        return AnimatedContainer(
          duration: kTapMs,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: LauncherSpace.s3,
            vertical: LauncherSpace.s2 + 2,
          ),
          decoration: BoxDecoration(
            color: selected
                ? p.bg
                : (hover ? p.bg.withValues(alpha: 0.5) : null),
            border: Border(
              left: BorderSide(
                color: selected ? p.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LauncherFonts.ui.copyWith(
                    fontSize: 14,
                    color: selected ? p.accent : p.text,
                  ),
                ),
              ),
              if (selected)
                Icon(LauncherIcons.check, size: 14, color: p.accent),
            ],
          ),
        );
      },
    );
  }
}
