import 'package:flutter/material.dart';

import '../core/constants.dart';

/// 应用程序路由名称常量
class AppRoutes {
  /// 首页路由
  static const String home = '/';

  /// 设备详情页路由
  static const String deviceDetail = '/device/detail';

  /// 设置页路由
  static const String settings = '/settings';

  /// 关于页路由
  static const String about = '/about';

  /// 禁止实例化
  AppRoutes._();
}

/// 应用路由配置
///
/// 集中管理所有页面路由配置
class AppRouter {
  /// 生成路由
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _buildRoute(const _PlaceholderPage(title: '首页'), settings);

      case AppRoutes.deviceDetail:
        final deviceId = settings.arguments as String? ?? '';
        return _buildRoute(
          _PlaceholderPage(title: '设备详情 - $deviceId'),
          settings,
        );

      case AppRoutes.settings:
        return _buildRoute(const _PlaceholderPage(title: '设置'), settings);

      case AppRoutes.about:
        return _buildRoute(const _PlaceholderPage(title: '关于'), settings);

      default:
        return _buildRoute(
          _PlaceholderPage(title: '404 - 页面未找到'),
          settings,
        );
    }
  }

  /// 构建页面路由（带过渡动画）
  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  /// 禁止实例化
  AppRouter._();
}

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
      cardTheme: CardTheme(
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
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
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

/// 临时占位页面
///
/// 用于尚未实现的路由，后续会被实际页面替代
class _PlaceholderPage extends StatelessWidget {
  /// 页面标题
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: UIConstants.defaultPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: UIConstants.smallPadding),
            Text(
              '此页面正在建设中...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
