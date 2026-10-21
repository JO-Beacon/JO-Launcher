// Path joining and basename helpers.
//
// No `path` package: only these two functions are needed, and `dart:io`'s
// `Platform.pathSeparator` is enough. One less dependency and version constraint.

import 'dart:io';

/// Joins [child] after [base] with a separator.
///
/// If [base] already ends with a separator (`\` or `/`), no extra one is added:
/// hand-typed directories often have a trailing slash, and a root like `C:\`
/// must not be truncated to `C:`.
String joinPath(String base, String child) {
  if (base.isEmpty) return child;
  final String sep = Platform.pathSeparator;
  final bool ends =
      base.endsWith(sep) || base.endsWith('/') || base.endsWith('\\');
  return ends ? '$base$child' : '$base$sep$child';
}

/// Returns the last segment (`C:\Users\x\.minecraft` → `.minecraft`).
///
/// Accepts both separators: Windows paths often contain `/` too.
String baseName(String path) {
  final List<String> parts = path
      .replaceAll('\\', '/')
      .split('/')
      .where((String s) => s.isNotEmpty)
      .toList();
  return parts.isEmpty ? path : parts.last;
}
