import 'package:flutter/material.dart';

/// Design tokens: colors, fonts, spacing and shapes.
/// No Material look — colors and typography are fully custom.
@immutable
class LauncherPalette {
  const LauncherPalette({
    required this.bg,
    required this.surface,
    required this.border,
    required this.text,
    required this.secondary,
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color border;
  final Color text;
  final Color secondary;

  /// Dedicated level for icons and structural elements (dividers, headers).
  /// Kept separate from [secondary] so it can be adjusted without changing
  /// body text. Its initial value matches secondary, so adding it caused
  /// **zero visual change**.
  final Color icon;

  final Color accent;
  final bool isDark;

  /// Dark · machine
  static const LauncherPalette dark = LauncherPalette(
    bg: Color(0xFF0E0F12),
    surface: Color(0xFF16181D),
    border: Color(0xFF262A31),
    text: Color(0xFFE6E3DC),
    secondary: Color(0xFF8A8F98),
    icon: Color(0xFF8A8F98),
    accent: Color(0xFF8AA0B8),
    isDark: true,
  );

  /// Used during light/dark transitions: interpolate every field.
  /// isDark is not interpolated; it flips at the midpoint and is only a switch.
  static LauncherPalette lerp(LauncherPalette a, LauncherPalette b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return LauncherPalette(
      bg: Color.lerp(a.bg, b.bg, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      text: Color.lerp(a.text, b.text, t)!,
      secondary: Color.lerp(a.secondary, b.secondary, t)!,
      icon: Color.lerp(a.icon, b.icon, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      isDark: t < 0.5 ? a.isDark : b.isDark,
    );
  }

  /// Light · paper
  static const LauncherPalette light = LauncherPalette(
    bg: Color(0xFFF5F2EC),
    surface: Color(0xFFFBFAF6),
    border: Color(0xFFE0DAD0),
    text: Color(0xFF1C1B19),
    secondary: Color(0xFF6E6A62),
    icon: Color(0xFF6E6A62),
    accent: Color(0xFF9A7B4F),
    isDark: false,
  );
}

/// Font family.
///
/// Only one family: Noto Sans SC.
/// **Never use generic names such as 'monospace'**: that is not a font name;
/// Windows cannot resolve the family, so the engine falls back to Roboto
/// (the “Material look”), while Chinese falls back to a system font, mixing
/// two typefaces on one line.
class LauncherFonts {
  static const String sans = 'NotoSansSC';

  /// Tabular figures. The old design aligned numbered columns with a
  /// monospace font; this feature keeps digit widths equal so columns do not
  /// jump. Ignored when the font does not support it.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// UI / headings (sans serif)
  static const TextStyle ui = TextStyle(fontFamily: sans);

  /// Metadata / labels (smaller sans serif + tabular figures)
  static const TextStyle meta = TextStyle(
    fontFamily: sans,
    fontFeatures: tabular,
    height: 1.4,
    fontSize: 12,
    letterSpacing: 0.4,
  );
}

/// Spacing scale.
class LauncherSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
}

/// Shapes: square corners / tiny radius, thin lines, no shadows.
class LauncherShape {
  static const double radius = 2;
  static const BorderRadius br = BorderRadius.all(Radius.circular(radius));
  static Border border(Color color) => Border.all(color: color, width: 1);
  static BorderSide side(Color color) => BorderSide(color: color, width: 1);
}

/// User-configurable settings.
@immutable
class LauncherSettings {
  const LauncherSettings({
    this.isDark = true,
    this.followSystem = false,
    this.locale = 'system',
  });

  final bool isDark;

  /// Follow system light/dark mode.
  ///
  /// When enabled, the platform brightness decides which palette is used and
  /// [isDark] is ignored (but kept so disabling follow-system can restore the
  /// user's last choice).
  final bool followSystem;

  /// UI language code: `system` / `en` / `zh` / `ja` / `pt` / `es` / `fr` / `de`.
  final String locale;

  // Note: a convenience `palette` getter is intentionally not provided.
  // The effective palette depends on followSystem; only `_effectiveDark` at
  // the root knows the answer. A getter that only looks at isDark would lie.

  LauncherSettings copyWith({
    bool? isDark,
    bool? followSystem,
    String? locale,
  }) {
    return LauncherSettings(
      isDark: isDark ?? this.isDark,
      followSystem: followSystem ?? this.followSystem,
      locale: locale ?? this.locale,
    );
  }
}

/// Injects the tokens into Theme for descendants to read.
@immutable
class LauncherTheme extends InheritedWidget {
  const LauncherTheme({
    super.key,
    required this.settings,
    required this.palette,
    required super.child,
  });

  final LauncherSettings settings;

  /// The palette **actually** in use. During a light/dark transition this is
  /// the interpolated value, not the target.
  final LauncherPalette palette;

  static LauncherTheme _scope(BuildContext context) {
    final LauncherTheme? t = context
        .dependOnInheritedWidgetOfExactType<LauncherTheme>();
    assert(t != null, 'LauncherTheme is not mounted');
    return t!;
  }

  static LauncherPalette of(BuildContext context) => _scope(context).palette;

  static LauncherSettings settingsOf(BuildContext context) =>
      _scope(context).settings;

  @override
  bool updateShouldNotify(LauncherTheme oldWidget) =>
      settings != oldWidget.settings || palette != oldWidget.palette;
}
