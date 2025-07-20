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
      background: backgroundColor,
    ),

    // Expansion Tile (removes default dividers and adds smooth look)
    expansionTileTheme: ExpansionTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      backgroundColor: Colors.white,
      tilePadding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: 4,
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: defaultPadding),
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: headingFontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      bodyMedium: TextStyle(fontSize: bodyFontSize, color: textColor),
      bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        fontFamily: defaultFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: defaultPadding),
      iconColor: primaryColor,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
    ),

    // cardTheme: CardTheme(
    //   elevation: 1,
    //   margin: const EdgeInsets.symmetric(
    //     horizontal: defaultPadding,
    //     vertical: 6,
    //   ),
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(defaultBorderRadius),
    //   ),
    // ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
