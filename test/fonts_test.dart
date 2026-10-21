// Fonts: the UI uses one typeface — Noto Sans SC.
//
// Why this is pinned: the metadata style used to say `fontFamily: 'monospace'`.
// That is a **generic name, not a font name**; Windows has no family by that
// name, so the engine falls back to Roboto (the Material look), while Chinese
// falls back to a system font — two typefaces on one line, looking like
// “Material leaked in”.

import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jolauncher/theme/tokens.dart';

void main() {
  test('every text style uses Noto Sans SC, not a generic family', () {
    final Map<String, TextStyle> styles = <String, TextStyle>{
      'ui': LauncherFonts.ui,
      'meta': LauncherFonts.meta,
    };
    for (final MapEntry<String, TextStyle> e in styles.entries) {
      expect(
        e.value.fontFamily,
        LauncherFonts.sans,
        reason: '${e.key} uses ${e.value.fontFamily}',
      );
      // Generic names (monospace / sans-serif / serif / system-ui) are forbidden.
      expect(
        e.value.fontFamily,
        isNot(
          anyOf(<String>[
            'monospace',
            'sans-serif',
            'serif',
            'system-ui',
            'inherit',
          ]),
        ),
      );
    }
  });

  test('metadata style has tabular figures', () {
    expect(LauncherFonts.meta.fontFeatures, isNotNull);
    expect(
      LauncherFonts.meta.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('no generic fontFamily in code', () {
    // The tokens.dart comment mentions monospace (explaining why it is avoided); skip it.
    final List<String> offenders = <String>[];
    for (final FileSystemEntity e in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      if (e.path.replaceAll(r'\', '/').endsWith('theme/tokens.dart')) continue;
      final String src = e.readAsStringSync();
      for (final String bad in <String>[
        "fontFamily: 'monospace'",
        'fontFamily: "monospace"',
        "fontFamily: 'sans-serif'",
        "fontFamily: 'system-ui'",
        "fontFamily: '.SF",
      ]) {
        if (src.contains(bad)) offenders.add('${e.path} → $bad');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
