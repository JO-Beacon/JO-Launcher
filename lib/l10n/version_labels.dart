// Display labels for versions (depends on the localization table; kept out of
// the plain data model).

import '../mc/version.dart';
import 'app_localizations.dart';

extension McVersionLabels on McVersion {
  /// Loader part: `NeoForge 21.1.259`; vanilla becomes `Vanilla` / `localized label`.
  String loaderText(AppLocalizations s) {
    final String? version = loaderVersion;
    if (version == null || version.isEmpty) return s.t(loader.labelKey);
    return '${s.t(loader.labelKey)} $version';
  }

  /// Metadata line: `1.21.1 · NeoForge 21.1.259`.
  String meta(AppLocalizations s) => '$gameVersion · ${loaderText(s)}';
}
