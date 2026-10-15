import 'package:flutter/material.dart';

/// Semantic colors for custom-painted and explicitly styled app widgets.
@immutable
class AppPalette {
  const AppPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.primarySoft,
  });

  final bool isDark;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color primary;
  final Color primarySoft;

  static const light = AppPalette(
    isDark: false,
    background: Color(0xFFF7F9FC),
    surface: Colors.white,
    surfaceVariant: Color(0xFFF0F5FF),
    textPrimary: Color(0xFF0A1638),
    textSecondary: Color(0xFF727D95),
    border: Color(0xFFE5EAF2),
    primary: Color(0xFF167BFF),
    primarySoft: Color(0xFFEAF4FF),
  );

  static const dark = AppPalette(
    isDark: true,
    background: Color(0xFF10151F),
    surface: Color(0xFF1A2230),
    surfaceVariant: Color(0xFF232E40),
    textPrimary: Color(0xFFF0F4FC),
    textSecondary: Color(0xFFB1BCD0),
    border: Color(0xFF354156),
    primary: Color(0xFF8AB8FF),
    primarySoft: Color(0xFF203759),
  );
}

extension AppColorContext on BuildContext {
  AppPalette get appColors => Theme.of(this).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}
