import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../l10n/language_picker.dart';
import '../platform/dir_picker.dart' as platform;
import '../shell/page_frame.dart';
import '../theme/tokens.dart';
import '../ui/common.dart';
import '../ui/licenses_page.dart';
import '../ui/privacy_page.dart';

/// Settings page (global): appearance, game directory, account and about.
///
/// Per-version Java, memory and JVM arguments live on the Version settings page.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.gameDir,
    required this.onGameDirChanged,
    required this.accountName,
    required this.onLogin,
    required this.onLogout,
    this.onDeleteAccount,
    this.chooseDirectory = platform.pickDirectory,
  });

  final LauncherSettings settings;
  final ValueChanged<LauncherSettings> onChanged;

  /// Global game directory (the `.minecraft` level).
  final String gameDir;
  final ValueChanged<String> onGameDirChanged;

  /// Signed-in player name; null when signed out.
  final String? accountName;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  /// Deletes the account and local account data; null hides the entry.
  final Future<void> Function()? onDeleteAccount;

  /// System directory picker; tests replace it with a fixed result.
  final Future<String?> Function(String initialDirectory) chooseDirectory;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Reason the picker failed; usually null and takes no space.
  String? _notice;

  Future<void> _chooseDir() async {
    setState(() => _notice = null);
    try {
      final String? picked = await widget.chooseDirectory(widget.gameDir);
      if (!mounted || picked == null || picked == widget.gameDir) return;
      widget.onGameDirChanged(picked);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = context.l10n.t('settings.pickerError', <String, Object>{
          'error': '$error',
        });
      });
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final Future<void> Function()? delete = widget.onDeleteAccount;
    if (delete == null) return;
    setState(() => _notice = null);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) {
        final LauncherPalette p = LauncherTheme.of(c);
        final AppLocalizations s = c.l10n;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(LauncherSpace.s5),
          child: Container(
            width: 460,
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
                  s.t('settings.deleteAccountTitle'),
                  style: LauncherFonts.ui.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: LauncherSpace.s3),
                Text(
                  s.t('settings.deleteAccountMessage'),
                  style: LauncherFonts.meta.copyWith(
                    color: p.secondary,
                    height: 1.6,
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
                      text: s.t('common.delete'),
                      onTap: () => Navigator.of(c).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;
    try {
      await delete();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = context.l10n.t(
          'settings.deleteAccountError',
          <String, Object>{'error': '$error'},
        );
      });
    }
  }

  Future<void> _pickLanguage() async {
    final String? code = await showLanguagePicker(
      context,
      widget.settings.locale,
    );
    if (!mounted || code == null || code == widget.settings.locale) return;
    widget.onChanged(widget.settings.copyWith(locale: code));
  }

  String _languageLabel(AppLocalizations s) {
    if (widget.settings.locale == 'system') {
      return s.t('settings.languageSystem');
    }
    return AppLocalizations.languageName(widget.settings.locale) ??
        widget.settings.locale;
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    final AppLocalizations s = context.l10n;
    return LauncherPageFrame(
      title: s.t('settings.title'),
      subtitle: s.t('settings.subtitle'),
      children: <Widget>[
        LauncherSection(
          title: s.t('settings.sectionLanguage'),
          children: <Widget>[
            LauncherField(
              label: s.t('settings.language'),
              child: LauncherButton(
                text: _languageLabel(s),
                bordered: true,
                onTap: _pickLanguage,
              ),
            ),
          ],
        ),
        const SizedBox(height: LauncherSpace.s5),
        LauncherSection(
          title: s.t('settings.sectionAppearance'),
          children: <Widget>[
            LauncherField(
              label: s.t('settings.dark'),
              hint: widget.settings.followSystem
                  ? s.t('settings.darkHint')
                  : null,
              child: LauncherToggle(
                on: widget.settings.isDark,
                onLabel: s.t('settings.dark'),
                offLabel: s.t('settings.light'),
                onChanged: (bool v) =>
                    widget.onChanged(widget.settings.copyWith(isDark: v)),
              ),
            ),
            LauncherField(
              label: s.t('settings.followSystem'),
              hint: s.t('settings.followSystemHint'),
              child: LauncherToggle(
                on: widget.settings.followSystem,
                onChanged: (bool v) =>
                    widget.onChanged(widget.settings.copyWith(followSystem: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: LauncherSpace.s5),
        LauncherSection(
          title: s.t('settings.sectionGameDir'),
          children: <Widget>[
            Padding(
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
                          s.t('settings.currentDir'),
                          style: LauncherFonts.ui.copyWith(
                            fontSize: 14,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.gameDir,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LauncherFonts.meta.copyWith(
                            color: p.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: LauncherSpace.s3),
                  LauncherButton(
                    text: s.t('common.change'),
                    bordered: true,
                    onTap: _chooseDir,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_notice != null) ...<Widget>[
          const SizedBox(height: LauncherSpace.s2),
          Text(
            _notice!,
            style: LauncherFonts.meta.copyWith(color: p.secondary, height: 1.6),
          ),
        ],
        const SizedBox(height: LauncherSpace.s5),
        LauncherSection(
          title: s.t('settings.sectionAccount'),
          children: <Widget>[
            if (widget.accountName == null)
              LauncherField(
                label: s.t('settings.microsoftAccount'),
                hint: s.t('settings.loginToPlay'),
                child: LauncherButton(
                  text: s.t('common.login'),
                  bordered: true,
                  onTap: widget.onLogin,
                ),
              )
            else ...<Widget>[
              LauncherField(
                label: s.t('settings.characterName'),
                hint: s.t('settings.microsoftAccount'),
                child: Text(
                  widget.accountName!,
                  style: LauncherFonts.meta.copyWith(color: p.text),
                ),
              ),
              LauncherField(
                label: s.t('settings.loginStatus'),
                hint: s.t('settings.autoRenew'),
                child: LauncherButton(
                  text: s.t('common.logout'),
                  bordered: true,
                  onTap: widget.onLogout,
                ),
              ),
            ],
            if (widget.accountName != null && widget.onDeleteAccount != null)
              LauncherField(
                label: s.t('settings.deleteAccount'),
                hint: s.t('settings.deleteAccountHint'),
                child: LauncherButton(
                  text: s.t('common.delete'),
                  bordered: true,
                  onTap: _confirmDeleteAccount,
                ),
              ),
          ],
        ),
        const SizedBox(height: LauncherSpace.s5),
        LauncherSection(
          title: s.t('settings.sectionAbout'),
          children: <Widget>[
            LauncherField(
              label: s.t('settings.version'),
              hint: s.t('settings.licenseName'),
              child: const _VersionText(),
            ),
            LauncherField(
              label: s.t('privacy.title'),
              hint: s.t('privacy.hint'),
              child: LauncherButton(
                text: s.t('common.view'),
                bordered: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const PrivacyPage(),
                  ),
                ),
              ),
            ),
            LauncherField(
              label: s.t('settings.licenses'),
              hint: s.t('settings.licensesHint'),
              child: LauncherButton(
                text: s.t('common.view'),
                bordered: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => const LicensesPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: LauncherSpace.s5),
        Text(
          s.t('settings.disclaimer'),
          style: LauncherFonts.meta.copyWith(color: p.secondary, height: 1.6),
        ),
      ],
    );
  }
}

/// Reads the version from the installed package metadata instead of duplicating it here.
class _VersionText extends StatelessWidget {
  const _VersionText();

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (BuildContext context, AsyncSnapshot<PackageInfo> snap) {
        final String text = snap.hasData
            ? snap.data!.version
            : (snap.hasError ? context.t('settings.versionReadError') : '…');
        return Text(
          text,
          style: LauncherFonts.meta.copyWith(color: p.secondary),
        );
      },
    );
  }
}
