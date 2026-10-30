import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeMode _activeThemeMode = ThemeMode.light;

  static void setActiveThemeMode(ThemeMode mode) {
    _activeThemeMode = mode;
  }

  static bool get isDarkMode {
    switch (_activeThemeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  static const Color _primaryLight = Color(0xFF0A84FF);
  static const Color _primaryDark = Color(0xFF4DA3FF);
  static const Color _secondaryLight = Color(0xFFF2F2F7);
  static const Color _secondaryDark = Color(0xFF2B2F38);
  static const Color _tertiaryLight = Color(0xFF34C759);
  static const Color _tertiaryDark = Color(0xFF49D96A);

  static const Color _appBgLight = Color(0xFFF5F5F7);
  static const Color _appBgDark = Color(0xFF0B0C10);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceDark = Color(0xFF161922);
  static const Color _mutedSurfaceLight = Color(0xFFF2F2F7);
  static const Color _mutedSurfaceDark = Color(0xFF202531);
  static const Color _elevatedSurfaceLight = Color(0xFFFCFCFD);
  static const Color _elevatedSurfaceDark = Color(0xFF2A3040);
  static const Color _onSurfaceLight = Color(0xFF111111);
  static const Color _onSurfaceDark = Color(0xFFF6F7FA);
  static const Color _onSurfaceVariantLight = Color(0xFF6E6E73);
  static const Color _onSurfaceVariantDark = Color(0xFFA8B0BF);

  static const Color _caloriesLight = Color(0xFFFF9F0A);
  static const Color _caloriesDark = Color(0xFFFFB347);
  static const Color _proteinLight = Color(0xFF5AC8FA);
  static const Color _proteinDark = Color(0xFF7ED8FF);
  static const Color _fatLight = Color(0xFF30D158);
  static const Color _fatDark = Color(0xFF56E17B);
  static const Color _accentSageLight = Color(0xFF34C759);
  static const Color _accentSageDark = Color(0xFF56D87B);
  static const Color _accentOliveLight = Color(0xFF5856D6);
  static const Color _accentOliveDark = Color(0xFF8A84FF);

  static Color get primary => isDarkMode ? _primaryDark : _primaryLight;
  static Color get secondary => isDarkMode ? _secondaryDark : _secondaryLight;
  static Color get tertiary => isDarkMode ? _tertiaryDark : _tertiaryLight;

  static Color get appBg => isDarkMode ? _appBgDark : _appBgLight;
  static Color get surface => isDarkMode ? _surfaceDark : _surfaceLight;
  static Color get mutedSurface =>
      isDarkMode ? _mutedSurfaceDark : _mutedSurfaceLight;
  static Color get elevatedSurface =>
      isDarkMode ? _elevatedSurfaceDark : _elevatedSurfaceLight;
  static Color get onSurface => isDarkMode ? _onSurfaceDark : _onSurfaceLight;
  static Color get onSurfaceVariant =>
      isDarkMode ? _onSurfaceVariantDark : _onSurfaceVariantLight;

  static Color get caloriesColor => isDarkMode ? _caloriesDark : _caloriesLight;
  static Color get proteinColor => isDarkMode ? _proteinDark : _proteinLight;
  static Color get fatColor => isDarkMode ? _fatDark : _fatLight;
  static Color get accentSage =>
      isDarkMode ? _accentSageDark : _accentSageLight;
  static Color get accentOlive =>
      isDarkMode ? _accentOliveDark : _accentOliveLight;

  static BoxDecoration get pageDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? const [Color(0xFF12151E), Color(0xFF0B0D13)]
              : const [Color(0xFFF8F8FA), Color(0xFFF1F3F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );

  static BoxDecoration get softPanelDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? const [Color(0xFF1A1F2B), Color(0xFF151924)]
              : const [Color(0xFFFFFFFF), Color(0xFFF7F8FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    final colorScheme = ColorScheme.fromSeed(
            seedColor: _primaryLight, brightness: Brightness.light)
        .copyWith(
      primary: _primaryLight,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD8EAFF),
      onPrimaryContainer: const Color(0xFF09203C),
      secondary: _secondaryLight,
      onSecondary: _onSurfaceLight,
      secondaryContainer: const Color(0xFFEDEEFA),
      onSecondaryContainer: _onSurfaceLight,
      tertiary: _tertiaryLight,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFDCF7E5),
      onTertiaryContainer: const Color(0xFF123D1F),
      surface: _surfaceLight,
      surfaceContainerHighest: _mutedSurfaceLight,
      onSurface: _onSurfaceLight,
      onSurfaceVariant: _onSurfaceVariantLight,
      outline: const Color(0xFFE1E2E8),
      shadow: const Color(0x14000000),
      error: const Color(0xFFFF453A),
    );

    return base.copyWith(
      scaffoldBackgroundColor: _appBgLight,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
          bodyColor: _onSurfaceLight, displayColor: _onSurfaceLight),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _onSurfaceLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE6E6EB),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _elevatedSurfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: _onSurfaceVariantLight),
        labelStyle: const TextStyle(color: _onSurfaceVariantLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFE6E6EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: _primaryLight, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8D9FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _onSurfaceLight,
          backgroundColor: _surfaceLight,
          side: const BorderSide(color: Color(0xFFE5E5EA)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C1C1E),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      iconTheme: const IconThemeData(size: 22, color: _onSurfaceLight),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _onSurfaceLight,
          backgroundColor: Colors.white.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryLight,
        circularTrackColor: Color(0xFFE6EAF0),
        linearTrackColor: Color(0xFFE9EBF0),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    final colorScheme = ColorScheme.fromSeed(
            seedColor: _primaryDark, brightness: Brightness.dark)
        .copyWith(
      primary: _primaryDark,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF114679),
      onPrimaryContainer: const Color(0xFFD9EBFF),
      secondary: _secondaryDark,
      onSecondary: _onSurfaceDark,
      secondaryContainer: const Color(0xFF2F3643),
      onSecondaryContainer: const Color(0xFFDCE3F0),
      tertiary: _tertiaryDark,
      onTertiary: const Color(0xFF05260F),
      tertiaryContainer: const Color(0xFF184B2A),
      onTertiaryContainer: const Color(0xFFCFF9DA),
      surface: _surfaceDark,
      surfaceContainerHighest: _mutedSurfaceDark,
      onSurface: _onSurfaceDark,
      onSurfaceVariant: _onSurfaceVariantDark,
      outline: const Color(0xFF3B4454),
      shadow: const Color(0x7A000000),
      error: const Color(0xFFFF7D75),
    );

    return base.copyWith(
      scaffoldBackgroundColor: _appBgDark,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
          bodyColor: _onSurfaceDark, displayColor: _onSurfaceDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _onSurfaceDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF313948),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _elevatedSurfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: _onSurfaceVariantDark),
        labelStyle: const TextStyle(color: _onSurfaceVariantDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF3B4454)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: _primaryDark, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF4D6283),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _onSurfaceDark,
          backgroundColor: _surfaceDark,
          side: const BorderSide(color: Color(0xFF3A4250)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A303A),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: _onSurfaceDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      iconTheme: const IconThemeData(size: 22, color: _onSurfaceDark),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _onSurfaceDark,
          backgroundColor: _mutedSurfaceDark.withValues(alpha: 0.82),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryDark,
        circularTrackColor: Color(0xFF2F3745),
        linearTrackColor: Color(0xFF303A4A),
      ),
    );
  }
}
