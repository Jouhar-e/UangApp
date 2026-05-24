import 'package:flutter/material.dart';

/// Palet warna aktif (hijau atau pink), disematkan di [ThemeData.extensions].
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.mintLight,
    required this.sage,
    required this.forest,
    required this.charcoal,
    required this.onPrimary,
    required this.outlineVariant,
    required this.splashDark,
  });

  final Color mintLight;
  final Color sage;
  final Color forest;
  final Color charcoal;
  final Color onPrimary;
  final Color outlineVariant;

  /// Warna bawah gradien splash (atas = [forest]).
  final Color splashDark;

  Color get forestContainer => mintLight;
  Color get forestDark => charcoal;
  Color get onForest => onPrimary;
  Color get onForestContainer => charcoal;

  static const green = AppPalette(
    mintLight: Color(0xFFF1F8E9),
    sage: Color(0xFF99B898),
    forest: Color(0xFF5B8266),
    charcoal: Color(0xFF334D5C),
    onPrimary: Color(0xFFFFFFFF),
    outlineVariant: Color(0xFFDCE8DC),
    splashDark: Color(0xFF4A6F58),
  );

  /// Pink — dari palet pengguna (#FFF9F5 … #880E4F).
  static const pink = AppPalette(
    mintLight: Color(0xFFFFF9F5),
    sage: Color(0xFFFFC9C9),
    forest: Color(0xFFF06292),
    charcoal: Color(0xFF880E4F),
    onPrimary: Color(0xFFFFFFFF),
    outlineVariant: Color(0xFFF8BBD0),
    splashDark: Color(0xFF880E4F),
  );

  @override
  AppPalette copyWith({
    Color? mintLight,
    Color? sage,
    Color? forest,
    Color? charcoal,
    Color? onPrimary,
    Color? outlineVariant,
    Color? splashDark,
  }) {
    return AppPalette(
      mintLight: mintLight ?? this.mintLight,
      sage: sage ?? this.sage,
      forest: forest ?? this.forest,
      charcoal: charcoal ?? this.charcoal,
      onPrimary: onPrimary ?? this.onPrimary,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      splashDark: splashDark ?? this.splashDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      mintLight: Color.lerp(mintLight, other.mintLight, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      forest: Color.lerp(forest, other.forest, t)!,
      charcoal: Color.lerp(charcoal, other.charcoal, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      outlineVariant:
          Color.lerp(outlineVariant, other.outlineVariant, t)!,
      splashDark: Color.lerp(splashDark, other.splashDark, t)!,
    );
  }

  List<Color> get splashGradient => [forest, splashDark];
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.green;
}
