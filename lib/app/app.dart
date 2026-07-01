import 'package:flutter/material.dart';

import '../core/constants.dart';

/// 应用主题配置
///
/// 管理应用程序的亮色和暗色主题
class AppTheme {
  /// 主题强调色
  static const Color primaryColor = Color(0xFF2196F3);

  /// 成功状态颜色
  static const Color successColor = Color(0xFF4CAF50);

  /// 警告状态颜色
  static const Color warningColor = Color(0xFFFF9800);

  /// 错误状态颜色
  static const Color errorColor = Color(0xFFF44336);

  /// 信息状态颜色
  static const Color infoColor = Color(0xFF03A9F4);

  /// CPU 图表颜色
  static const Color cpuChartColor = Color(0xFF42A5F5);

  /// 内存图表颜色
  static const Color memoryChartColor = Color(0xFF66BB6A);

  /// GPU 图表颜色
  static const Color gpuChartColor = Color(0xFFAB47BC);

  /// 磁盘图表颜色
  static const Color diskChartColor = Color(0xFFFF7043);

  /// 网络图表颜色
  static const Color networkChartColor = Color(0xFF26C6DA);

  /// 获取亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryColor,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.smallBorderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIConstants.defaultPadding,
          vertical: UIConstants.smallPadding,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.smallBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.largePadding,
            vertical: UIConstants.defaultPadding,
          ),
        ),
      ),
    );
  }

  /// 获取暗色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryColor,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.smallBorderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIConstants.defaultPadding,
          vertical: UIConstants.smallPadding,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.smallBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.largePadding,
            vertical: UIConstants.defaultPadding,
          ),
        ),
      ),
    );
  }

  /// 根据使用率百分比获取颜色
  ///
  /// 低使用率（<60%）返回绿色，中等（60-85%）返回橙色，高使用率（>85%）返回红色
  static Color getUsageColor(double percent) {
    if (percent < 60) {
      return successColor;
    } else if (percent < 85) {
      return warningColor;
    } else {
      return errorColor;
    }
  }

  /// 禁止实例化
  AppTheme._();
}
