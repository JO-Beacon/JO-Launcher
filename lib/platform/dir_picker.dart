// System folder picker.
//
// Uses `file_selector` (Flutter's official plugin) instead of calling Win32 /
// GTK directly: Windows, Linux and macOS each need a native dialog, which
// would mean three platform implementations.
//
// This is the only place that touches the plugin; the UI only depends on
// `Future<String?> Function(String)`, so tests do not need platform channels.

import 'package:file_selector/file_selector.dart';

/// Lets the user choose a directory. Returns null on cancel.
///
/// A failure to open the dialog is thrown to the caller: it knows whether to
/// show a reason. Swallowing it here would make the button look dead.
Future<String?> pickDirectory(String initialDirectory) {
  return getDirectoryPath(initialDirectory: initialDirectory);
}
