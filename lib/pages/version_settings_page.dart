import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/version_labels.dart';
import '../mc/scan.dart';
import '../mc/version.dart';
import '../mc/version_config.dart';
import '../platform/reveal.dart';
import '../shell/page_frame.dart';
import '../theme/tokens.dart';
import '../ui/common.dart';
import '../ui/icons.dart';

/// Version settings: Java, memory and JVM arguments for the current version.
///
/// Settings follow the version directory (`<version dir>/jolauncher.json`), not
/// a single run. When no version is selected, only a shortcut to the Launch
/// page is shown.
class VersionSettingsPage extends StatefulWidget {
  const VersionSettingsPage({
    super.key,
    required this.gameDir,
    required this.currentVersionName,
    required this.onOpenLaunch,
    this.scan = scanVersions,
    this.readConfig = readVersionConfig,
    this.saveConfig = saveVersionConfig,
    this.openFolder = revealInFolder,
  });

  final String gameDir;
  final String? currentVersionName;
  final VoidCallback onOpenLaunch;

  final Future<VersionScanResult> Function(String gameDir) scan;
  final Future<VersionConfig> Function(String versionDir) readConfig;
  final Future<void> Function(String versionDir, VersionConfig config)
  saveConfig;
  final Future<bool> Function(String path) openFolder;

  @override
  State<VersionSettingsPage> createState() => _VersionSettingsPageState();
}

class _VersionSettingsPageState extends State<VersionSettingsPage> {
  bool _loading = true;
  String? _error;
  McVersion? _version;

  /// Load sequence: when switching versions quickly, only the latest result is accepted.
  int _token = 0;

  final TextEditingController _java = TextEditingController();
  final TextEditingController _minMemory = TextEditingController();
  final TextEditingController _maxMemory = TextEditingController();
  final TextEditingController _jvmArgs = TextEditingController();

