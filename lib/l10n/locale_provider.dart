import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言模式枚举
enum LanguageMode {
  /// 跟随系统
  system,

  /// 中文
  chinese,

  /// 英文
  english,
}

/// 语言 Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

/// 语言模式 Provider
final languageModeProvider = StateNotifierProvider<LanguageModeNotifier, LanguageMode>((ref) {
  return LanguageModeNotifier();
});

/// 语言状态管理
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  /// 从本地存储加载语言设置
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');

    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  /// 设置语言
  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();

    if (locale == null) {
      // 跟随系统
      await prefs.remove('language_code');
      state = null;
    } else {
      await prefs.setString('language_code', locale.languageCode);
      state = locale;
    }
  }
}

/// 语言模式状态管理
class LanguageModeNotifier extends StateNotifier<LanguageMode> {
  LanguageModeNotifier() : super(LanguageMode.system) {
    _loadLanguageMode();
  }

  /// 从本地存储加载语言模式
  Future<void> _loadLanguageMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('language_mode');

    if (modeIndex != null && modeIndex < LanguageMode.values.length) {
      state = LanguageMode.values[modeIndex];
    }
  }

  /// 设置语言模式
  Future<void> setLanguageMode(LanguageMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('language_mode', mode.index);
    state = mode;
  }

  /// 获取对应的 Locale
  Locale? get locale {
    switch (state) {
      case LanguageMode.system:
        return null;
      case LanguageMode.chinese:
        return const Locale('zh', 'CN');
      case LanguageMode.english:
        return const Locale('en', 'US');
    }
  }
}
