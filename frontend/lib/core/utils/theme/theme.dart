import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'custom_themes/appbar_theme.dart';
import 'custom_themes/bottom_sheet_theme.dart';
import 'custom_themes/checkbox_theme.dart';
import 'custom_themes/chip_theme.dart';
import 'custom_themes/elevated_button_theme.dart';
import 'custom_themes/outlined_button._theme.dart';
import 'custom_themes/text_field_theme.dart';
import 'custom_themes/text_theme.dart';

/// 🎨 OMGx OChat App Theme
///
/// A sophisticated AI-inspired theme featuring dark purple tones,
/// premium gradients, and cutting-edge design elements that reflect
/// OMGx's innovation in AI technology.
class TAppTheme {
  TAppTheme._();

  /// 🌟 Premium Dark Theme - OMGx OChat Signature Look
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,

    // 🎨 Core Colors
    primaryColor: TColors.primary,
    colorScheme: const ColorScheme.dark(
      // Primary brand colors
      primary: TColors.primary, // Main purple
      onPrimary: TColors.white, // Text on primary
      primaryContainer: TColors.primaryDark, // Container variant
      onPrimaryContainer: TColors.white, // Text on container

      // Secondary colors
      secondary: TColors.secondary, // Cyan accent
      onSecondary: TColors.white, // Text on secondary
      secondaryContainer: TColors.surfaceDark, // Secondary container
      onSecondaryContainer: TColors.textSecondary, // Text on sec container

      // Surface colors
      surface: TColors.surfaceDark, // Card/surface background
      onSurface: TColors.textPrimary, // Text on surface
      surfaceVariant: TColors.cardDark, // Surface variant
      onSurfaceVariant: TColors.textSecondary, // Text on surface variant

      // Background colors
      background: TColors.backgroundDark, // App background
      onBackground: TColors.textPrimary, // Text on background

      // Error colors
      error: TColors.error, // Error color
      onError: TColors.white, // Text on error
      errorContainer: TColors.error, // Error container
      onErrorContainer: TColors.white, // Text on error container

      // Outline colors
      outline: TColors.borderPrimary, // Border color
      outlineVariant: TColors.borderSecondary, // Border variant

      // Inverse colors
      inverseSurface: TColors.white, // Inverse surface
      onInverseSurface: TColors.backgroundDark, // Text on inverse
      inversePrimary: TColors.primary, // Inverse primary
    ),

    // 🏠 Background & Scaffold
    scaffoldBackgroundColor: TColors.backgroundDark,
    canvasColor: TColors.backgroundDark,

    // 📱 App Bar Styling
    appBarTheme: TAppBarTheme.darkAppBarTheme,

    // 🔳 Button Themes
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonData,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TColors.primary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // 🎭 Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: TColors.fabBackground,
      foregroundColor: TColors.fabForeground,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // 📝 Text Styling
    textTheme: TTextTheme.darkTextTheme,

    // 📦 Card Styling
    cardTheme: CardTheme(
      color: TColors.cardBackground,
      shadowColor: TColors.cardShadow,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),

    // 🔲 Input Field Styling
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,

    // 🧩 Chip Styling
    chipTheme: TChipTheme.darkChipTheme,

    // ✅ Checkbox Styling
    checkboxTheme: TCheckboxTheme.darkCheckBoxTheme,

    // 📄 Bottom Sheet Styling
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,

