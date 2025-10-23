import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themePreferenceKey = 'theme_preference';

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Load saved theme preference
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getBool(_themePreferenceKey);
      
      if (savedTheme != null) {
        _themeMode = savedTheme ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      // If there's an error loading the preference, use the default
      debugPrint('Error loading theme preference: $e');
    }
  }

  // Save theme preference
  Future<void> _saveThemePreference(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, isDark);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference(isDarkMode);
    notifyListeners();
  }
  
  // Utility method to get appropriate colors based on theme
  Color getThemedColor({
    required Color lightColor,
    required Color darkColor,
  }) {
    return isDarkMode ? darkColor : lightColor;
  }
  
  // Get appropriate background color
  Color getBackgroundColor({
    Color? lightColor,
    Color? darkColor,
  }) {
    return isDarkMode 
        ? darkColor ?? const Color(0xFF121212) 
        : lightColor ?? Colors.white;
  }
  
  // Get appropriate card color
  Color getCardColor({
    Color? lightColor,
    Color? darkColor,
  }) {
    return isDarkMode 
        ? darkColor ?? const Color(0xFF1E1E1E) 
        : lightColor ?? Colors.white;
  }
  
  // Get appropriate text color
  Color getTextColor({
    Color? lightColor,
    Color? darkColor,
  }) {
    return isDarkMode 
        ? darkColor ?? Colors.white 
        : lightColor ?? Colors.black;
  }
}
