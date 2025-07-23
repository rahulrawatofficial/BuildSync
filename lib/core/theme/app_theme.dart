// app_theme.dart

import 'package:buildsync/core/theme/theme_constants.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: defaultFontFamily,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: cardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB2DFDB),
    ),
    textTheme: TextTheme(
      titleLarge: const TextStyle(
        fontSize: headingFontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: bodyFontSize,
        color: Colors.black.withOpacity(0.85),
      ),
      bodySmall: const TextStyle(fontSize: 12, color: Colors.black54),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
    inputDecorationTheme: _inputTheme,
    elevatedButtonTheme: _buttonTheme,
    expansionTileTheme: ExpansionTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      backgroundColor: cardColor,
      iconColor: primaryColor,
      collapsedIconColor: Colors.black54,
      textColor: primaryColor,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: defaultFontFamily,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF121212), // Dark base background
    cardColor: const Color(0xFF1E2A22), // A deep greenish-black for cards
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: Color(0xFF81C784), // Softer green for accents
      background: Color(0xFF121212),
      surface: Color(0xFF1E2A22),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white70,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: headingFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(fontSize: bodyFontSize, color: Colors.white70),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white54),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1C),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white70,
      textColor: Colors.white70,
    ),
    inputDecorationTheme: _inputThemeDark,
    elevatedButtonTheme: _buttonTheme,
    expansionTileTheme: ExpansionTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      backgroundColor: const Color(0xFF1E2A22),
      collapsedIconColor: Colors.white60,
      iconColor: primaryColor,
      textColor: Colors.white,
    ),
  );

  static const InputDecorationTheme _inputTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
    labelStyle: TextStyle(color: Colors.black54),
  );

  static const InputDecorationTheme _inputThemeDark = InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF2A2A2A),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
      borderSide: BorderSide(color: Colors.white30),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
      borderSide: BorderSide(color: Colors.white30),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
      borderSide: BorderSide(color: secondaryColor, width: 1.5),
    ),
    labelStyle: TextStyle(color: Colors.white54),
  );

  static final ElevatedButtonThemeData _buttonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );
}
