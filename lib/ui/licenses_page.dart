// License list.
//
// Flutter's showLicensePage is not used: it repeats framework licenses for
// hundreds of library files, so the page is mostly Material. LicenseRegistry
// is append-only and cannot be filtered.
//
// This page walks the registry and **deduplicates by package name**: one entry
// per package.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'common.dart';
import 'icons.dart';

class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  /// Package name -> license text. Keep the longest text for duplicate names
  /// (repeated registrations can truncate the body).
  Map<String, String>? _byName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, String> out = <String, String>{};
    await for (final LicenseEntry e in LicenseRegistry.licenses) {
      final String name = e.packages.isEmpty ? '' : e.packages.first;
      final String text = e.paragraphs
          .map((LicenseParagraph p) => p.text)
          .join('\n\n')
          .trim();
      final String? old = out[name];
      if (old == null || text.length > old.length) out[name] = text;
    }
    if (!mounted) return;
    setState(() => _byName = out);
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    final AppLocalizations s = context.l10n;
    final Map<String, String>? m = _byName;
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
                  s.t('licenses.title'),
                  style: LauncherFonts.ui.copyWith(fontSize: 15, color: p.text),
                ),
                const Spacer(),
                if (m != null)
                  Text(
                    s.t('licenses.count', <String, Object>{'count': m.length}),
                    style: LauncherFonts.meta.copyWith(color: p.secondary),
                  ),
              ],
            ),
          ),
          if (m == null)
            Padding(
              padding: const EdgeInsets.all(LauncherSpace.s4),
              child: Text(
                s.t('licenses.loading'),
                style: LauncherFonts.meta.copyWith(color: p.secondary),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: LauncherSpace.s4,
                  vertical: LauncherSpace.s2,
                ),
                children: <Widget>[
                  for (final MapEntry<String, String> e in m.entries)
                    LauncherTap(
                      onTap: () => _showText(
                        e.key.isEmpty ? s.t('licenses.unsigned') : e.key,
                        e.value,
                      ),
                      builder: (BuildContext c, bool hover, bool down) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: LauncherSpace.s3,
                              horizontal: LauncherSpace.s2,
                            ),
                            decoration: BoxDecoration(
                              color: hover
                                  ? p.surface
                                  : p.bg.withValues(alpha: 0),
                              border: Border(
                                bottom: BorderSide(color: p.border),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    e.key.isEmpty
                                        ? s.t('licenses.unsigned')
                                        : e.key,
                                    style: LauncherFonts.ui.copyWith(
                                      fontSize: 13,
                                      color: p.text,
                                    ),
                                  ),
                                ),
                                Text(
                                  s.t('licenses.viewText'),
                                  style: LauncherFonts.meta.copyWith(
                                    color: p.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showText(String name, String text) {
    showDialog<void>(
      context: context,
      builder: (BuildContext c) {
        final LauncherPalette p = LauncherTheme.of(c);
        return Dialog(
          backgroundColor: p.bg,
          shape: const RoundedRectangleBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(LauncherSpace.s4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          name,
                          style: LauncherFonts.ui.copyWith(
                            fontSize: 14,
                            color: p.text,
                          ),
                        ),
                      ),
                      LauncherButton(
                        text: context.t('common.close'),
                        onTap: () => Navigator.of(c).maybePop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      LauncherSpace.s4,
                      0,
                      LauncherSpace.s4,
                      LauncherSpace.s4,
                    ),
                    child: SelectableText(
                      text.isEmpty ? context.t('licenses.noText') : text,
                      style: LauncherFonts.meta.copyWith(
                        color: p.secondary,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
