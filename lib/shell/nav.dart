import 'package:flutter/widgets.dart';

import '../ui/icons.dart';

/// The three left-rail entries. Order is display order.
enum LauncherTab { launch, version, settings }

extension LauncherTabInfo on LauncherTab {
  String get labelKey => switch (this) {
    LauncherTab.launch => 'nav.launch',
    LauncherTab.version => 'nav.version',
    LauncherTab.settings => 'nav.settings',
  };

  IconData get icon => switch (this) {
    LauncherTab.launch => LauncherIcons.rocket,
    LauncherTab.version => LauncherIcons.archive,
    LauncherTab.settings => LauncherIcons.settings,
  };
}
