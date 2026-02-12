import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

// 主题状态
class ThemeState {
  final ThemeMode themeMode;
  final Color accentColor;
  final bool useSystemTheme;

  const ThemeState({
    this.themeMode = ThemeMode.dark,
    this.accentColor = const Color(0xFFD4AF37), // vintageGold
    this.useSystemTheme = false,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    bool? useSystemTheme,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'accentColor': accentColor.value,
      'useSystemTheme': useSystemTheme,
    };
  }

  factory ThemeState.fromJson(Map<String, dynamic> json) {
    return ThemeState(
      themeMode: ThemeMode.values[json['themeMode'] ?? 1],
      accentColor: Color(json['accentColor'] ?? 0xFFD4AF37),
      useSystemTheme: json['useSystemTheme'] ?? false,
    );
  }
}

// 主题控制器
class ThemeController extends StateNotifier<ThemeState> {
  ThemeController() : super(const ThemeState()) {
    _loadTheme();
  }

  // 从存储加载主题
  Future<void> _loadTheme() async {
    final json = StorageService.getJson(StorageKeys.themeMode);
    if (json != null) {
      state = ThemeState.fromJson(json);
    }
  }

  // 保存主题到存储
  Future<void> _saveTheme() async {
    await StorageService.setJson(StorageKeys.themeMode, state.toJson());
  }

  // 切换主题模式
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode, useSystemTheme: false);
    _saveTheme();
  }

  // 切换到浅色模式
  void setLightMode() {
    setThemeMode(ThemeMode.light);
  }

  // 切换到深色模式
  void setDarkMode() {
    setThemeMode(ThemeMode.dark);
  }

  // 切换主题
  void toggleTheme() {
    final newMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    setThemeMode(newMode);
  }

  // 使用系统主题
  void setUseSystemTheme(bool use) {
    state = state.copyWith(useSystemTheme: use);
    _saveTheme();
  }

  // 设置强调色
  void setAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
    _saveTheme();
  }

  // 预设颜色
  static const List<Color> presetColors = [
    Color(0xFFD4AF37), // 复古金
    Color(0xFF8B4513), // 马鞍棕
    Color(0xFFCD853F), // 秘鲁色
    Color(0xFFD2691E), // 巧克力色
    Color(0xFFBC8F8F), // 玫瑰褐
    Color(0xFF708090), // 石板灰
    Color(0xFF2F4F4F), // 深石板灰
    Color(0xFF800000), // 栗色
  ];
}

// Provider
final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeState>((ref) {
  return ThemeController();
});
