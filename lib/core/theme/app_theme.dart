import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Modern Electric Ocean & Cyan Palette matching games_user
  static const Color primaryColor = Color(0xFF0284C7); // Electric Ocean Blue
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color accentColor = Color(0xFF38BDF8); // Bright Cyan
  static const Color secondaryColor = Color(0xFF0EA5E9);
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFF43F5E); // Rose
  static const Color backgroundColor = Color(0xFF07111F); // Deep Oceanic Gaming Slate
  static const Color cardColor = Color(0xFF0F172A); // Elevated Surface
  static const Color surfaceColor = Color(0xFF131D31);

  // ---------------- DARK THEME (ADMIN EXECUTIVE GAMING) ----------------
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: cardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF8FAFC),
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16.5,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIconColor: accentColor,
      suffixIconColor: const Color(0xFF64748B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: primaryColor.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.08),
      thickness: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF07111F),
      indicatorColor: primaryColor.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: accentColor,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.white60,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accentColor, size: 22);
        }
        return const IconThemeData(color: Colors.white60, size: 20);
      }),
    ),
  );
}
