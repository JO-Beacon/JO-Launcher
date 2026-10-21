import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/account.dart';
import 'auth/account_store.dart';
import 'auth/auth_service.dart';
import 'auth/login_dialog.dart';
import 'l10n/app_localizations.dart';
import 'mc/game_dir.dart';
import 'privacy/privacy_dialog.dart';
import 'privacy/privacy_store.dart';
import 'shell/app_shell.dart';
import 'shell/nav.dart';
import 'theme/settings_store.dart';
import 'theme/tokens.dart';

/// Root widget: theme animation, native caption colors, rail width and page.
///
/// **No Material look**: MaterialApp only provides routing and localization;
/// colors, fonts and spacing come from `LauncherTheme` (`theme/tokens.dart`).
class LauncherApp extends StatefulWidget {
  const LauncherApp({
    super.key,
    required this.store,
    required this.initial,
    this.initialRailWidth,
    this.initialGameDir,
    this.initialCurrentVersion,
    this.initialAccount,
    required this.accountStore,
    required this.privacyStore,
  });

  final SettingsStore store;
  final LauncherSettings initial;

  /// Last rail width; null means the default value.
  final double? initialRailWidth;

  /// Last game directory; null means the system default `.minecraft`.
  final String? initialGameDir;

  /// Last selected version name; null when nothing was selected.
  final String? initialCurrentVersion;

  /// Last signed-in account; null when signed out.
  final MinecraftAccount? initialAccount;
  final AccountStore accountStore;
  final PrivacyStore privacyStore;

  @override
  State<LauncherApp> createState() => _LauncherAppState();
}

