import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/account.dart';
import '../l10n/app_localizations.dart';
import '../l10n/version_labels.dart';
import '../launch/launch_error.dart';
import '../launch/launch_service.dart';
import '../mc/scan.dart';
import '../mc/version.dart';
import '../shell/page_frame.dart';
import '../theme/tokens.dart';
import '../ui/common.dart';
import '../ui/icons.dart';

/// Launch page: current version, version switching, launching and running
/// instances.
///
/// An “instance” is one run (one game process); the same version can run in
/// multiple processes at once.
class LaunchPage extends StatefulWidget {
  const LaunchPage({
    super.key,
    required this.gameDir,
    required this.currentVersionName,
    required this.onCurrentVersionChanged,
    this.account,
    this.launchService,
    this.scan = scanVersions,
  });

  /// Game directory to scan (the `.minecraft` level).
  final String gameDir;

  /// Current version name; null when not selected.
  final String? currentVersionName;

  /// Selects another version.
  final ValueChanged<String> onCurrentVersionChanged;

  /// Current account; null means signed out and the launch button is disabled.
  final MinecraftAccount? account;

  /// Launch implementation; tests can inject a fake.
  final LaunchService? launchService;

  /// Scan implementation. Defaults to the real disk scan; tests can inject a
  /// fixed result.
  final Future<VersionScanResult> Function(String gameDir) scan;

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  late Future<VersionScanResult> _scan = widget.scan(widget.gameDir);
  late final LaunchService _launcher = widget.launchService ?? LaunchService();
  bool _switching = false;

  GameProcess? _running;
  bool _starting = false;
  String? _launchError;

