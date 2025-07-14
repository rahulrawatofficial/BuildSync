// app_theme.dart

import 'package:buildsync/core/theme/theme_constants.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: defaultFontFamily,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: headingFontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      bodyMedium: TextStyle(fontSize: bodyFontSize, color: textColor),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: backgroundColor,
      contentPadding: EdgeInsets.symmetric(horizontal: defaultPadding),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
        borderSide: BorderSide(color: borderColor),
      ),
    ),
  );
}
