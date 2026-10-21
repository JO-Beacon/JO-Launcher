import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/account.dart';
import '../pages/app_settings_page.dart';
import '../pages/launch_page.dart';
import '../pages/version_settings_page.dart';
import '../theme/tokens.dart';
import '../ui/splitter.dart';
import 'left_rail.dart';
import 'nav.dart';

/// Left rail + splitter + right pane.
///
/// Layout only: width, selected page and page content are passed in.
class LauncherShell extends StatelessWidget {
  const LauncherShell({
    super.key,
    required this.tab,
    required this.onTabChanged,
    required this.railWidth,
    required this.onRailResize,
    required this.onRailResizeEnd,
    required this.settings,
    required this.onSettingsChanged,
    required this.gameDir,
    required this.onGameDirChanged,
    required this.currentVersionName,
    required this.onCurrentVersionChanged,
    required this.accountName,
    required this.onLogin,
    required this.onLogout,
    this.onDeleteAccount,
    this.account,
    this.playerName,
  });

  final LauncherTab tab;
  final ValueChanged<LauncherTab> onTabChanged;

  final double railWidth;
  final ValueChanged<double> onRailResize;
  final VoidCallback onRailResizeEnd;

  final LauncherSettings settings;
  final ValueChanged<LauncherSettings> onSettingsChanged;

  /// Game directory to scan (the `.minecraft` level).
  final String gameDir;
  final ValueChanged<String> onGameDirChanged;

  /// Current version name; null when not selected.
  final String? currentVersionName;
  final ValueChanged<String> onCurrentVersionChanged;

  /// Signed-in player name; null when signed out.
  final String? accountName;

  /// Full account (tokens / UUID are needed for launching).
  final MinecraftAccount? account;

  /// Opens the sign-in dialog and hands the account back to the caller.
  final Future<void> Function(BuildContext context) onLogin;
  final VoidCallback onLogout;

  /// Deletes the account and local account data; null hides the entry.
  final Future<void> Function()? onDeleteAccount;

  final String? playerName;

  /// Allowed rail drag range. The right pane needs at least this width so it
  /// never gets squeezed to nothing when the window shrinks.
  static const double minRail = 200;
  static const double defaultRail = 232;
  static const double _minRight = 420;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double maxRail = (c.maxWidth - _minRight)
            .clamp(minRail, 360)
            .toDouble();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: railWidth.clamp(minRail, maxRail).toDouble(),
              child: LauncherRail(
                tab: tab,
                onTabChanged: onTabChanged,
                playerName: accountName,
                onLogin: () => unawaited(onLogin(context)),
              ),
            ),
            LauncherSplitter(
              palette: p,
              width: railWidth,
              minWidth: minRail,
              maxWidth: maxRail,
              defaultWidth: defaultRail,
              growsRight: true,
              onResize: onRailResize,
              onResizeEnd: onRailResizeEnd,
            ),
            Expanded(child: _page(context)),
          ],
        );
      },
    );
  }

  Widget _page(BuildContext context) {
    return switch (tab) {
      LauncherTab.launch => LaunchPage(
        gameDir: gameDir,
        currentVersionName: currentVersionName,
        onCurrentVersionChanged: onCurrentVersionChanged,
        account: account,
      ),
      LauncherTab.version => VersionSettingsPage(
        gameDir: gameDir,
        currentVersionName: currentVersionName,
        onOpenLaunch: () => onTabChanged(LauncherTab.launch),
      ),
      LauncherTab.settings => SettingsPage(
        settings: settings,
        onChanged: onSettingsChanged,
        gameDir: gameDir,
        onGameDirChanged: onGameDirChanged,
        accountName: accountName,
        onLogin: () => unawaited(onLogin(context)),
        onLogout: onLogout,
        onDeleteAccount: onDeleteAccount,
      ),
    };
  }
}
