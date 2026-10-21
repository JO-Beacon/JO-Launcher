import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../ui/common.dart';
import 'privacy_store.dart';

/// Ensures the user has read and accepted the current privacy notice before
/// signing in.
///
/// Consent is recorded per device; returns true immediately when accepted.
Future<bool> ensurePrivacyConsent(
  BuildContext context,
  PrivacyStore store,
) async {
  if (store.accepted) return true;

  final bool? accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext c) {
      final LauncherPalette p = LauncherTheme.of(c);
      final AppLocalizations s = c.l10n;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(LauncherSpace.s5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Container(
            padding: const EdgeInsets.all(LauncherSpace.s5),
            decoration: BoxDecoration(
              color: p.surface,
              border: LauncherShape.border(p.border),
              borderRadius: LauncherShape.br,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.t('privacy.title'),
                  style: LauncherFonts.ui.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: LauncherSpace.s3),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      s.t('privacy.summary'),
                      style: LauncherFonts.meta.copyWith(
                        color: p.secondary,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: LauncherSpace.s5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    LauncherButton(
                      text: s.t('common.cancel'),
                      bordered: true,
                      onTap: () => Navigator.of(c).pop(false),
                    ),
                    const SizedBox(width: LauncherSpace.s3),
                    LauncherButton(
                      text: s.t('privacy.agree'),
                      onTap: () => Navigator.of(c).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (accepted != true) return false;
  await store.accept();
  return true;
}
