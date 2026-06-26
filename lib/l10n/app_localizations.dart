import 'package:flutter/material.dart';

/// 应用本地化支持
///
/// 支持中文和英文两种语言
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// 获取当前本地化实例
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// 支持的语言列表
  static const supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];

  /// 本地化代理
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ==================== 通用 ====================

  String get appName {
    switch (locale.languageCode) {
      case 'zh':
        return '万镜';
      default:
        return 'Myriad Monitor';
    }
  }

  String get ok => locale.languageCode == 'zh' ? '确定' : 'OK';
  String get cancel => locale.languageCode == 'zh' ? '取消' : 'Cancel';
  String get save => locale.languageCode == 'zh' ? '保存' : 'Save';
  String get delete => locale.languageCode == 'zh' ? '删除' : 'Delete';
  String get search => locale.languageCode == 'zh' ? '搜索' : 'Search';
  String get add => locale.languageCode == 'zh' ? '添加' : 'Add';
  String get close => locale.languageCode == 'zh' ? '关闭' : 'Close';
  String get clear => locale.languageCode == 'zh' ? '清除' : 'Clear';

  // ==================== 底栏导航 ====================

  String get navHome => locale.languageCode == 'zh' ? '主页' : 'Home';
  String get navSettings => locale.languageCode == 'zh' ? '配置' : 'Settings';
  String get navAbout => locale.languageCode == 'zh' ? '关于' : 'About';

  // ==================== 主页 ====================

  String get deviceList => locale.languageCode == 'zh' ? '设备列表' : 'Device List';
  String get searchDevice => locale.languageCode == 'zh' ? '搜索设备' : 'Search Device';
  String get addDevice => locale.languageCode == 'zh' ? '添加设备' : 'Add Device';

  String deviceCount(int total, int online) {
    if (locale.languageCode == 'zh') {
      return '共 $total 台设备，$online 台在线';
    }
    return '$total devices, $online online';
  }

  String searchResult(int count) {
    if (locale.languageCode == 'zh') {
      return '搜索结果: $count 台设备';
    }
    return 'Search results: $count devices';
  }

  String get clearSearch => locale.languageCode == 'zh' ? '清除搜索' : 'Clear Search';
  String get noDeviceFound => locale.languageCode == 'zh' ? '暂未发现设备' : 'No devices found';
  String get noDeviceSearch => locale.languageCode == 'zh' ? '未找到匹配的设备' : 'No matching devices';
  String get ensureSameNetwork =>
      locale.languageCode == 'zh' ? '请确保其他设备在同一局域网内' : 'Ensure devices are on the same network';
  String get tryOtherKeywords =>
      locale.languageCode == 'zh' ? '请尝试其他关键词' : 'Try other keywords';
  String get refresh => locale.languageCode == 'zh' ? '重新搜索' : 'Refresh';

  // ==================== 排序 ====================

  String get sortDevices => locale.languageCode == 'zh' ? '排序' : 'Sort';
  String get sortBy => locale.languageCode == 'zh' ? '排序方式' : 'Sort by';
  String get sortByTime => locale.languageCode == 'zh' ? '按添加时间' : 'By time added';
  String get sortByName => locale.languageCode == 'zh' ? '按名称' : 'By name';
  String get sortByStatus => locale.languageCode == 'zh' ? '按在线状态' : 'By status';
  String get sortByIp => locale.languageCode == 'zh' ? '按 IP 地址' : 'By IP address';
  String get sortDirection => locale.languageCode == 'zh' ? '排序方向' : 'Sort direction';
  String get ascending => locale.languageCode == 'zh' ? '升序' : 'Ascending';
  String get descending => locale.languageCode == 'zh' ? '降序' : 'Descending';
  String get currentSort => locale.languageCode == 'zh' ? '当前排序' : 'Current sort';

  // ==================== 设备卡片 ====================

  String get online => locale.languageCode == 'zh' ? '在线' : 'Online';
  String get offline => locale.languageCode == 'zh' ? '离线' : 'Offline';
  String get lastSeen => locale.languageCode == 'zh' ? '最后在线' : 'Last seen';

  String lastSeenTime(String time) {
    if (locale.languageCode == 'zh') {
      return '最后在线: $time';
    }
    return 'Last seen: $time';
  }

  String get justNow => locale.languageCode == 'zh' ? '刚刚' : 'Just now';
  String secondsAgo(int seconds) =>
      locale.languageCode == 'zh' ? '$seconds秒前' : '$seconds seconds ago';
  String minutesAgo(int minutes) =>
      locale.languageCode == 'zh' ? '$minutes分钟前' : '$minutes min ago';
  String hoursAgo(int hours) =>
      locale.languageCode == 'zh' ? '$hours小时前' : '$hours hours ago';
  String daysAgo(int days) =>
      locale.languageCode == 'zh' ? '$days天前' : '$days days ago';

  // ==================== 添加设备对话框 ====================

  String get deviceName => locale.languageCode == 'zh' ? '设备名称' : 'Device Name';
  String get deviceNameHint =>
      locale.languageCode == 'zh' ? '例如: 我的笔记本' : 'e.g.: My Laptop';
  String get ipAddress => locale.languageCode == 'zh' ? 'IP 地址' : 'IP Address';
  String get ipAddressHint =>
      locale.languageCode == 'zh' ? '例如: 192.168.1.100' : 'e.g.: 192.168.1.100';
  String get port => locale.languageCode == 'zh' ? '端口号' : 'Port';
  String get portHint =>
      locale.languageCode == 'zh' ? '默认 8080' : 'Default 8080';

  String get enterDeviceName =>
      locale.languageCode == 'zh' ? '请输入设备名称' : 'Please enter device name';
  String get enterIpAddress =>
      locale.languageCode == 'zh' ? '请输入 IP 地址' : 'Please enter IP address';
  String get invalidIpAddress =>
      locale.languageCode == 'zh' ? '请输入有效的 IP 地址' : 'Please enter a valid IP address';
  String get enterPort =>
      locale.languageCode == 'zh' ? '请输入端口号' : 'Please enter port';
  String get invalidPort =>
      locale.languageCode == 'zh' ? '请输入有效的端口号 (1-65535)' : 'Please enter a valid port (1-65535)';

  String deviceAdded(String name) {
    if (locale.languageCode == 'zh') {
      return '已添加设备: $name';
    }
    return 'Device added: $name';
  }

  // ==================== 搜索对话框 ====================

  String get searchDeviceHint =>
      locale.languageCode == 'zh' ? '输入设备名称或 IP 地址' : 'Enter device name or IP';

  // ==================== 配置页面 ====================

  String get serverConfig => locale.languageCode == 'zh' ? '服务器配置' : 'Server Config';
  String get autoStartServer =>
      locale.languageCode == 'zh' ? '自动启动服务器' : 'Auto start server';
  String get autoStartServerDesc =>
      locale.languageCode == 'zh' ? '应用启动时自动开启 WebSocket 服务器' : 'Start WebSocket server on app launch';
  String get serverPort => locale.languageCode == 'zh' ? '服务器端口' : 'Server Port';
  String get listenAddress => locale.languageCode == 'zh' ? '监听地址' : 'Listen Address';
  String get pushInterval => locale.languageCode == 'zh' ? '数据推送间隔' : 'Push Interval';
  String seconds(int seconds) => '$seconds ${locale.languageCode == 'zh' ? '秒' : 's'}';

  String get deviceDiscovery => locale.languageCode == 'zh' ? '设备发现' : 'Device Discovery';
  String get enableDiscovery =>
      locale.languageCode == 'zh' ? '启用设备发现' : 'Enable device discovery';
  String get enableDiscoveryDesc =>
      locale.languageCode == 'zh' ? '自动发现局域网内的其他 Myriad 设备' : 'Auto discover other Myriad devices on LAN';
  String get deviceNameLabel => locale.languageCode == 'zh' ? '设备名称' : 'Device Name';

  String get dataStorage => locale.languageCode == 'zh' ? '数据存储' : 'Data Storage';
  String get clearDeviceData =>
      locale.languageCode == 'zh' ? '清除设备数据' : 'Clear device data';
  String get clearDeviceDataDesc =>
      locale.languageCode == 'zh' ? '删除所有已保存的设备信息' : 'Delete all saved device info';
  String get clearHistoryData =>
      locale.languageCode == 'zh' ? '清除历史数据' : 'Clear history data';
  String get clearHistoryDataDesc =>
      locale.languageCode == 'zh' ? '删除所有监控历史记录' : 'Delete all monitoring history';

  String get language => locale.languageCode == 'zh' ? '语言' : 'Language';
  String get systemDefault => locale.languageCode == 'zh' ? '跟随系统' : 'System default';
  String get chinese => locale.languageCode == 'zh' ? '中文' : 'Chinese';
  String get english => locale.languageCode == 'zh' ? '英文' : 'English';

  String get confirmClearData =>
      locale.languageCode == 'zh' ? '确定要删除所有已保存的设备信息吗？此操作不可撤销。' :
      'Are you sure you want to delete all saved device info? This action cannot be undone.';
  String get confirmClearHistory =>
      locale.languageCode == 'zh' ? '确定要删除所有监控历史记录吗？此操作不可撤销。' :
      'Are you sure you want to delete all monitoring history? This action cannot be undone.';
  String get deviceDataCleared =>
      locale.languageCode == 'zh' ? '设备数据已清除' : 'Device data cleared';
  String get historyDataCleared =>
      locale.languageCode == 'zh' ? '历史数据已清除' : 'History data cleared';

  String get editPortTitle => locale.languageCode == 'zh' ? '服务器端口' : 'Server Port';
  String get editPortHint =>
      locale.languageCode == 'zh' ? '输入端口号 (1-65535)' : 'Enter port (1-65535)';
  String get editAddressTitle => locale.languageCode == 'zh' ? '监听地址' : 'Listen Address';
  String get editAddressHint =>
      locale.languageCode == 'zh' ? '输入监听地址 (例如: 0.0.0.0)' : 'Enter address (e.g.: 0.0.0.0)';
  String get editIntervalTitle => locale.languageCode == 'zh' ? '数据推送间隔' : 'Push Interval';
  String get editIntervalHint =>
      locale.languageCode == 'zh' ? '输入间隔秒数 (1-60)' : 'Enter interval (1-60)';
  String get editDeviceNameTitle => locale.languageCode == 'zh' ? '设备名称' : 'Device Name';
  String get editDeviceNameHint =>
      locale.languageCode == 'zh' ? '输入设备名称' : 'Enter device name';

  // ==================== 关于页面 ====================

  String get appDescription =>
      locale.languageCode == 'zh' ?
      '去中心化的跨平台系统监控面板\n设备间 IP 直连，一端采集一端渲染' :
      'Decentralized cross-platform system monitoring\nDirect IP connection, one side collects one side renders';

  String get features => locale.languageCode == 'zh' ? '功能特性' : 'Features';
  String get decentralized => locale.languageCode == 'zh' ? '去中心化' : 'Decentralized';
  String get decentralizedDesc =>
      locale.languageCode == 'zh' ? '无中心服务器，设备间通过 IP 直连通信' :
      'No central server, direct IP communication between devices';
  String get clientServer => locale.languageCode == 'zh' ? '客户端服务端同体' : 'Client-Server in One';
  String get clientServerDesc =>
      locale.languageCode == 'zh' ? '每个实例既是 Server 又是 Client' :
      'Each instance is both Server and Client';
  String get crossPlatform => locale.languageCode == 'zh' ? '跨平台' : 'Cross Platform';
  String get crossPlatformDesc =>
      locale.languageCode == 'zh' ? '支持 Windows、macOS、Linux、Android、iOS' :
      'Supports Windows, macOS, Linux, Android, iOS';
  String get realtimeMonitor => locale.languageCode == 'zh' ? '实时监控' : 'Realtime Monitor';
  String get realtimeMonitorDesc =>
      locale.languageCode == 'zh' ? 'CPU、内存、GPU、磁盘、网络实时图表' :
      'CPU, Memory, GPU, Disk, Network realtime charts';

  String get techStack => locale.languageCode == 'zh' ? '技术栈' : 'Tech Stack';
  String get crossPlatformFramework =>
      locale.languageCode == 'zh' ? '跨平台 UI 框架' : 'Cross-platform UI framework';
  String get stateManagement => locale.languageCode == 'zh' ? '状态管理' : 'State management';
  String get deviceCommunication =>
      locale.languageCode == 'zh' ? '设备间通信' : 'Device communication';
  String get chartRendering => locale.languageCode == 'zh' ? '图表渲染' : 'Chart rendering';
  String get localStorage => locale.languageCode == 'zh' ? '本地数据存储' : 'Local data storage';

  String get developer => locale.languageCode == 'zh' ? '开发者' : 'Developer';
  String get openSourceLicense =>
      locale.languageCode == 'zh' ? '开源许可' : 'Open Source License';
  String get aboutSoftware =>
      locale.languageCode == 'zh' ? '关于本软件' : 'About Software';
  String get blog => locale.languageCode == 'zh' ? '博客' : 'Blog';

  // ==================== 服务端页面 ====================

  String get navServer => locale.languageCode == 'zh' ? '服务端' : 'Server';
  String get deviceInfo => locale.languageCode == 'zh' ? '设备信息' : 'Device Info';
  String get deviceId => locale.languageCode == 'zh' ? '设备 ID' : 'Device ID';
  String get os => locale.languageCode == 'zh' ? '操作系统' : 'OS';
  String get hostname => locale.languageCode == 'zh' ? '主机名' : 'Hostname';
  String get serviceStatus => locale.languageCode == 'zh' ? '服务状态' : 'Service Status';
  String get websocketService => locale.languageCode == 'zh' ? 'WebSocket 服务' : 'WebSocket Service';
  String get running => locale.languageCode == 'zh' ? '运行中' : 'Running';
  String get stopped => locale.languageCode == 'zh' ? '已停止' : 'Stopped';
  String get startService => locale.languageCode == 'zh' ? '启动服务' : 'Start Service';
  String get stopService => locale.languageCode == 'zh' ? '停止服务' : 'Stop Service';
  String get networkInfo => locale.languageCode == 'zh' ? '网络信息' : 'Network Info';
  String get detecting => locale.languageCode == 'zh' ? '检测中...' : 'Detecting...';
  String get connectedClients => locale.languageCode == 'zh' ? '已连接的客户端' : 'Connected Clients';
  String get clientCount => locale.languageCode == 'zh' ? '客户端数量' : 'Client Count';
  String get noClients => locale.languageCode == 'zh' ? '暂无客户端连接' : 'No clients connected';

  // ==================== 关于本软件 ====================

  String get appMeaning =>
      locale.languageCode == 'zh' ?
      '取"万物皆可观、镜照万千端"之意。每台设备是一面镜子，互相映照，无需中心。' :
      '"Myriad" means countless mirrors reflecting each other. Every device is a mirror, reflecting thousands of endpoints, no center needed.';

  // ==================== 设备详情页 ====================

  String get monitorPanel => locale.languageCode == 'zh' ? '的监控面板' : ' Monitor';
  String openingDevice(String name) {
    if (locale.languageCode == 'zh') {
      return '即将打开 $name 的监控面板';
    }
    return 'Opening $name monitor';
  }
}

/// 本地化代理
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
