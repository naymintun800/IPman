import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    final ColorScheme scheme = lightColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF743cf3),
          // Customize brightness values for more vibrant colors
          primary: const Color(0xFF743cf3),
          secondary: const Color(0xFF9c6efa),
          surface: const Color(0xFFe3e3fb),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      // Customize text theme for more vibrant text
      textTheme: TextTheme(
        displayLarge: TextStyle(color: scheme.onSurface),
        displayMedium: TextStyle(color: scheme.onSurface),
        displaySmall: TextStyle(color: scheme.onSurface),
        headlineLarge: TextStyle(color: scheme.onSurface),
        headlineMedium: TextStyle(color: scheme.onSurface),
        headlineSmall: TextStyle(color: scheme.onSurface),
        titleLarge: TextStyle(color: scheme.onSurface),
        titleMedium: TextStyle(color: scheme.onSurface),
        titleSmall: TextStyle(color: scheme.onSurface),
        bodyLarge: TextStyle(color: scheme.onSurface),
        bodyMedium: TextStyle(color: scheme.onSurface),
        bodySmall: TextStyle(color: scheme.onSurface),
        labelLarge: TextStyle(color: scheme.onSurface),
        labelMedium: TextStyle(color: scheme.onSurface),
        labelSmall: TextStyle(color: scheme.onSurface),
      ),
      // Customize icon theme for more vibrant icons
      iconTheme: IconThemeData(
        color: scheme.primary,
        size: 24,
      ),
      // Customize app bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.primary,
        iconTheme: IconThemeData(color: scheme.primary),
        titleTextStyle: TextStyle(
          color: scheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Customize button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.light,
      },
    );
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    final ColorScheme scheme = darkColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF743cf3),
          brightness: Brightness.dark,
          // Customize dark mode colors for more vibrant appearance
          primary: const Color(0xFF9c6efa),
          secondary: const Color(0xFFb28aff),
          surface: const Color(0xFF271f30),
          background: const Color(0xFF271f30),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: fontFamily,
      // Customize text theme for more vibrant text in dark mode
      textTheme: TextTheme(
        displayLarge: TextStyle(color: scheme.onSurface),
        displayMedium: TextStyle(color: scheme.onSurface),
        displaySmall: TextStyle(color: scheme.onSurface),
        headlineLarge: TextStyle(color: scheme.onSurface),
        headlineMedium: TextStyle(color: scheme.onSurface),
        headlineSmall: TextStyle(color: scheme.onSurface),
        titleLarge: TextStyle(color: scheme.onSurface),
        titleMedium: TextStyle(color: scheme.onSurface),
        titleSmall: TextStyle(color: scheme.onSurface),
        bodyLarge: TextStyle(color: scheme.onSurface),
        bodyMedium: TextStyle(color: scheme.onSurface),
        bodySmall: TextStyle(color: scheme.onSurface),
        labelLarge: TextStyle(color: scheme.onSurface),
        labelMedium: TextStyle(color: scheme.onSurface),
        labelSmall: TextStyle(color: scheme.onSurface),
      ),
      // Customize icon theme for more vibrant icons in dark mode
      iconTheme: IconThemeData(
        color: scheme.primary,
        size: 24,
      ),
      // Customize app bar theme for dark mode
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.primary,
        iconTheme: IconThemeData(color: scheme.primary),
        titleTextStyle: TextStyle(
          color: scheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Customize button themes for dark mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.dark,
      },
    );
  }
}
