/// 系统指标模型
///
/// 用于表示系统的各项性能指标，包括 CPU、内存、GPU、磁盘、网络等
/// 支持 JSON 序列化和反序列化

/// CPU 信息模型
class CpuMetrics {
  /// CPU 使用率百分比（0-100）
  final double usagePercent;

  /// CPU 型号名称
  final String modelName;

  /// CPU 核心数
  final int coreCount;

  /// CPU 逻辑处理器数
  final int logicalProcessorCount;

  /// CPU 当前频率（MHz）
  final double currentFrequencyMhz;

  /// CPU 最大频率（MHz）
  final double maxFrequencyMhz;

  /// CPU 温度（摄氏度），可能为 null
  final double? temperatureCelsius;

  /// 每个核心的使用率
  final List<double> coreUsages;

  /// 构造函数
  const CpuMetrics({
    this.usagePercent = 0.0,
    this.modelName = '',
    this.coreCount = 0,
    this.logicalProcessorCount = 0,
    this.currentFrequencyMhz = 0.0,
    this.maxFrequencyMhz = 0.0,
    this.temperatureCelsius,
    this.coreUsages = const [],
  });

  /// 从 JSON Map 创建实例
  factory CpuMetrics.fromJson(Map<String, dynamic> json) {
    return CpuMetrics(
      usagePercent: (json['usage_percent'] as num?)?.toDouble() ?? 0.0,
      modelName: json['model_name'] as String? ?? '',
      coreCount: json['core_count'] as int? ?? 0,
      logicalProcessorCount: json['logical_processor_count'] as int? ?? 0,
      currentFrequencyMhz: (json['current_frequency_mhz'] as num?)?.toDouble() ?? 0.0,
      maxFrequencyMhz: (json['max_frequency_mhz'] as num?)?.toDouble() ?? 0.0,
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble(),
      coreUsages: (json['core_usages'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'usage_percent': usagePercent,
      'model_name': modelName,
      'core_count': coreCount,
      'logical_processor_count': logicalProcessorCount,
      'current_frequency_mhz': currentFrequencyMhz,
      'max_frequency_mhz': maxFrequencyMhz,
      'temperature_celsius': temperatureCelsius,
      'core_usages': coreUsages,
    };
  }

  /// 创建副本
  CpuMetrics copyWith({
    double? usagePercent,
    String? modelName,
    int? coreCount,
    int? logicalProcessorCount,
    double? currentFrequencyMhz,
    double? maxFrequencyMhz,
    double? temperatureCelsius,
    List<double>? coreUsages,
  }) {
    return CpuMetrics(
      usagePercent: usagePercent ?? this.usagePercent,
      modelName: modelName ?? this.modelName,
      coreCount: coreCount ?? this.coreCount,
      logicalProcessorCount: logicalProcessorCount ?? this.logicalProcessorCount,
      currentFrequencyMhz: currentFrequencyMhz ?? this.currentFrequencyMhz,
      maxFrequencyMhz: maxFrequencyMhz ?? this.maxFrequencyMhz,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      coreUsages: coreUsages ?? this.coreUsages,
    );
  }

  /// 获取格式化的频率字符串
  String get formattedFrequency {
    if (currentFrequencyMhz >= 1000) {
      return '${(currentFrequencyMhz / 1000).toStringAsFixed(2)} GHz';
    }
    return '${currentFrequencyMhz.toStringAsFixed(0)} MHz';
  }

  /// 获取格式化的温度字符串
  String get formattedTemperature {
    if (temperatureCelsius == null) return 'N/A';
    return '${temperatureCelsius!.toStringAsFixed(1)} C';
  }
}

/// 内存信息模型
class MemoryMetrics {
  /// 总物理内存（字节）
  final int totalBytes;

  /// 已使用内存（字节）
  final int usedBytes;

  /// 可用内存（字节）
  final int availableBytes;

  /// 内存使用率百分比（0-100）
  final double usagePercent;

  /// 交换分区总大小（字节）
  final int swapTotalBytes;

  /// 已使用交换分区（字节）
  final int swapUsedBytes;

  /// 构造函数
  const MemoryMetrics({
    this.totalBytes = 0,
    this.usedBytes = 0,
    this.availableBytes = 0,
    this.usagePercent = 0.0,
    this.swapTotalBytes = 0,
    this.swapUsedBytes = 0,
  });

  /// 从 JSON Map 创建实例
  factory MemoryMetrics.fromJson(Map<String, dynamic> json) {
    return MemoryMetrics(
      totalBytes: json['total_bytes'] as int? ?? 0,
      usedBytes: json['used_bytes'] as int? ?? 0,
      availableBytes: json['available_bytes'] as int? ?? 0,
      usagePercent: (json['usage_percent'] as num?)?.toDouble() ?? 0.0,
      swapTotalBytes: json['swap_total_bytes'] as int? ?? 0,
      swapUsedBytes: json['swap_used_bytes'] as int? ?? 0,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'total_bytes': totalBytes,
      'used_bytes': usedBytes,
      'available_bytes': availableBytes,
      'usage_percent': usagePercent,
      'swap_total_bytes': swapTotalBytes,
      'swap_used_bytes': swapUsedBytes,
    };
  }

  /// 创建副本
  MemoryMetrics copyWith({
    int? totalBytes,
    int? usedBytes,
    int? availableBytes,
    double? usagePercent,
    int? swapTotalBytes,
    int? swapUsedBytes,
  }) {
    return MemoryMetrics(
      totalBytes: totalBytes ?? this.totalBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      availableBytes: availableBytes ?? this.availableBytes,
      usagePercent: usagePercent ?? this.usagePercent,
      swapTotalBytes: swapTotalBytes ?? this.swapTotalBytes,
      swapUsedBytes: swapUsedBytes ?? this.swapUsedBytes,
    );
  }

  /// 获取格式化的总内存大小
  String get formattedTotal => formatBytes(totalBytes);

  /// 获取格式化的已使用内存大小
  String get formattedUsed => formatBytes(usedBytes);

  /// 获取格式化的可用内存大小
  String get formattedAvailable => formatBytes(availableBytes);

  /// 格式化字节数为可读字符串
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}

/// GPU 信息模型
class GpuMetrics {
  /// GPU 名称
  final String name;

  /// GPU 使用率百分比（0-100）
  final double usagePercent;

  /// GPU 显存总大小（字节）
  final int totalMemoryBytes;

  /// GPU 已使用显存（字节）
  final int usedMemoryBytes;

  /// GPU 温度（摄氏度）
  final double? temperatureCelsius;

  /// GPU 风扇转速百分比（0-100）
  final double? fanSpeedPercent;

  /// GPU 功耗（瓦特）
  final double? powerUsageWatts;

  /// 构造函数
  const GpuMetrics({
    this.name = '',
    this.usagePercent = 0.0,
    this.totalMemoryBytes = 0,
    this.usedMemoryBytes = 0,
    this.temperatureCelsius,
    this.fanSpeedPercent,
    this.powerUsageWatts,
  });

  /// 从 JSON Map 创建实例
  factory GpuMetrics.fromJson(Map<String, dynamic> json) {
    return GpuMetrics(
      name: json['name'] as String? ?? '',
      usagePercent: (json['usage_percent'] as num?)?.toDouble() ?? 0.0,
      totalMemoryBytes: json['total_memory_bytes'] as int? ?? 0,
      usedMemoryBytes: json['used_memory_bytes'] as int? ?? 0,
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble(),
      fanSpeedPercent: (json['fan_speed_percent'] as num?)?.toDouble(),
      powerUsageWatts: (json['power_usage_watts'] as num?)?.toDouble(),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'usage_percent': usagePercent,
      'total_memory_bytes': totalMemoryBytes,
      'used_memory_bytes': usedMemoryBytes,
      'temperature_celsius': temperatureCelsius,
      'fan_speed_percent': fanSpeedPercent,
      'power_usage_watts': powerUsageWatts,
    };
  }

  /// 创建副本
  GpuMetrics copyWith({
    String? name,
    double? usagePercent,
    int? totalMemoryBytes,
    int? usedMemoryBytes,
    double? temperatureCelsius,
    double? fanSpeedPercent,
    double? powerUsageWatts,
  }) {
    return GpuMetrics(
      name: name ?? this.name,
      usagePercent: usagePercent ?? this.usagePercent,
      totalMemoryBytes: totalMemoryBytes ?? this.totalMemoryBytes,
      usedMemoryBytes: usedMemoryBytes ?? this.usedMemoryBytes,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      fanSpeedPercent: fanSpeedPercent ?? this.fanSpeedPercent,
      powerUsageWatts: powerUsageWatts ?? this.powerUsageWatts,
    );
  }

  /// 显存使用率
  double get memoryUsagePercent {
    if (totalMemoryBytes <= 0) return 0.0;
    return (usedMemoryBytes / totalMemoryBytes) * 100;
  }

  /// 格式化的显存使用信息
  String get formattedMemory {
    final used = MemoryMetrics.formatBytes(usedMemoryBytes);
    final total = MemoryMetrics.formatBytes(totalMemoryBytes);
    return '$used / $total';
  }
}

/// 磁盘信息模型
class DiskMetrics {
  /// 磁盘挂载点
  final String mountPoint;

  /// 文件系统类型（如 NTFS、ext4）
  final String fileSystem;

  /// 磁盘总容量（字节）
  final int totalBytes;

  /// 已使用空间（字节）
  final int usedBytes;

  /// 可用空间（字节）
  final int availableBytes;

  /// 使用率百分比（0-100）
  final double usagePercent;

  /// 磁盘读取速率（字节/秒）
  final double readBytesPerSec;

  /// 磁盘写入速率（字节/秒）
  final double writeBytesPerSec;

  /// 构造函数
  const DiskMetrics({
    this.mountPoint = '',
    this.fileSystem = '',
    this.totalBytes = 0,
    this.usedBytes = 0,
    this.availableBytes = 0,
    this.usagePercent = 0.0,
    this.readBytesPerSec = 0.0,
    this.writeBytesPerSec = 0.0,
  });

  /// 从 JSON Map 创建实例
  factory DiskMetrics.fromJson(Map<String, dynamic> json) {
    return DiskMetrics(
      mountPoint: json['mount_point'] as String? ?? '',
      fileSystem: json['file_system'] as String? ?? '',
      totalBytes: json['total_bytes'] as int? ?? 0,
      usedBytes: json['used_bytes'] as int? ?? 0,
      availableBytes: json['available_bytes'] as int? ?? 0,
      usagePercent: (json['usage_percent'] as num?)?.toDouble() ?? 0.0,
      readBytesPerSec: (json['read_bytes_per_sec'] as num?)?.toDouble() ?? 0.0,
      writeBytesPerSec: (json['write_bytes_per_sec'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'mount_point': mountPoint,
      'file_system': fileSystem,
      'total_bytes': totalBytes,
      'used_bytes': usedBytes,
      'available_bytes': availableBytes,
      'usage_percent': usagePercent,
      'read_bytes_per_sec': readBytesPerSec,
      'write_bytes_per_sec': writeBytesPerSec,
    };
  }

  /// 创建副本
  DiskMetrics copyWith({
    String? mountPoint,
    String? fileSystem,
    int? totalBytes,
    int? usedBytes,
    int? availableBytes,
    double? usagePercent,
    double? readBytesPerSec,
    double? writeBytesPerSec,
  }) {
    return DiskMetrics(
      mountPoint: mountPoint ?? this.mountPoint,
      fileSystem: fileSystem ?? this.fileSystem,
      totalBytes: totalBytes ?? this.totalBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      availableBytes: availableBytes ?? this.availableBytes,
      usagePercent: usagePercent ?? this.usagePercent,
      readBytesPerSec: readBytesPerSec ?? this.readBytesPerSec,
      writeBytesPerSec: writeBytesPerSec ?? this.writeBytesPerSec,
    );
  }

  /// 格式化的总容量
  String get formattedTotal => MemoryMetrics.formatBytes(totalBytes);

  /// 格式化的已使用空间
  String get formattedUsed => MemoryMetrics.formatBytes(usedBytes);

  /// 格式化的可用空间
  String get formattedAvailable => MemoryMetrics.formatBytes(availableBytes);

  /// 格式化的读取速率
  String get formattedReadSpeed => '${MemoryMetrics.formatBytes(readBytesPerSec.toInt())}/s';

  /// 格式化的写入速率
  String get formattedWriteSpeed => '${MemoryMetrics.formatBytes(writeBytesPerSec.toInt())}/s';
}

/// 网络信息模型
class NetworkMetrics {
  /// 网络接口名称
  final String interfaceName;

  /// 接收速率（字节/秒）
  final double receiveBytesPerSec;

  /// 发送速率（字节/秒）
  final double sendBytesPerSec;

  /// 总接收字节数
  final int totalReceivedBytes;

  /// 总发送字节数
  final int totalSentBytes;

  /// 网络连接数
  final int connectionCount;

  /// 网络延迟（毫秒）
  final double? latencyMs;

  /// 构造函数
  const NetworkMetrics({
    this.interfaceName = '',
    this.receiveBytesPerSec = 0.0,
    this.sendBytesPerSec = 0.0,
    this.totalReceivedBytes = 0,
    this.totalSentBytes = 0,
    this.connectionCount = 0,
    this.latencyMs,
  });

  /// 从 JSON Map 创建实例
  factory NetworkMetrics.fromJson(Map<String, dynamic> json) {
    return NetworkMetrics(
      interfaceName: json['interface_name'] as String? ?? '',
      receiveBytesPerSec: (json['receive_bytes_per_sec'] as num?)?.toDouble() ?? 0.0,
      sendBytesPerSec: (json['send_bytes_per_sec'] as num?)?.toDouble() ?? 0.0,
      totalReceivedBytes: json['total_received_bytes'] as int? ?? 0,
      totalSentBytes: json['total_sent_bytes'] as int? ?? 0,
      connectionCount: json['connection_count'] as int? ?? 0,
      latencyMs: (json['latency_ms'] as num?)?.toDouble(),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'interface_name': interfaceName,
      'receive_bytes_per_sec': receiveBytesPerSec,
      'send_bytes_per_sec': sendBytesPerSec,
      'total_received_bytes': totalReceivedBytes,
      'total_sent_bytes': totalSentBytes,
      'connection_count': connectionCount,
      'latency_ms': latencyMs,
    };
  }

  /// 创建副本
  NetworkMetrics copyWith({
    String? interfaceName,
    double? receiveBytesPerSec,
    double? sendBytesPerSec,
    int? totalReceivedBytes,
    int? totalSentBytes,
    int? connectionCount,
    double? latencyMs,
  }) {
    return NetworkMetrics(
      interfaceName: interfaceName ?? this.interfaceName,
      receiveBytesPerSec: receiveBytesPerSec ?? this.receiveBytesPerSec,
      sendBytesPerSec: sendBytesPerSec ?? this.sendBytesPerSec,
      totalReceivedBytes: totalReceivedBytes ?? this.totalReceivedBytes,
      totalSentBytes: totalSentBytes ?? this.totalSentBytes,
      connectionCount: connectionCount ?? this.connectionCount,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  /// 格式化的接收速率
  String get formattedReceiveSpeed => '${MemoryMetrics.formatBytes(receiveBytesPerSec.toInt())}/s';

  /// 格式化的发送速率
  String get formattedSendSpeed => '${MemoryMetrics.formatBytes(sendBytesPerSec.toInt())}/s';

  /// 格式化的总接收量
  String get formattedTotalReceived => MemoryMetrics.formatBytes(totalReceivedBytes);

  /// 格式化的总发送量
  String get formattedTotalSent => MemoryMetrics.formatBytes(totalSentBytes);
}

/// 系统指标聚合模型
///
/// 将所有系统指标组合在一起，便于统一管理
class SystemMetrics {
  /// 设备 ID
  final String deviceId;

  /// 数据采集时间戳（Unix 时间戳，毫秒）
  final int timestamp;

  /// CPU 指标
  final CpuMetrics cpu;

  /// 内存指标
  final MemoryMetrics memory;

  /// GPU 指标列表（可能有多个 GPU）
  final List<GpuMetrics> gpus;

  /// 磁盘指标列表（可能有多个分区）
  final List<DiskMetrics> disks;

  /// 网络指标列表（可能有多个网络接口）
  final List<NetworkMetrics> networks;

  /// 系统运行时间（秒）
  final int uptimeSeconds;

  /// 系统负载（1分钟、5分钟、15分钟）
  final List<double> loadAverage;

  /// 构造函数
  const SystemMetrics({
    this.deviceId = '',
    required this.timestamp,
    this.cpu = const CpuMetrics(),
    this.memory = const MemoryMetrics(),
    this.gpus = const [],
    this.disks = const [],
    this.networks = const [],
    this.uptimeSeconds = 0,
    this.loadAverage = const [0.0, 0.0, 0.0],
  });

  /// 从 JSON Map 创建实例
  factory SystemMetrics.fromJson(Map<String, dynamic> json) {
    return SystemMetrics(
      deviceId: json['device_id'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      cpu: CpuMetrics.fromJson(json['cpu'] as Map<String, dynamic>? ?? {}),
      memory: MemoryMetrics.fromJson(json['memory'] as Map<String, dynamic>? ?? {}),
      gpus: (json['gpus'] as List<dynamic>?)
              ?.map((e) => GpuMetrics.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      disks: (json['disks'] as List<dynamic>?)
              ?.map((e) => DiskMetrics.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      networks: (json['networks'] as List<dynamic>?)
              ?.map((e) => NetworkMetrics.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      uptimeSeconds: json['uptime_seconds'] as int? ?? 0,
      loadAverage: (json['load_average'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0.0, 0.0, 0.0],
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'timestamp': timestamp,
      'cpu': cpu.toJson(),
      'memory': memory.toJson(),
      'gpus': gpus.map((e) => e.toJson()).toList(),
      'disks': disks.map((e) => e.toJson()).toList(),
      'networks': networks.map((e) => e.toJson()).toList(),
      'uptime_seconds': uptimeSeconds,
      'load_average': loadAverage,
    };
  }

  /// 创建副本
  SystemMetrics copyWith({
    String? deviceId,
    int? timestamp,
    CpuMetrics? cpu,
    MemoryMetrics? memory,
    List<GpuMetrics>? gpus,
    List<DiskMetrics>? disks,
    List<NetworkMetrics>? networks,
    int? uptimeSeconds,
    List<double>? loadAverage,
  }) {
    return SystemMetrics(
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      cpu: cpu ?? this.cpu,
      memory: memory ?? this.memory,
      gpus: gpus ?? this.gpus,
      disks: disks ?? this.disks,
      networks: networks ?? this.networks,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      loadAverage: loadAverage ?? this.loadAverage,
    );
  }

  /// 获取格式化的运行时间
  String get formattedUptime {
    final days = uptimeSeconds ~/ 86400;
    final hours = (uptimeSeconds % 86400) ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;

    if (days > 0) {
      return '$days 天 $hours 小时 $minutes 分钟';
    } else if (hours > 0) {
      return '$hours 小时 $minutes 分钟';
    } else {
      return '$minutes 分钟';
    }
  }

  /// 获取格式化的系统负载
  String get formattedLoadAverage {
    return loadAverage.map((e) => e.toStringAsFixed(2)).join(' / ');
  }

  /// 获取数据采集时间
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// 获取主要网络接口的指标（第一个非回环接口）
  NetworkMetrics? get primaryNetwork {
    if (networks.isEmpty) return null;
    for (final n in networks) {
      if (n.interfaceName != 'lo' && n.interfaceName != 'Loopback') {
        return n;
      }
    }
    return networks.first;
  }

  /// 获取系统盘的指标（第一个磁盘）
  DiskMetrics? get systemDisk {
    return disks.isNotEmpty ? disks.first : null;
  }
}
