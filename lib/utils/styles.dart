import 'package:flutter/material.dart';

class AppStyles {
  // Colors
  static const Color primaryGold = Color(0xFFc59a2b);
  static final Color fieldBorderColor = Colors.brown.shade700;
  static const Color lightBeige = Color(0xFFf3e9df);
  static const Color veryLightPink = Color(0xFFfbf6f8);
  static const Color pageBackground = Color(0xFFfbf6f2);
  static const Color iconColor = Color(0xFF2b2b2b);
  static const Color darkGray = Color(0xFF4a4a4a);
  static const Color lightGray = Color(0xFF9b9b9b);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryGold,

    primarySwatch: Colors.blue,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),

    // ✔️ secondaryHeaderColor
    secondaryHeaderColor: Colors.amber,

    fontFamily: 'Al-Tarhouny',

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.black87),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),

    scaffoldBackgroundColor: Colors.white,

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: TextStyle(fontWeight: FontWeight.w600 ,fontSize: 16),
      ),
    ),

    textTheme: ThemeData.light().textTheme.copyWith(
      // Titles
      headlineLarge: TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontFamily: 'Al-Tarhouny',
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.blue,
        fontSize: 24,
        fontFamily: 'Al-Tarhouny',
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: Colors.black,
        fontSize: 22,
        fontFamily: 'Andalus',
        fontWeight: FontWeight.bold,
      ),

      // Body text
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontFamily: 'Dubai',
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(
        color: Colors.black,
        fontSize: 26,
        fontFamily: 'Dubai',
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // Dark theme to use with DarkModeProvider
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryGold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGold,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor:  Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor:  Color(0xFF1E1E1E),
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: ThemeData.dark().textTheme.copyWith(
      headlineSmall: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontFamily: 'Andalus',
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: const TextStyle(color: Colors.white70, fontSize: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
    ),
  );

  // Other custom text styles
  static const TextStyle logoTextStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: primaryGold,
    letterSpacing: 1.2,
  );

  static const TextStyle brandNormal = TextStyle(
    fontSize: 18,
    color: Colors.black87,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle brandHighlight = TextStyle(
    fontSize: 18,
    color: primaryGold,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle heroTitle = TextStyle(
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle heroMeta = TextStyle(
    fontSize: 13,
    color: Colors.white70,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Arabic Typesetting',
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: Colors.black87,
  );

  static const TextStyle itemTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
  );

  static const TextStyle itemAuthorStyle = TextStyle(
    fontSize: 13,
    color: Colors.black54,
  );

  static const TextStyle itemRatingCountStyle = TextStyle(
    fontSize: 12,
    color: Colors.black45,
  );
}