class _LauncherAppState extends State<LauncherApp>
    with SingleTickerProviderStateMixin {
  late LauncherSettings _settings = widget.initial;
  late LauncherTab _tab = LauncherTab.launch;
  late double _railW = widget.initialRailWidth ?? LauncherShell.defaultRail;
  late String _gameDir = widget.initialGameDir ?? defaultGameDir();
  late String? _currentVersionName = widget.initialCurrentVersion;
  late MinecraftAccount? _account = widget.initialAccount;
  final AuthService _auth = AuthService();

  /// Light/dark transition: 0 = light (paper), 1 = dark (machine).
  /// The palette is interpolated at the root so every `LauncherTheme.of`
  /// consumer follows the transition.
  late final AnimationController _themeAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: _effectiveDark ? 1 : 0,
  );

  bool get _effectiveDark {
    if (!_settings.followSystem) return _settings.isDark;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void _syncTheme({bool animate = true}) {
    final double target = _effectiveDark ? 1 : 0;
    if (!animate) {
      _themeAnim.value = target;
      return;
    }
    if (target == _themeAnim.value) return;
    if (target > _themeAnim.value) {
      _themeAnim.forward();
    } else {
      _themeAnim.reverse();
    }
  }

  /// Native window caption colors (Windows only; other platforms throw and
  /// the error is ignored).
  static const MethodChannel _windowChannel = MethodChannel(
    'jolauncher/window',
  );

  @override
  void initState() {
    super.initState();
    _syncTheme(animate: false);
    _pushCaption();
    _themeAnim.addListener(_pushCaption);
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
          if (_settings.followSystem) _syncTheme();
        };

    final MinecraftAccount? account = _account;
    if (account != null && !widget.privacyStore.accepted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureInitialPrivacy(),
      );
    } else if (account != null && account.isExpired) {
      unawaited(_refreshAccount(account));
    }
  }

  Future<void> _ensureInitialPrivacy() async {
    if (!mounted) return;
    final bool accepted = await ensurePrivacyConsent(
      context,
      widget.privacyStore,
    );
    if (!mounted) return;
    if (!accepted) {
      await widget.accountStore.delete();
      if (mounted) setState(() => _account = null);
      return;
    }
    final MinecraftAccount? account = _account;
    if (account != null && account.isExpired) {
      unawaited(_refreshAccount(account));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        null;
    _themeAnim.removeListener(_pushCaption);
    _themeAnim.dispose();
    super.dispose();
  }

  void _pushCaption() {
    unawaited(
      _sendCaption(
        LauncherPalette.lerp(
          LauncherPalette.light,
          LauncherPalette.dark,
          _themeAnim.value,
        ),
      ),
    );
  }

  Future<void> _sendCaption(LauncherPalette palette) async {
    try {
      await _windowChannel.invokeMethod<void>('setCaption', <String, Object>{
        'caption': palette.bg.toARGB32(),
        'text': palette.text.toARGB32(),
        'border': palette.border.toARGB32(),
        'dark': palette.isDark ? 1 : 0,
      });
    } catch (_) {
      // Non-Windows platforms do not have this channel.
    }
  }

  void _updateSettings(LauncherSettings next) {
    setState(() => _settings = next);
    _syncTheme();
    widget.store.save(next);
  }

  void _updateGameDir(String dir) {
    setState(() {
      _gameDir = dir;
      // Changing the directory invalidates the version name from the old one.
      _currentVersionName = null;
    });
    widget.store.saveGameDir(dir);
    widget.store.saveCurrentVersion(null);
  }

  void _updateCurrentVersion(String name) {
    setState(() => _currentVersionName = name);
    widget.store.saveCurrentVersion(name);
  }

  /// Silent refresh on startup. On failure keep the old account: a network
  /// outage should not sign the user out.
  Future<void> _refreshAccount(MinecraftAccount old) async {
    try {
      final MinecraftAccount fresh = await _auth.refresh(old);
      if (!mounted) return;
      _signIn(fresh);
    } catch (_) {
      // Refresh failure is reported later when launching the game.
    }
  }

  void _signIn(MinecraftAccount account) {
    setState(() => _account = account);
    unawaited(widget.accountStore.save(account));
  }

  void _signOut() {
    setState(() => _account = null);
    unawaited(widget.accountStore.save(null));
  }

  Future<void> _deleteAccount() async {
    await widget.accountStore.delete();
    if (!mounted) return;
    setState(() => _account = null);
  }

  Future<void> _login(BuildContext context) async {
    if (!await ensurePrivacyConsent(context, widget.privacyStore)) return;
    if (!context.mounted) return;
    final MinecraftAccount? account = await showMicrosoftLogin(context, _auth);
    if (account == null || !mounted) return;
    _signIn(account);
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette palette = LauncherPalette.lerp(
      LauncherPalette.light,
      LauncherPalette.dark,
      _themeAnim.value,
    );
    return MaterialApp(
      title: 'JO-Launcher',
      debugShowCheckedModeBanner: false,
      // Flutter's built-in widgets use the Global* delegates; our own strings
      // use AppLocalizations.
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: AppLocalizations.localeFor(_settings.locale),
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: LauncherFonts.sans,
        scaffoldBackgroundColor: palette.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: _effectiveDark ? Brightness.dark : Brightness.light,
        ),
      ),
      builder: (BuildContext context, Widget? child) {
        // LauncherTheme must sit above the Navigator so dialogs can read it.
        return AnimatedBuilder(
          animation: _themeAnim,
          child: child ?? const SizedBox.shrink(),
          builder: (BuildContext context, Widget? inner) {
            return LauncherTheme(
              settings: _settings,
              palette: LauncherPalette.lerp(
                LauncherPalette.light,
                LauncherPalette.dark,
                _themeAnim.value,
              ),
              child: inner ?? const SizedBox.shrink(),
            );
          },
        );
      },
      home: ColoredBox(
        color: palette.bg,
        child: LauncherShell(
          tab: _tab,
          onTabChanged: (LauncherTab t) => setState(() => _tab = t),
          railWidth: _railW,
          onRailResize: (double w) => setState(() => _railW = w),
          onRailResizeEnd: () => widget.store.saveRailW(_railW),
          settings: _settings,
          onSettingsChanged: _updateSettings,
          gameDir: _gameDir,
          onGameDirChanged: _updateGameDir,
          currentVersionName: _currentVersionName,
          onCurrentVersionChanged: _updateCurrentVersion,
          accountName: _account?.name,
          account: _account,
          onLogin: _login,
          onLogout: _signOut,
          onDeleteAccount: _deleteAccount,
        ),
      ),
    );
  }
}
