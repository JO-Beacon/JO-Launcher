// Microsoft device-code sign-in dialog.
//
// The user sees the short code, opens the authorization page and waits. On
// success the dialog closes and returns the account. Cancel stops polling.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../platform/open_url.dart';
import '../theme/tokens.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import 'account.dart';
import 'auth_service.dart';

/// Opens the sign-in dialog. Returns the account on success, null on cancel.
Future<MinecraftAccount?> showMicrosoftLogin(
  BuildContext context,
  Authenticator auth,
) {
  return showDialog<MinecraftAccount>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext _) => MicrosoftLoginDialog(auth: auth),
  );
}

class MicrosoftLoginDialog extends StatefulWidget {
  const MicrosoftLoginDialog({super.key, required this.auth});

  final Authenticator auth;

  @override
  State<MicrosoftLoginDialog> createState() => _MicrosoftLoginDialogState();
}

class _MicrosoftLoginDialogState extends State<MicrosoftLoginDialog> {
  DeviceCodeInfo? _code;
  String? _error;
  String? _notice;
  bool _cancelled = false;

  /// Retry sequence number: a stale round must not update the UI.
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _start() async {
    final int attempt = ++_attempt;
    setState(() {
      _code = null;
      _error = null;
      _notice = null;
    });
    try {
      final MinecraftAccount account = await widget.auth.loginWithDeviceCode(
        onCode: (DeviceCodeInfo info) {
          if (!mounted || attempt != _attempt) return;
          setState(() => _code = info);
        },
        isCancelled: () => _cancelled || !mounted || attempt != _attempt,
      );
      if (!mounted || attempt != _attempt) return;
      Navigator.of(context).pop(account);
    } on AuthCancelled {
      // User cancelled (or the window closed); say nothing.
    } on AuthException catch (error) {
      if (!mounted || attempt != _attempt) return;
      setState(() => _error = context.t(error.key, error.args));
    } catch (error) {
      if (!mounted || attempt != _attempt) return;
      setState(
        () => _error = context.t('auth.errorGeneric', <String, Object>{
          'error': '$error',
        }),
      );
    }
  }

  void _close() {
    _cancelled = true;
    Navigator.of(context).pop();
  }

  Future<void> _copy() async {
    final DeviceCodeInfo? code = _code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code.userCode));
    if (!mounted) return;
    setState(() => _notice = context.t('auth.copied'));
  }

  Future<void> _open() async {
    final DeviceCodeInfo? code = _code;
    if (code == null) return;
    final bool ok = await openUrl(code.verificationUri);
    if (!mounted) return;
    if (!ok) setState(() => _notice = context.t('auth.openBrowserFailed'));
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
        width: 460,
        padding: const EdgeInsets.all(LauncherSpace.s5),
        decoration: BoxDecoration(
          color: p.surface,
          border: LauncherShape.border(p.border),
          borderRadius: LauncherShape.br,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    s.t('auth.title'),
                    style: LauncherFonts.ui.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                ),
                LauncherIconAction(
                  icon: LauncherIcons.close,
                  tip: s.t('common.close'),
                  onTap: _close,
                ),
              ],
            ),
            const SizedBox(height: LauncherSpace.s3),
            if (_error != null)
              _errorView(p, s)
            else if (_code == null)
              _waitingView(p, s)
            else
              _codeView(p, s, _code!),
          ],
        ),
      ),
    );
  }

  Widget _waitingView(LauncherPalette p, AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.t('auth.requesting'),
          style: LauncherFonts.meta.copyWith(color: p.secondary),
        ),
        const SizedBox(height: LauncherSpace.s4),
        Align(
          alignment: Alignment.centerRight,
          child: LauncherButton(
            text: s.t('common.cancel'),
            bordered: true,
            onTap: _close,
          ),
        ),
      ],
    );
  }

  Widget _errorView(LauncherPalette p, AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _error!,
          style: LauncherFonts.meta.copyWith(color: p.text, height: 1.6),
        ),
        const SizedBox(height: LauncherSpace.s4),
        Row(
          children: <Widget>[
            LauncherButton(
              text: s.t('common.retry'),
              bordered: true,
              onTap: _start,
            ),
            const Spacer(),
            LauncherButton(
              text: s.t('common.close'),
              bordered: true,
              onTap: _close,
            ),
          ],
        ),
      ],
    );
  }

  Widget _codeView(LauncherPalette p, AppLocalizations s, DeviceCodeInfo code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.t('auth.instructions'),
          style: LauncherFonts.meta.copyWith(color: p.secondary, height: 1.6),
        ),
        const SizedBox(height: LauncherSpace.s3),
        Container(
          padding: const EdgeInsets.symmetric(vertical: LauncherSpace.s4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.bg,
            border: LauncherShape.border(p.border),
            borderRadius: LauncherShape.br,
          ),
          child: SelectableText(
            code.userCode,
            style: LauncherFonts.ui.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: p.text,
              fontFeatures: LauncherFonts.tabular,
            ),
          ),
        ),
        const SizedBox(height: LauncherSpace.s3),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                code.verificationUri,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LauncherFonts.meta.copyWith(color: p.secondary),
              ),
            ),
            const SizedBox(width: LauncherSpace.s2),
            LauncherButton(
              text: s.t('auth.copyCode'),
              bordered: true,
              onTap: _copy,
            ),
            const SizedBox(width: LauncherSpace.s2),
            LauncherButton(
              text: s.t('auth.openLink'),
              bordered: true,
              onTap: _open,
            ),
          ],
        ),
        const SizedBox(height: LauncherSpace.s3),
        Text(
          _notice ?? s.t('auth.waiting'),
          style: LauncherFonts.meta.copyWith(color: p.secondary),
        ),
        const SizedBox(height: LauncherSpace.s4),
        Align(
          alignment: Alignment.centerRight,
          child: LauncherButton(
            text: s.t('common.cancel'),
            bordered: true,
            onTap: _close,
          ),
        ),
      ],
    );
  }
}
