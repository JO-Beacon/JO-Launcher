// Our own Remix Icon constants.
//
// **No third-party package is used.**
//   · Font: fonts/remixicon.ttf from the official Remix-Design/remixicon repo
//     → assets/fonts/remixicon.ttf
//   · Codepoints: published in fonts/remixicon.css in the same repo
//     (entries such as `.ri-add-line:before { content: "\ea13"; }`)
//
// Only the icons we use are included; the official set has 3229, so there is
// no reason to pull in the whole package.
//
// License: Remix Icon License v1.0 — https://remixicon.com
// Distributions that use these icons must include the attribution and license text.

import 'package:flutter/widgets.dart';

/// Font family name. **Must match the `family` in pubspec.yaml exactly.**
const String _kFamily = 'RemixIcon';

/// Remix Icon glyphs (the subset we use).
///
/// Usage: `Icon(LauncherIcons.add, size: 18, color: ...)`.
///
/// To add an icon: search the official `fonts/remixicon.css` for
/// `.ri-name-line:before`, copy the hex string from `content: "\xxxx"`, and add
/// one line here.
class LauncherIcons {
  LauncherIcons._();

  // General actions
  static const IconData add = IconData(0xea13, fontFamily: _kFamily);
  static const IconData close = IconData(0xeb99, fontFamily: _kFamily);
  static const IconData check = IconData(0xeb7b, fontFamily: _kFamily);
  static const IconData more = IconData(0xef79, fontFamily: _kFamily);
  static const IconData refresh = IconData(0xf064, fontFamily: _kFamily);
  static const IconData search = IconData(0xf0d1, fontFamily: _kFamily);
  // UI
  static const IconData settings = IconData(0xf0ee, fontFamily: _kFamily);
  // Light/dark switch: shows the current mode
  static const IconData sun = IconData(0xf1bf, fontFamily: _kFamily);
  static const IconData moon = IconData(0xef75, fontFamily: _kFamily);

  // Editing
  static const IconData edit = IconData(0xec86, fontFamily: _kFamily);
  static const IconData pencil = IconData(0xefe0, fontFamily: _kFamily);
  static const IconData delete = IconData(0xec2a, fontFamily: _kFamily);
  static const IconData save = IconData(0xf0b3, fontFamily: _kFamily);

  // Navigation
  static const IconData rocket = IconData(0xf097, fontFamily: _kFamily);
  static const IconData archive = IconData(0xf3a8, fontFamily: _kFamily);
  static const IconData arrowLeft = IconData(0xea60, fontFamily: _kFamily);
  static const IconData history = IconData(0xee17, fontFamily: _kFamily);
  static const IconData links = IconData(0xeeb8, fontFamily: _kFamily);

  // Playback
  static const IconData play = IconData(0xf00b, fontFamily: _kFamily);
  static const IconData pause = IconData(0xefd8, fontFamily: _kFamily);
  static const IconData skipBack = IconData(0xf140, fontFamily: _kFamily);
  static const IconData skipForward = IconData(0xf144, fontFamily: _kFamily);
  static const IconData loader = IconData(0xeeca, fontFamily: _kFamily);

  // World and character
  static const IconData cpu = IconData(0xebf0, fontFamily: _kFamily);
  static const IconData brain = IconData(0xf2f7, fontFamily: _kFamily);
  static const IconData book = IconData(0xeadb, fontFamily: _kFamily);
  static const IconData user = IconData(0xf264, fontFamily: _kFamily);
  static const IconData global = IconData(0xedcf, fontFamily: _kFamily);
  static const IconData eye = IconData(0xecb5, fontFamily: _kFamily);
  static const IconData run = IconData(0xf0a5, fontFamily: _kFamily);
  static const IconData sparkling = IconData(0xf36d, fontFamily: _kFamily);

  // Input
  // Send uses send-plane (the slanted one).
  static const IconData send = IconData(0xf0da, fontFamily: _kFamily);
  static const IconData camera = IconData(0xeb31, fontFamily: _kFamily);
  static const IconData file = IconData(0xeceb, fontFamily: _kFamily);
  static const IconData image = IconData(0xee4b, fontFamily: _kFamily);
  static const IconData mic = IconData(0xef50, fontFamily: _kFamily);
}