  bool _manualJava = false;
  bool _saving = false;
  bool _saved = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VersionSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameDir != oldWidget.gameDir ||
        widget.currentVersionName != oldWidget.currentVersionName) {
      _load();
    }
  }

  @override
  void dispose() {
    _java.dispose();
    _minMemory.dispose();
    _maxMemory.dispose();
    _jvmArgs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final int token = ++_token;
    setState(() {
      _loading = true;
      _error = null;
      _saved = false;
      _formError = null;
    });

    try {
      final VersionScanResult result = await widget.scan(widget.gameDir);
      final String? name = widget.currentVersionName;
      McVersion? found;
      if (name != null) {
        for (final McVersion version in result.versions) {
          if (version.name == name) {
            found = version;
            break;
          }
        }
      }
      if (!mounted || token != _token) return;
      if (found == null) {
        setState(() {
          _loading = false;
          _version = null;
        });
        return;
      }

      final VersionConfig config = await widget.readConfig(found.dir);
      if (!mounted || token != _token) return;
      setState(() {
        _version = found;
        _loading = false;
        _manualJava = config.javaPath != null;
        _java.text = config.javaPath ?? '';
        _minMemory.text = config.minMemoryMb?.toString() ?? '';
        _maxMemory.text = config.maxMemoryMb?.toString() ?? '';
        _jvmArgs.text = config.jvmArgs;
      });
    } catch (error) {
      if (!mounted || token != _token) return;
      setState(() {
        _loading = false;
        _error = context.l10n.t('version.errorRead', <String, Object>{
          'error': '$error',
        });
      });
    }
  }

  void _markEdited() {
    if (!_saved && _formError == null) return;
    setState(() {
      _saved = false;
      _formError = null;
    });
  }

  Future<void> _openFolder() async {
    final McVersion? version = _version;
    if (version == null) return;
    final bool ok = await widget.openFolder(version.dir);
    if (!mounted || ok) return;
    setState(() => _formError = context.l10n.t('version.errorOpenFolder'));
  }

  Future<void> _save() async {
    final McVersion? version = _version;
    if (version == null || _saving) return;

    final String minText = _minMemory.text.trim();
    final String maxText = _maxMemory.text.trim();
    final int? min = minText.isEmpty ? null : int.tryParse(minText);
    final int? max = maxText.isEmpty ? null : int.tryParse(maxText);
    final bool badNumber =
        (minText.isNotEmpty && min == null) ||
        (maxText.isNotEmpty && max == null);
    if (badNumber) {
      setState(() => _formError = context.l10n.t('version.errorMemoryNumber'));
      return;
    }
    if ((min != null && min <= 0) || (max != null && max <= 0)) {
      setState(
        () => _formError = context.l10n.t('version.errorMemoryPositive'),
      );
      return;
    }
    if (min != null && max != null && min > max) {
      setState(() => _formError = context.l10n.t('version.errorMemoryOrder'));
      return;
    }

    final String java = _java.text.trim();
    final VersionConfig config = VersionConfig(
      javaPath: _manualJava && java.isNotEmpty ? java : null,
      minMemoryMb: min,
      maxMemoryMb: max,
      jvmArgs: _jvmArgs.text.trim(),
    );

    setState(() {
      _saving = true;
      _formError = null;
      _saved = false;
    });
    try {
      await widget.saveConfig(version.dir, config);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = context.l10n.t('version.errorWrite', <String, Object>{
          'error': '$error',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    final AppLocalizations s = context.l10n;
    return LauncherPageFrame(
      title: s.t('version.title'),
      subtitle: _version?.name ?? s.t('version.current'),
      trailing: LauncherIconAction(
        icon: LauncherIcons.refresh,
        tip: s.t('version.reload'),
        onTap: _load,
      ),
      children: _content(p, s),
    );
  }

  List<Widget> _content(LauncherPalette p, AppLocalizations s) {
    if (_loading) {
      return <Widget>[LauncherPending(text: s.t('common.loading'))];
    }
    if (_error != null) {
      return <Widget>[LauncherPending(text: _error!)];
    }
    final McVersion? version = _version;
    if (version == null) {
      return <Widget>[
        LauncherPending(text: s.t('version.pickFirst')),
        const SizedBox(height: LauncherSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: LauncherButton(
            text: s.t('version.goLaunch'),
            bordered: true,
            onTap: widget.onOpenLaunch,
          ),
        ),
      ];
    }

    return <Widget>[
      LauncherSection(
        title: s.t('version.versionSection'),
        children: <Widget>[
          LauncherField(
            label: s.t('version.name'),
            child: _value(p, version.name),
          ),
          LauncherField(
            label: s.t('version.gameVersion'),
            child: _value(p, version.gameVersion),
          ),
          LauncherField(
            label: s.t('version.loader'),
            child: _value(p, version.loaderText(s)),
          ),
          _pathRow(p, s, version),
        ],
      ),
      const SizedBox(height: LauncherSpace.s5),
      LauncherSection(
        title: s.t('version.javaSection'),
        children: <Widget>[
          LauncherField(
            label: s.t('version.javaSource'),
            hint: s.t('version.javaAutoHint'),
            child: LauncherSegment<bool>(
              options: <({String label, bool value})>[
                (label: s.t('common.auto'), value: false),
                (label: s.t('common.manual'), value: true),
              ],
              value: _manualJava,
              onChanged: (bool manual) {
                setState(() => _manualJava = manual);
                _markEdited();
              },
            ),
          ),
          if (_manualJava)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LauncherSpace.s4,
                0,
                LauncherSpace.s4,
                LauncherSpace.s3,
              ),
              child: _input(p, _java, hint: s.t('version.javaPathHint')),
            ),
        ],
      ),
      const SizedBox(height: LauncherSpace.s5),
      LauncherSection(
        title: s.t('version.memorySection'),
        children: <Widget>[
          LauncherField(
            label: s.t('version.memoryMin'),
            hint: s.t('version.memoryHint'),
            child: _memoryField(p, s, _minMemory),
          ),
          LauncherField(
            label: s.t('version.memoryMax'),
            hint: s.t('version.memoryHint'),
            child: _memoryField(p, s, _maxMemory),
          ),
        ],
      ),
      const SizedBox(height: LauncherSpace.s5),
      LauncherSection(
        title: s.t('version.jvmSection'),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(LauncherSpace.s4),
            child: _input(
              p,
              _jvmArgs,
              hint: s.t('version.jvmHint'),
              multiline: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: LauncherSpace.s5),
      Row(
        children: <Widget>[
          LauncherButton(
            text: _saving ? s.t('common.saving') : s.t('common.save'),
            color: p.accent,
            bordered: true,
            enabled: !_saving,
            onTap: _save,
          ),
          const SizedBox(width: LauncherSpace.s3),
          if (_saved)
            Text(
              s.t('common.saved'),
              style: LauncherFonts.meta.copyWith(color: p.secondary),
            ),
        ],
      ),
      if (_formError != null) ...<Widget>[
        const SizedBox(height: LauncherSpace.s2),
        Text(
          _formError!,
          style: LauncherFonts.meta.copyWith(color: p.secondary, height: 1.6),
        ),
      ],
    ];
  }

  Widget _value(LauncherPalette p, String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: LauncherFonts.meta.copyWith(color: p.text),
    );
  }

  Widget _pathRow(LauncherPalette p, AppLocalizations s, McVersion version) {
    return Padding(
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
                  s.t('version.directory'),
                  style: LauncherFonts.ui.copyWith(fontSize: 14, color: p.text),
                ),
                const SizedBox(height: 2),
                Text(
                  version.dir,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LauncherFonts.meta.copyWith(color: p.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: LauncherSpace.s3),
          LauncherButton(
            text: s.t('common.openFolder'),
            bordered: true,
            onTap: _openFolder,
          ),
        ],
      ),
    );
  }

  Widget _memoryField(
    LauncherPalette p,
    AppLocalizations s,
    TextEditingController controller,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 96,
          child: _input(p, controller, hint: s.t('common.auto')),
        ),
        const SizedBox(width: LauncherSpace.s1),
        Text('MB', style: LauncherFonts.meta.copyWith(color: p.secondary)),
      ],
    );
  }

  Widget _input(
    LauncherPalette p,
    TextEditingController controller, {
    String? hint,
    bool multiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LauncherSpace.s3,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        border: LauncherShape.border(p.border),
        borderRadius: LauncherShape.br,
      ),
      child: LauncherTextField(
        controller: controller,
        style: LauncherFonts.ui.copyWith(fontSize: 13, color: p.text),
        hint: hint,
        hintStyle: LauncherFonts.ui.copyWith(fontSize: 13, color: p.secondary),
        maxLines: multiline ? null : 1,
        minLines: multiline ? 3 : null,
        onChanged: (String _) => _markEdited(),
      ),
    );
  }
}
