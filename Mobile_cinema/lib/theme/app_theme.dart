import 'package:flutter/material.dart';

class AppTheme {
  // Primary color constant
  static const Color primaryColor = Colors.red;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Colors.red,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        color: Colors.red,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.red,
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: Colors.red,
        secondary: Colors.redAccent,
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200]!,
        disabledColor: Colors.grey[300]!,
        selectedColor: Colors.red,
        secondarySelectedColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelStyle: const TextStyle(color: Colors.black87),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
      ),
      cardColor: Colors.white,
      dividerColor: Colors.grey[200],
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey[600],
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.red,
        unselectedLabelColor: Colors.grey[600],
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[100],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      iconTheme: const IconThemeData(
        color: Colors.black54,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: Colors.red,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        color: Colors.grey[900]!,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.red,
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: Colors.red,
        secondary: Colors.redAccent,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800]!,
        disabledColor: Colors.grey[700]!,
        selectedColor: Colors.red,
        secondarySelectedColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelStyle: const TextStyle(color: Colors.white70),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.dark,
      ),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: Colors.grey[800],
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey[400],
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[850],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      // Ensure icon colors are appropriate for dark mode
      iconTheme: const IconThemeData(
        color: Colors.white70,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E1E1E)),
    );
  }

  // Utility class to check if current theme is dark
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
