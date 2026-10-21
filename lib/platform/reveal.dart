// Opens a directory in the system file manager.
//
// One command per platform. Windows explorer often returns 1 even on success,
// so Windows does not check the exit code.

import 'dart:io';

/// Returns true on success. Returns false when it cannot open; the UI decides
/// what to say.
Future<bool> revealInFolder(String path) async {
  try {
    final String os = Platform.operatingSystem;
    if (os == 'windows') {
      await Process.run('explorer', <String>[path]);
      return true;
    }
    final ProcessResult result = os == 'macos'
        ? await Process.run('open', <String>[path])
        : await Process.run('xdg-open', <String>[path]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
