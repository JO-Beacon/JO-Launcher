// Shared widget-test shell: localization delegate + theme above the Navigator
// (so dialogs can read them too).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jolauncher/l10n/app_localizations.dart';
import 'package:jolauncher/theme/tokens.dart';

Widget testApp(
  Widget home, {
  GlobalKey<NavigatorState>? navigatorKey,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (BuildContext context, Widget? child) {
      return LauncherTheme(
        settings: const LauncherSettings(),
        palette: LauncherPalette.dark,
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: home,
  );
}
