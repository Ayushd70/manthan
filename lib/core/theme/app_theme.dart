import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the light and dark [ThemeData] for Manthan.
///
/// When the platform exposes a dynamic color palette (Android 12+ / supported
/// desktops) it is used; otherwise we fall back to a brand seed color so the
/// app always looks intentional.
abstract final class AppTheme {
  /// Brand seed used when dynamic color is unavailable.
  static const Color seed = Color(0xFF6750A4);

  /// Builds a theme for the given [brightness] and optional dynamic [scheme].
  static ThemeData build(Brightness brightness, [ColorScheme? scheme]) {
    final colorScheme =
        scheme ?? ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    final baseTextTheme = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.interTextTheme(baseTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 1,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
