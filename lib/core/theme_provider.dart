import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// 主题模式枚举
enum ThemeModeOption {
  /// 自动（跟随系统深浅色）
  system,

  /// 浅色模式
  light,

  /// 深色模式
  dark,
}

/// 主题模式枚举扩展
extension ThemeModeOptionX on ThemeModeOption {
  /// 转换为 Flutter 的 [ThemeMode]
  ThemeMode get flutterThemeMode {
    switch (this) {
      case ThemeModeOption.system:
        return ThemeMode.system;
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
    }
  }
}

/// 主题模式 Provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeModeOption>((ref) {
  return ThemeModeNotifier();
});

/// 主题模式状态管理
///
/// 负责主题偏好的持久化存储和运行时状态管理
class ThemeModeNotifier extends StateNotifier<ThemeModeOption> {
  ThemeModeNotifier() : super(ThemeModeOption.system) {
    _loadThemeMode();
  }

  /// 从本地存储加载主题偏好
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(StorageConstants.prefThemeMode);

    if (modeIndex != null && modeIndex < ThemeModeOption.values.length) {
      state = ThemeModeOption.values[modeIndex];
    }
  }

  /// 设置主题模式并持久化
  Future<void> setThemeMode(ThemeModeOption mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageConstants.prefThemeMode, mode.index);
    state = mode;
  }

}
