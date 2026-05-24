import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/services/theme_service.dart';

class AppTheme {
  AppTheme._();

  static ThemeData fromVariant(AppThemeVariant variant) {
    return variant == AppThemeVariant.pink ? pink : light;
  }

  static ThemeData get light => _build(AppPalette.green);

  static ThemeData get pink => _build(AppPalette.pink);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: p.forest,
      onPrimary: p.onPrimary,
      primaryContainer: p.sage,
      onPrimaryContainer: p.charcoal,
      secondary: p.sage,
      onSecondary: p.charcoal,
      secondaryContainer: p.mintLight,
      onSecondaryContainer: p.charcoal,
      tertiary: p.charcoal,
      onTertiary: Colors.white,
      error: const Color(0xFFC62828),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: p.charcoal,
      surfaceContainerHighest: p.mintLight,
      onSurfaceVariant: p.forest,
      outline: p.sage,
      outlineVariant: p.outlineVariant,
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: p.charcoal,
      onInverseSurface: p.mintLight,
      inversePrimary: p.sage,
    );

    return ThemeData(
      useMaterial3: true,
      extensions: [p],
      colorScheme: scheme,
      scaffoldBackgroundColor: p.mintLight,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: p.charcoal,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: Colors.white,
        indicatorColor: p.mintLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: p.forest);
          }
          return IconThemeData(color: p.charcoal);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: p.forest,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(color: p.charcoal);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.forest,
          foregroundColor: p.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.forest,
        foregroundColor: p.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.charcoal,
        contentTextStyle: TextStyle(color: p.onPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: p.charcoal,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: p.charcoal, fontSize: 15),
      ),
      datePickerTheme: DatePickerThemeData(
        headerBackgroundColor: p.forest,
        headerForegroundColor: p.onPrimary,
        todayForegroundColor: WidgetStatePropertyAll(p.forest),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.onPrimary;
          return p.charcoal;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.forest;
          return Colors.transparent;
        }),
      ),
      timePickerTheme: TimePickerThemeData(
        dialHandColor: p.forest,
        hourMinuteColor: p.mintLight,
        hourMinuteTextColor: p.charcoal,
        dayPeriodColor: p.mintLight,
        dayPeriodTextColor: p.charcoal,
        entryModeIconColor: p.forest,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.sage),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.sage),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.forest, width: 2),
        ),
        labelStyle: TextStyle(color: p.charcoal),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.outlineVariant),
      listTileTheme: ListTileThemeData(
        iconColor: p.forest,
        textColor: p.charcoal,
      ),
    );
  }
}
