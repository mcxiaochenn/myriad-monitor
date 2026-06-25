import 'dart:async';

/// 系统信息数据模型
///
/// 封装采集到的系统资源信息
class SystemInfo {
  /// CPU 使用率（百分比，0-100）
  final double cpuUsage;

  /// 内存已使用量（字节）
  final int memoryUsed;

  /// 内存总量（字节）
  final int memoryTotal;

  /// 内存使用率（百分比，0-100）
  final double memoryUsage;

  /// 磁盘信息列表
  final List<DiskInfo> disks;

  /// 网络流量信息
  final NetworkTraffic networkTraffic;

  /// 采集时间戳
  final DateTime timestamp;

  const SystemInfo({
    required this.cpuUsage,
    required this.memoryUsed,
    required this.memoryTotal,
    required this.memoryUsage,
    required this.disks,
    required this.networkTraffic,
    required this.timestamp,
  });

  /// 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'cpuUsage': cpuUsage,
      'memoryUsed': memoryUsed,
      'memoryTotal': memoryTotal,
      'memoryUsage': memoryUsage,
      'disks': disks.map((d) => d.toJson()).toList(),
      'networkTraffic': networkTraffic.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 磁盘信息模型
class DiskInfo {
  /// 磁盘挂载点
  final String mountPoint;

  /// 磁盘文件系统类型
  final String fileSystem;

  /// 磁盘总容量（字节）
  final int totalSpace;

  /// 已使用空间（字节）
  final int usedSpace;

  /// 可用空间（字节）
  final int freeSpace;

  /// 使用率（百分比，0-100）
  final double usage;

  const DiskInfo({
    required this.mountPoint,
    required this.fileSystem,
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
    required this.usage,
  });

  /// 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'mountPoint': mountPoint,
      'fileSystem': fileSystem,
      'totalSpace': totalSpace,
      'usedSpace': usedSpace,
      'freeSpace': freeSpace,
      'usage': usage,
    };
  }
}

/// 网络流量信息模型
class NetworkTraffic {
  /// 上传速率（字节/秒）
  final double uploadSpeed;

  /// 下载速率（字节/秒）
  final double downloadSpeed;

  /// 累计上传流量（字节）
  final int totalUploaded;

  /// 累计下载流量（字节）
  final int totalDownloaded;

  const NetworkTraffic({
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.totalUploaded,
    required this.totalDownloaded,
  });

  /// 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'uploadSpeed': uploadSpeed,
      'downloadSpeed': downloadSpeed,
      'totalUploaded': totalUploaded,
      'totalDownloaded': totalDownloaded,
    };
  }
}

/// 系统信息采集器
///
/// 负责采集 CPU、内存、磁盘、网络等系统资源信息
/// 支持定时采集和手动采集两种模式
class SystemInfoCollector {
  /// 定时采集间隔（默认 1 秒）
  final Duration collectionInterval;

  /// 定时采集定时器
  Timer? _collectionTimer;

  /// 系统信息流控制器
  final StreamController<SystemInfo> _infoStreamController =
      StreamController<SystemInfo>.broadcast();

  /// 上一次采集的网络流量数据（用于计算速率）
  NetworkTraffic? _lastNetworkTraffic;

  /// 上一次网络采集时间
  DateTime? _lastNetworkCollectTime;

  /// 构造函数
  ///
  /// [collectionInterval] 采集间隔，默认 1 秒
  SystemInfoCollector({
    this.collectionInterval = const Duration(seconds: 1),
  });

  /// 系统信息数据流
  ///
  /// 监听此流可实时获取系统信息更新
  Stream<SystemInfo> get infoStream => _infoStreamController.stream;

  /// 启动定时采集
  ///
  /// 按照设定的间隔定期采集系统信息并通过流推送
  void startPeriodicCollection() {
    // 停止已有的定时采集
    _collectionTimer?.cancel();

    // 启动新的定时器
    _collectionTimer = Timer.periodic(collectionInterval, (_) async {
      final info = await collectAll();
      _infoStreamController.add(info);
    });
  }

  /// 停止定时采集
  void stopPeriodicCollection() {
    _collectionTimer?.cancel();
    _collectionTimer = null;
  }

  /// 采集所有系统信息
  ///
  /// 返回包含 CPU、内存、磁盘、网络信息的 [SystemInfo] 对象
  Future<SystemInfo> collectAll() async {
    // TODO: 并发采集各项系统信息并汇总
    final cpuUsage = await collectCpuUsage();
    final memoryInfo = await collectMemoryInfo();
    final disks = await collectDiskInfo();
    final networkTraffic = await collectNetworkTraffic();

    return SystemInfo(
      cpuUsage: cpuUsage,
      memoryUsed: memoryInfo['used'] ?? 0,
      memoryTotal: memoryInfo['total'] ?? 0,
      memoryUsage: memoryInfo['usage'] ?? 0.0,
      disks: disks,
      networkTraffic: networkTraffic,
      timestamp: DateTime.now(),
    );
  }

  /// 采集 CPU 使用率
  ///
  /// 返回 CPU 使用率百分比（0-100）
  Future<double> collectCpuUsage() async {
    // TODO: 使用 system_info2 或平台原生方式采集 CPU 使用率
    // 可能需要通过 Platform Channel 调用原生代码获取实时 CPU 数据
    return 0.0;
  }

  /// 采集内存使用情况
  ///
  /// 返回包含 used、total、usage 的 Map
  /// - used: 已使用内存（字节）
  /// - total: 总内存（字节）
  /// - usage: 使用率（百分比）
  Future<Map<String, dynamic>> collectMemoryInfo() async {
    // TODO: 使用 system_info2 获取物理内存信息
    // final totalMemory = await SystemInfo2.getTotalPhysicalMemory();
    // final freeMemory = await SystemInfo2.getFreePhysicalMemory();
    return {
      'used': 0,
      'total': 0,
      'usage': 0.0,
    };
  }

  /// 采集磁盘信息
  ///
  /// 返回所有磁盘分区的信息列表
  Future<List<DiskInfo>> collectDiskInfo() async {
    // TODO: 获取系统磁盘分区信息
    // 需要通过 Platform Channel 调用原生代码获取磁盘使用情况
    return [];
  }

  /// 采集网络流量
  ///
  /// 返回当前网络上传/下载速率和累计流量
  Future<NetworkTraffic> collectNetworkTraffic() async {
    // TODO: 获取网络接口流量数据
    // 需要通过 Platform Channel 调用原生代码获取网络统计
    // 并与上次数据对比计算速率

    const traffic = NetworkTraffic(
      uploadSpeed: 0,
      downloadSpeed: 0,
      totalUploaded: 0,
      totalDownloaded: 0,
    );

    _lastNetworkTraffic = traffic;
    _lastNetworkCollectTime = DateTime.now();

    return traffic;
  }

  /// 释放资源
  ///
  /// 关闭流控制器，停止定时采集
  void dispose() {
    stopPeriodicCollection();
    _infoStreamController.close();
  }
}
