/// 应用程序常量定义
///
/// 集中管理所有配置常量，便于维护和修改
library;

/// 网络相关常量
class NetworkConstants {
  /// HTTP 服务默认端口号
  static const int defaultHttpPort = 19191;

  /// HTTP 请求超时时间（秒）
  static const int connectionTimeoutSeconds = 10;

  /// HTTP 轮询间隔（秒），客户端定期拉取数据
  static const int pollingIntervalSeconds = 1;

  /// 最大重试次数
  static const int maxRetryAttempts = 3;

  /// 禁止实例化
  NetworkConstants._();
}

/// 数据刷新相关常量
class RefreshConstants {
  /// 系统指标默认刷新间隔（毫秒）
  static const int defaultRefreshIntervalMs = 1000;

  /// CPU 使用率刷新间隔（毫秒）
  static const int cpuRefreshIntervalMs = 1000;

  /// 内存使用率刷新间隔（毫秒）
  static const int memoryRefreshIntervalMs = 1000;

  /// 磁盘使用率刷新间隔（毫秒）
  static const int diskRefreshIntervalMs = 5000;

  /// 网络流量刷新间隔（毫秒）
  static const int networkRefreshIntervalMs = 1000;

  /// GPU 使用率刷新间隔（毫秒）
  static const int gpuRefreshIntervalMs = 1000;

  /// 进程列表刷新间隔（毫秒）
  static const int processRefreshIntervalMs = 2000;

  /// 历史数据点数量上限
  static const int maxHistoryDataPoints = 60;

  /// 禁止实例化
  RefreshConstants._();
}

/// 应用配置常量
class AppConfigConstants {
  /// 应用名称
  static const String appName = 'Myriad Monitor';

  /// 应用版本号
  /// 编译时通过 --dart-define=APP_VERSION=x.y.z 注入，自动与 pubspec.yaml 同步
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

  /// 应用构建号（对应 Android versionCode）
  /// 编译时通过 --dart-define=APP_BUILD_NUMBER=N 注入，自动与 pubspec.yaml 同步
  static const String appBuildNumber = String.fromEnvironment('APP_BUILD_NUMBER', defaultValue: '0');

  /// 应用包名
  static const String packageName = 'com.myriad.monitor';

  /// 窗口默认宽度
  static const double defaultWindowWidth = 1200.0;

  /// 窗口默认高度
  static const double defaultWindowHeight = 800.0;

  /// 窗口最小宽度
  static const double minWindowWidth = 800.0;

  /// 窗口最小高度
  static const double minWindowHeight = 600.0;

  /// 禁止实例化
  AppConfigConstants._();
}

/// UI 相关常量
class UIConstants {
  /// 默认内边距
  static const double defaultPadding = 16.0;

  /// 小内边距
  static const double smallPadding = 8.0;

  /// 大内边距
  static const double largePadding = 24.0;

  /// 默认圆角半径
  static const double defaultBorderRadius = 12.0;

  /// 小圆角半径
  static const double smallBorderRadius = 8.0;

  /// 大圆角半径
  static const double largeBorderRadius = 16.0;

  /// 默认卡片高度
  static const double defaultCardHeight = 200.0;

  /// 图表高度
  static const double chartHeight = 300.0;

  /// 动画持续时间（毫秒）
  static const int animationDurationMs = 300;

  /// 禁止实例化
  UIConstants._();
}

/// 存储相关常量
class StorageConstants {
  /// Hive Box 名称 - 设备信息
  static const String deviceInfoBox = 'device_info';

  /// Hive Box 名称 - 系统指标历史
  static const String metricsHistoryBox = 'metrics_history';

  /// Hive Box 名称 - 应用设置
  static const String settingsBox = 'settings';

  /// SharedPreferences 键名 - 主题模式
  static const String prefThemeMode = 'theme_mode';

  /// SharedPreferences 键名 - 语言设置
  static const String prefLanguage = 'language';

  /// SharedPreferences 键名 - 刷新间隔
  static const String prefRefreshInterval = 'refresh_interval';

  /// SharedPreferences 键名 - 自动启动监控
  static const String prefAutoStartMonitor = 'auto_start_monitor';

  /// 禁止实例化
  StorageConstants._();
}

/// 日志级别常量
class LogConstants {
  /// 日志级别：调试
  static const String levelDebug = 'DEBUG';

  /// 日志级别：信息
  static const String levelInfo = 'INFO';

  /// 日志级别：警告
  static const String levelWarning = 'WARNING';

  /// 日志级别：错误
  static const String levelError = 'ERROR';

  /// 日志级别：致命
  static const String levelFatal = 'FATAL';

  /// 最大日志文件大小（MB）
  static const int maxLogFileSizeMB = 10;

  /// 最大日志文件数量
  static const int maxLogFiles = 5;

  /// 禁止实例化
  LogConstants._();
}
