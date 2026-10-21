// Lightweight localization: a `key -> text` table + a `LocalizationsDelegate`.
//
// No code generator and no intl message syntax; only `{name}` placeholder
// replacement. Flutter's built-in widgets (Material / Cupertino menus, dates)
// still use the Global* delegates from `flutter_localizations`.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings_de.dart';
import 'strings_en.dart';
import 'strings_es.dart';
import 'strings_fr.dart';
import 'strings_ja.dart';
import 'strings_pt.dart';
import 'strings_sv.dart';

/// Language code -> string table.
const Map<String, Map<String, String>> kStringsByLanguage =
    <String, Map<String, String>>{
      'en': stringsEn,
      'ja': stringsJa,
      'sv': stringsSv,
      'pt': stringsPt,
      'es': stringsEs,
      'fr': stringsFr,
      'de': stringsDe,
    };

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? value = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(value != null, 'AppLocalizations is not mounted');
    return value!;
  }

  /// Gets a string; missing keys fall back to English, then to the key itself
  /// (so omissions are easy to spot).
  String t(String key, [Map<String, Object>? args]) {
    final String text =
        kStringsByLanguage[locale.languageCode]?[key] ?? stringsEn[key] ?? key;
    if (args == null || args.isEmpty) return text;
    String out = text;
    args.forEach((String name, Object value) {
      out = out.replaceAll('{$name}', '$value');
    });
    return out;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('sv'),
    Locale('pt', 'BR'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
  ];

  /// Stored language code -> Locale; `system` returns null (let the system resolve).
  static Locale? localeFor(String code) {
    return switch (code) {
      'en' => const Locale('en'),
      'ja' => const Locale('ja'),
      'sv' => const Locale('sv'),
      'pt' => const Locale('pt', 'BR'),
      'es' => const Locale('es'),
      'fr' => const Locale('fr'),
      'de' => const Locale('de'),
      _ => null,
    };
  }

  /// Language's own name (not translated), used by the language picker.
  static String? languageName(String code) {
    return switch (code) {
      'en' => 'English',
      'ja' => '日本語',
      'sv' => 'Svenska',
      'pt' => 'Português (Brasil)',
      'es' => 'Español',
      'fr' => 'Français',
      'de' => 'Deutsch',
      _ => null,
    };
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kStringsByLanguage.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String t(String key, [Map<String, Object>? args]) => l10n.t(key, args);
}
