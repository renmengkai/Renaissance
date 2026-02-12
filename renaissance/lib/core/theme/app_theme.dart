import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;

class AppTheme {
  // 复古暖色调色板
  static const Color warmCream = Color(0xFFF5F0E8);
  static const Color warmBeige = Color(0xFFE8DCC4);
  static const Color warmBrown = Color(0xFF8B7355);
  static const Color deepBrown = Color(0xFF4A3728);
  static const Color vintageGold = Color(0xFFD4AF37);
  static const Color mutedRed = Color(0xFF8B4513);
  static const Color charcoal = Color(0xFF2C2C2C);
  static const Color softBlack = Color(0xFF1A1A1A);
  
  // Mica 背景色
  static const Color micaLight = Color(0xFFF3F3F3);
  static const Color micaDark = Color(0xFF202020);
  
  // 亚克力效果色
  static const Color acrylicLight = Color(0x80FFFFFF);
  static const Color acrylicDark = Color(0x80202020);

  static final lightTheme = FluentThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: warmCream,
    accentColor: AccentColor.swatch({
      'normal': vintageGold,
      'dark': vintageGold,
    }),
  );

  static final darkTheme = FluentThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: softBlack,
    accentColor: AccentColor.swatch({
      'normal': vintageGold,
      'dark': vintageGold,
    }),
  );
}