  @override
  void didUpdateWidget(LaunchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameDir != oldWidget.gameDir) {
      _switching = false;
      _launchError = null;
      _scan = widget.scan(widget.gameDir);
    }
  }

  Future<void> _launch(McVersion version) async {
    final MinecraftAccount? account = widget.account;
    if (account == null || _starting) return;
    setState(() {
      _starting = true;
      _launchError = null;
    });
    try {
      final GameProcess game = await _launcher.start(
        gameDir: widget.gameDir,
        version: version,
        account: account,
        config: version.config,
      );
      if (!mounted) {
        await game.stop();
        return;
      }
      setState(() {
        _running = game;
        _starting = false;
      });
      unawaited(
        game.exitCode.then((_) {
          if (mounted && identical(_running, game)) {
            setState(() => _running = null);
          }
        }),
      );
    } on LaunchException catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _launchError = context.l10n.t(error.key, error.args);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _launchError = context.l10n.t('launch.error.start', <String, Object>{
          'error': '$error',
        });
      });
    }
  }

  void _showLog(GameProcess game) {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => _GameLogDialog(game: game),
    );
  }

  void _rescan() {
    setState(() => _scan = widget.scan(widget.gameDir));
  }

  void _select(McVersion version) {
    widget.onCurrentVersionChanged(version.name);
    setState(() => _switching = false);
  }

  McVersion? _current(List<McVersion> versions) {
    final String? name = widget.currentVersionName;
    if (name == null) return null;
    for (final McVersion version in versions) {
      if (version.name == name) return version;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    final AppLocalizations s = context.l10n;
    return LauncherPageFrame(
      title: s.t('launch.title'),
      subtitle: s.t('launch.subtitle'),
      trailing: LauncherIconAction(
        icon: LauncherIcons.refresh,
        tip: s.t('launch.rescan'),
        onTap: _rescan,
      ),
      children: <Widget>[
        FutureBuilder<VersionScanResult>(
          future: _scan,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<VersionScanResult> snapshot,
              ) {
                if (snapshot.hasError) {
                  return LauncherPending(
                    text: s.t('launch.scanError', <String, Object>{
                      'error': '${snapshot.error}',
                    }),
                  );
                }
                final VersionScanResult? result = snapshot.data;
                if (result == null) {
                  return LauncherPending(text: s.t('common.loading'));
                }
                if (!result.exists) {
                  return _empty(p, s, s.t('launch.noVersionsDir'));
                }
                if (result.versions.isEmpty) {
                  return _empty(
                    p,
                    s,
                    s.t('launch.noVersions'),
                    broken: result.broken,
                  );
                }

                final McVersion? current = _current(result.versions);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (current == null)
                      _pickCard(p, s, result.versions)
                    else ...<Widget>[
                      _currentCard(p, s, current),
                      if (_switching) ...<Widget>[
                        const SizedBox(height: LauncherSpace.s2),
                        _versionList(p, result.versions, current.name),
                      ],
                    ],
                    const SizedBox(height: LauncherSpace.s5),
                    _runningSection(p, s),
                    if (result.broken.isNotEmpty) ...<Widget>[
                      const SizedBox(height: LauncherSpace.s3),
                      _brokenNote(p, s, result.broken),
                    ],
                  ],
                );
              },
        ),
      ],
    );
  }

  Widget _empty(
    LauncherPalette p,
    AppLocalizations s,
    String text, {
    List<String> broken = const <String>[],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LauncherPending(text: text),
        if (broken.isNotEmpty) _brokenNote(p, s, broken),
      ],
    );
  }

  /// Card shown when no version is selected: expands the version list inline.
  Widget _pickCard(
    LauncherPalette p,
    AppLocalizations s,
    List<McVersion> versions,
  ) {
    return Container(
      padding: const EdgeInsets.all(LauncherSpace.s5),
      decoration: BoxDecoration(
        color: p.surface,
        border: LauncherShape.border(p.border),
        borderRadius: LauncherShape.br,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            s.t('launch.chooseVersion'),
            style: LauncherFonts.ui.copyWith(fontSize: 16, color: p.text),
          ),
          const SizedBox(height: LauncherSpace.s1),
          Text(
            s.t('launch.versionCount', <String, Object>{
              'count': versions.length,
            }),
            style: LauncherFonts.meta.copyWith(color: p.secondary),
          ),
          const SizedBox(height: LauncherSpace.s3),
          _versionList(p, versions, null),
        ],
      ),
    );
  }

  Widget _currentCard(
    LauncherPalette p,
    AppLocalizations s,
    McVersion version,
  ) {
    return Container(
      padding: const EdgeInsets.all(LauncherSpace.s5),
      decoration: BoxDecoration(
        color: p.surface,
        border: LauncherShape.border(p.border),
        borderRadius: LauncherShape.br,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      version.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LauncherFonts.ui.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      version.meta(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LauncherFonts.meta.copyWith(color: p.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LauncherSpace.s3),
              LauncherButton(
                text: _switching
                    ? s.t('launch.collapse')
                    : s.t('launch.switch'),
                bordered: true,
                onTap: () => setState(() => _switching = !_switching),
              ),
            ],
          ),
          const SizedBox(height: LauncherSpace.s4),
          Row(
            children: <Widget>[
              const Spacer(),
              LauncherButton(
                text: _starting
                    ? s.t('launch.starting')
                    : s.t('launch.launchGame'),
                color: p.accent,
                bordered: true,
                enabled:
                    widget.account != null && !_starting && _running == null,
                onTap: () => _launch(version),
              ),
            ],
          ),
          if (_launchError != null) ...<Widget>[
            const SizedBox(height: LauncherSpace.s2),
            Text(
              _launchError!,
              style: LauncherFonts.meta.copyWith(
                color: p.secondary,
                height: 1.6,
              ),
            ),
          ] else if (widget.account == null) ...<Widget>[
            const SizedBox(height: LauncherSpace.s2),
            Text(
              s.t('launch.loginRequired'),
              style: LauncherFonts.meta.copyWith(color: p.secondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _versionList(
    LauncherPalette p,
    List<McVersion> versions,
    String? selected,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: LauncherShape.border(p.border),
        borderRadius: LauncherShape.br,
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < versions.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, thickness: 1, color: p.border),
            _VersionRow(
              version: versions[i],
              selected: versions[i].name == selected,
              onTap: () => _select(versions[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _runningSection(LauncherPalette p, AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.t('launch.running'),
          style: LauncherFonts.meta.copyWith(
            color: p.secondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: LauncherSpace.s2),
        Container(
          padding: const EdgeInsets.all(LauncherSpace.s4),
          decoration: BoxDecoration(
            color: p.surface,
            border: LauncherShape.border(p.border),
            borderRadius: LauncherShape.br,
          ),
          child: _running == null
              ? Text(
                  s.t('launch.noneRunning'),
                  style: LauncherFonts.meta.copyWith(color: p.secondary),
                )
              : Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _running!.version.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LauncherFonts.ui.copyWith(
                          fontSize: 14,
                          color: p.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: LauncherSpace.s3),
                    LauncherButton(
                      text: s.t('launch.log'),
                      bordered: true,
                      onTap: () => _showLog(_running!),
                    ),
                    const SizedBox(width: LauncherSpace.s2),
                    LauncherButton(
                      text: s.t('launch.stop'),
                      bordered: true,
                      onTap: () => _running?.stop(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _brokenNote(
    LauncherPalette p,
    AppLocalizations s,
    List<String> broken,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: LauncherSpace.s3),
      child: Text(
        s.t('launch.broken', <String, Object>{
          'count': broken.length,
          'names': broken.join(s.t('common.listSeparator')),
        }),
        style: LauncherFonts.meta.copyWith(color: p.secondary, height: 1.6),
      ),
    );
  }
}

/// One clickable version row.
class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.version,
    required this.selected,
    required this.onTap,
  });

  final McVersion version;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    return LauncherTap(
      onTap: onTap,
      builder: (BuildContext context, bool hover, bool down) {
        return AnimatedContainer(
          duration: kTapMs,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: LauncherSpace.s4,
            vertical: LauncherSpace.s3,
          ),
          decoration: BoxDecoration(
            color: selected
                ? p.bg
                : (hover ? p.bg.withValues(alpha: 0.5) : null),
            border: Border(
              left: BorderSide(
                color: selected ? p.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                LauncherIcons.archive,
                size: 16,
                color: selected ? p.accent : p.icon,
              ),
              const SizedBox(width: LauncherSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      version.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LauncherFonts.ui.copyWith(
                        fontSize: 14,
                        color: selected ? p.accent : p.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      version.meta(context.l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LauncherFonts.meta.copyWith(color: p.secondary),
                    ),
                  ],
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: LauncherSpace.s2),
                Icon(LauncherIcons.check, size: 14, color: p.accent),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Game log dialog: subscribes to process output and appends it live.
class _GameLogDialog extends StatefulWidget {
  const _GameLogDialog({required this.game});

  final GameProcess game;

  @override
  State<_GameLogDialog> createState() => _GameLogDialogState();
}

class _GameLogDialogState extends State<_GameLogDialog> {
  final List<String> _lines = <String>[];
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _lines.addAll(widget.game.lines);
    _subscription = widget.game.logs.listen((String line) {
      if (mounted) setState(() => _lines.add(line));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LauncherPalette p = LauncherTheme.of(context);
    final AppLocalizations s = context.l10n;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(LauncherSpace.s5),
      child: Container(
        width: 760,
        height: 520,
        padding: const EdgeInsets.all(LauncherSpace.s4),
        decoration: BoxDecoration(
          color: p.surface,
          border: LauncherShape.border(p.border),
          borderRadius: LauncherShape.br,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    s.t('launch.logTitle', <String, Object>{
                      'name': widget.game.version.name,
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LauncherFonts.ui.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                ),
                LauncherIconAction(
                  icon: LauncherIcons.close,
                  tip: s.t('common.close'),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: LauncherSpace.s3),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(LauncherSpace.s3),
                decoration: BoxDecoration(
                  color: p.bg,
                  border: LauncherShape.border(p.border),
                  borderRadius: LauncherShape.br,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _lines.isEmpty ? '…' : _lines.join('\n'),
                    style: LauncherFonts.meta.copyWith(
                      color: p.text,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
