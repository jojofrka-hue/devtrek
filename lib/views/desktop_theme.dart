import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

@immutable
class DesktopPalette extends ThemeExtension<DesktopPalette> {
  const DesktopPalette({
    required this.sidebar,
    required this.card,
    required this.cardBorder,
    required this.subtle,
    required this.track,
  });

  final Color sidebar;
  final Color card;
  final Color cardBorder;
  final Color subtle;
  final Color track;

  static const dark = DesktopPalette(
    sidebar: Color(0xFF171A26),
    card: Color(0xFF1E2231),
    cardBorder: Color(0xFF2C3247),
    // Brightened for high-contrast, comfortable secondary text in dark mode
    // (~9.8:1 against the card surface, WCAG AAA).
    subtle: Color(0xFFC5CDDD),
    track: Color(0xFF2C3247),
  );

  @override
  DesktopPalette copyWith({
    Color? sidebar,
    Color? card,
    Color? cardBorder,
    Color? subtle,
    Color? track,
  }) {
    return DesktopPalette(
      sidebar: sidebar ?? this.sidebar,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      subtle: subtle ?? this.subtle,
      track: track ?? this.track,
    );
  }

  @override
  DesktopPalette lerp(covariant DesktopPalette? other, double t) {
    if (other is! DesktopPalette) return this;
    return DesktopPalette(
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      track: Color.lerp(track, other.track, t)!,
    );
  }
}

DesktopPalette desktopPalette(BuildContext context) =>
    Theme.of(context).extension<DesktopPalette>() ?? DesktopPalette.dark;

ThemeData buildDesktopTheme() {
  const palette = DesktopPalette.dark;
  const background = Color(0xFF12141D);
  const accent = Color(0xFF7EE02E);
  final scheme = ColorScheme.fromSeed(
    seedColor: green,
    brightness: Brightness.dark,
  ).copyWith(surface: background);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.sidebar,
      indicatorColor: green.withValues(alpha: 0.22),
      selectedIconTheme: IconThemeData(color: accent),
      unselectedIconTheme: IconThemeData(color: palette.subtle),
      selectedLabelTextStyle: TextStyle(
        color: accent,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      unselectedLabelTextStyle: TextStyle(color: palette.subtle, fontSize: 13),
    ),
    dividerTheme: DividerThemeData(
      color: palette.cardBorder,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.card,
      isDense: true,
      border: const OutlineInputBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
