import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _autoThemeKey = 'auto_theme';
  static const String _customColorKey = 'custom_color';
  static const String _gradientStartKey = 'gradient_start';
  static const String _gradientEndKey = 'gradient_end';
  static const String _useGradientKey = 'use_gradient';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _autoThemeEnabled = false;
  Color _customPrimaryColor = Colors.blue;
  Color _gradientStartColor = Colors.blue;
  Color _gradientEndColor = Colors.purple;
  bool _useGradient = false;

  ThemeMode get themeMode => _themeMode;
  bool get autoThemeEnabled => _autoThemeEnabled;
  Color get customPrimaryColor => _customPrimaryColor;
  Color get gradientStartColor => _gradientStartColor;
  Color get gradientEndColor => _gradientEndColor;
  bool get useGradient => _useGradient;
  
  LinearGradient get customGradient => LinearGradient(
    colors: [_gradientStartColor, _gradientEndColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  ThemeProvider() {
    _loadTheme();
    _checkAutoTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'light';
    _autoThemeEnabled = prefs.getBool(_autoThemeKey) ?? false;
    final colorValue = prefs.getInt(_customColorKey);
    final gradientStart = prefs.getInt(_gradientStartKey);
    final gradientEnd = prefs.getInt(_gradientEndKey);
    _useGradient = prefs.getBool(_useGradientKey) ?? false;
    
    if (colorValue != null) {
      _customPrimaryColor = Color(colorValue);
    }
    if (gradientStart != null) {
      _gradientStartColor = Color(gradientStart);
    }
    if (gradientEnd != null) {
      _gradientEndColor = Color(gradientEnd);
    }
    
    if (_autoThemeEnabled) {
      _themeMode = _getThemeByTime();
    } else {
      _themeMode = themeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  ThemeMode _getThemeByTime() {
    final hour = DateTime.now().hour;
    // Dark mode from 7 PM (19:00) to 7 AM (07:00)
    return (hour >= 19 || hour < 7) ? ThemeMode.dark : ThemeMode.light;
  }

  void _checkAutoTheme() {
    if (_autoThemeEnabled) {
      // Check every hour
      Future.delayed(const Duration(hours: 1), () {
        if (_autoThemeEnabled) {
          final newMode = _getThemeByTime();
          if (newMode != _themeMode) {
            _themeMode = newMode;
            notifyListeners();
          }
          _checkAutoTheme();
        }
      });
    }
  }

  Future<void> toggleTheme() async {
    if (_autoThemeEnabled) {
      await setAutoTheme(false);
    }
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    _autoThemeEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    await prefs.setBool(_autoThemeKey, false);
    notifyListeners();
  }

  Future<void> setAutoTheme(bool enabled) async {
    _autoThemeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoThemeKey, enabled);
    
    if (enabled) {
      // Immediately apply the time-based theme
      final newMode = _getThemeByTime();
      _themeMode = newMode;
      // Also save the current time-based theme
      await prefs.setString(_themeKey, newMode == ThemeMode.dark ? 'dark' : 'light');
      _checkAutoTheme();
    }
    notifyListeners();
  }

  Future<void> setCustomColor(Color color) async {
    _customPrimaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customColorKey, color.value);
    notifyListeners();
  }

  Future<void> setGradientColors(Color startColor, Color endColor) async {
    _gradientStartColor = startColor;
    _gradientEndColor = endColor;
    _useGradient = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gradientStartKey, startColor.value);
    await prefs.setInt(_gradientEndKey, endColor.value);
    await prefs.setBool(_useGradientKey, true);
    notifyListeners();
  }

  Future<void> toggleGradient(bool enabled) async {
    _useGradient = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useGradientKey, enabled);
    notifyListeners();
  }

  ThemeData get lightTheme {
    final primaryColor = _useGradient ? _gradientStartColor : _customPrimaryColor;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(primary: primaryColor),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData get darkTheme {
    final primaryColor = _useGradient ? _gradientStartColor : _customPrimaryColor;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(primary: primaryColor),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
