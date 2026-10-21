// Opens a URL in the system default browser.
//
// Like reveal.dart, uses system commands instead of url_launcher.

import 'dart:io';

Future<bool> openUrl(String url) async {
  try {
    final ProcessResult result;
    if (Platform.isWindows) {
      // The first argument to start is the window title; an empty placeholder
      // is required.
      result = await Process.run('cmd', <String>['/c', 'start', '', url]);
    } else if (Platform.isMacOS) {
      result = await Process.run('open', <String>[url]);
    } else {
      result = await Process.run('xdg-open', <String>[url]);
    }
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
