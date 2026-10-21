import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../platform/open_url.dart';
import '../theme/tokens.dart';
import '../ui/common.dart';
import '../ui/icons.dart';

const String kPrivacyNoticeUrl =
    'https://github.com/JO-Beacon/JO-Launcher/blob/main/PRIVACY.md';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _linkFailed = false;

  Future<void> _openFullNotice() async {
    final bool ok = await openUrl(kPrivacyNoticeUrl);
    if (!mounted || ok) return;
    setState(() => _linkFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    final AppLocalizations s = context.l10n;
    return Container(
      color: p.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(LauncherSpace.s4),
            child: Row(
              children: <Widget>[
                LauncherIconAction(
                  icon: LauncherIcons.arrowLeft,
                  tip: s.t('common.back'),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: LauncherSpace.s4),
                Text(
                  s.t('privacy.title'),
                  style: LauncherFonts.ui.copyWith(fontSize: 15, color: p.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: LauncherSpace.s5,
                vertical: LauncherSpace.s3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.t('privacy.summary'),
                    style: LauncherFonts.meta.copyWith(
                      color: p.secondary,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: LauncherSpace.s4),
                  LauncherButton(
                    text: s.t('privacy.fullNotice'),
                    bordered: true,
                    onTap: _openFullNotice,
                  ),
                  if (_linkFailed) ...<Widget>[
                    const SizedBox(height: LauncherSpace.s2),
                    Text(
                      s.t('privacy.linkError'),
                      style: LauncherFonts.meta.copyWith(color: p.secondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
