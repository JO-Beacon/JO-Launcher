import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/l10n/app_localizations.dart';
import 'package:jolauncher/l10n/language_picker.dart';
import 'package:jolauncher/l10n/strings_en.dart';
import 'package:jolauncher/mc/scan.dart';
import 'package:jolauncher/mc/version.dart';
import 'package:jolauncher/pages/launch_page.dart';

import 'test_app.dart';

/// Localization table structure: keys complete, placeholders substitute, missing
/// languages fall back to English.
void main() {
  test('every language table has exactly the English keys', () {
    final Set<String> expected = stringsEn.keys.toSet();
    for (final MapEntry<String, Map<String, String>> e
        in kStringsByLanguage.entries) {
      expect(
        e.value.keys.toSet(),
        expected,
        reason: '${e.key} keys differ from English',
      );
    }
  });

  test('every string is non-empty', () {
    for (final MapEntry<String, Map<String, String>> e
        in kStringsByLanguage.entries) {
      for (final MapEntry<String, String> item in e.value.entries) {
        expect(
          item.value.trim(),
          isNotEmpty,
          reason: '${e.key} ${item.key} is empty',
        );
      }
    }
  });

  test('placeholder substitution', () {
    const AppLocalizations pt = AppLocalizations(Locale('pt', 'BR'));
    expect(
      pt.t('launch.versionCount', <String, Object>{'count': 3}),
      'Este diretório contém 3 versões.',
    );
    const AppLocalizations en = AppLocalizations(Locale('en'));
    expect(
      en.t('auth.error.xboxCode', <String, Object>{'xerr': 2148916233}),
      'Xbox authorization failed (XErr 2148916233).',
    );
  });

  test(
    'unsupported languages fall back to English; missing keys show the key',
    () {
      const AppLocalizations ko = AppLocalizations(Locale('ko'));
      expect(ko.t('nav.launch'), 'Launch');
      expect(ko.t('no.such.key'), 'no.such.key');
    },
  );

  test('language code to Locale', () {
    expect(AppLocalizations.localeFor('system'), isNull);
    expect(AppLocalizations.localeFor('zh'), isNull);
    expect(AppLocalizations.localeFor('pt'), const Locale('pt', 'BR'));
    expect(AppLocalizations.localeFor('ja'), const Locale('ja'));
    expect(AppLocalizations.localeFor('sv'), const Locale('sv'));
    expect(AppLocalizations.localeFor('xx'), isNull);
  });

  testWidgets('English UI: launch page', (WidgetTester t) async {
    t.view.physicalSize = const Size(1200, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      testApp(
        LaunchPage(
          gameDir: '/nonexistent',
          currentVersionName: null,
          onCurrentVersionChanged: (_) {},
          scan: (String _) async => const VersionScanResult(
            versionsDir: '/nonexistent/versions',
            exists: false,
            versions: <McVersion>[],
            broken: <String>[],
          ),
        ),
        locale: const Locale('en'),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('Launch'), findsOneWidget);
    expect(find.text('Current version and running instances'), findsOneWidget);
    expect(
      find.text('There is no versions folder in this directory.'),
      findsOneWidget,
    );
  });

  testWidgets('language picker returns the language code on tap', (
    WidgetTester t,
  ) async {
    t.view.physicalSize = const Size(1200, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      testApp(const ColoredBox(color: Color(0xFF000000)), navigatorKey: nav),
    );
    final Future<String?> picked = showLanguagePicker(
      nav.currentContext!,
      'system',
    );
    await t.pumpAndSettle();

    expect(find.text('日本語'), findsOneWidget);
    await t.tap(find.text('日本語'));
    await t.pumpAndSettle();

    expect(await picked, 'ja');
  });
}