    // 🧭 Navigation Styling
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TColors.bottomNavBackground,
      selectedItemColor: TColors.bottomNavSelected,
      unselectedItemColor: TColors.bottomNavUnselected,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // 🎯 Navigation Rail (for wider screens)
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: TColors.bottomNavBackground,
      selectedIconTheme: IconThemeData(color: TColors.bottomNavSelected),
      unselectedIconTheme: IconThemeData(color: TColors.bottomNavUnselected),
      selectedLabelTextStyle: TextStyle(color: TColors.bottomNavSelected),
      unselectedLabelTextStyle: TextStyle(color: TColors.bottomNavUnselected),
    ),

    // 📊 Progress Indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TColors.primary,
      linearTrackColor: TColors.progressBackground,
      circularTrackColor: TColors.progressBackground,
    ),

    // 🎨 Slider Styling
    sliderTheme: SliderThemeData(
      activeTrackColor: TColors.primary,
      inactiveTrackColor: TColors.progressBackground,
      thumbColor: TColors.primary,
      overlayColor: TColors.glowPurple,
      valueIndicatorColor: TColors.primary,
    ),

    // 🔄 Switch Styling
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TColors.primary;
        }
        return TColors.medium;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TColors.primaryLight;
        }
        return TColors.dark;
      }),
    ),

    // 📱 Dialog Styling
    dialogTheme: DialogTheme(
      backgroundColor: TColors.cardBackground,
      titleTextStyle: const TextStyle(
        color: TColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: TColors.textSecondary,
        fontSize: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // 🍞 Snackbar Styling
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: TColors.cardBackground,
      contentTextStyle: TextStyle(color: TColors.textPrimary),
      actionTextColor: TColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),

    // 🎯 Tab Bar Styling
    tabBarTheme: const TabBarTheme(
      labelColor: TColors.primary,
      unselectedLabelColor: TColors.textSecondary,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: TColors.primary, width: 2),
      ),
    ),

    // 🔗 Divider Styling
    dividerTheme: const DividerThemeData(
      color: TColors.divider,
      thickness: 1,
      space: 1,
    ),

    // 🎭 Icon Styling
    iconTheme: const IconThemeData(
      color: TColors.textSecondary,
      size: 24,
    ),

    // 📋 List Tile Styling
    listTileTheme: const ListTileThemeData(
      textColor: TColors.textPrimary,
      iconColor: TColors.textSecondary,
      tileColor: Colors.transparent,
      selectedTileColor: TColors.elevation1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),

    // 🌊 Splash & Highlight Colors
    splashColor: TColors.glowPurple,
    highlightColor: TColors.glowPurple,
    hoverColor: TColors.glowPurple,
    focusColor: TColors.glowPurple,

    // 📱 Material Banner (for app updates/notifications)
    bannerTheme: const MaterialBannerThemeData(
      backgroundColor: TColors.cardBackground,
      contentTextStyle: TextStyle(color: TColors.textPrimary),
    ),

    // ⏰ Time Picker
    timePickerTheme: TimePickerThemeData(
      backgroundColor: TColors.cardBackground,
      hourMinuteTextColor: TColors.textPrimary,
      dayPeriodTextColor: TColors.textSecondary,
      dialHandColor: TColors.primary,
      dialBackgroundColor: TColors.surfaceDark,
      hourMinuteColor: TColors.surfaceDark,
      entryModeIconColor: TColors.primary,
    ),

    // 📅 Date Picker
    datePickerTheme: DatePickerThemeData(
      backgroundColor: TColors.cardBackground,
      surfaceTintColor: TColors.primary,
      shadowColor: TColors.cardShadow,
    ),
  );

  /// 🌅 Light Theme (Optional - for users who prefer light mode)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: TColors.primary,
    scaffoldBackgroundColor: TColors.white,

    // Keep the same purple accent but adapt for light mode
    colorScheme: ColorScheme.light(
      primary: TColors.primary,
      onPrimary: TColors.white,
      secondary: TColors.secondary,
      onSecondary: TColors.white,
      surface: TColors.white,
      onSurface: TColors.black,
      background: TColors.lightest,
      onBackground: TColors.black,
      error: TColors.error,
      onError: TColors.white,
    ),

    // Apply light variants of custom themes
    textTheme: TTextTheme.lightTextTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    chipTheme: TChipTheme.lightChipTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    checkboxTheme: TCheckboxTheme.lightCheckBoxTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonData,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
  );
}
