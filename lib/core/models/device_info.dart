/// 设备信息模型
///
/// 用于表示监控设备的基本信息，支持 JSON 序列化和反序列化

/// 设备运行状态枚举
enum DeviceStatus {
  /// 在线运行中
  online,

  /// 离线
  offline,

  /// 连接中
  connecting,

  /// 错误状态
  error;

  /// 获取状态的中文描述
  String get displayName {
    switch (this) {
      case DeviceStatus.online:
        return '在线';
      case DeviceStatus.offline:
        return '离线';
      case DeviceStatus.connecting:
        return '连接中';
      case DeviceStatus.error:
        return '错误';
    }
  }
}

/// 设备操作系统类型枚举
enum DeviceOsType {
  /// Windows 系统
  windows,

  /// macOS 系统
  macos,

  /// Linux 系统
  linux,

  /// 未知系统
  unknown;

  /// 获取操作系统名称
  String get displayName {
    switch (this) {
      case DeviceOsType.windows:
        return 'Windows';
      case DeviceOsType.macos:
        return 'macOS';
      case DeviceOsType.linux:
        return 'Linux';
      case DeviceOsType.unknown:
        return '未知';
    }
  }
}

/// 设备信息模型类
///
/// 包含设备的基本信息，如名称、IP 地址、操作系统等
class DeviceInfo {
  /// 设备唯一标识符
  final String id;

  /// 设备名称
  final String name;

  /// 设备 IP 地址
  final String ipAddress;

  /// 设备端口号
  final int port;

  /// 操作系统类型
  final DeviceOsType osType;

  /// 操作系统版本
  final String osVersion;

  /// 设备运行状态
  final DeviceStatus status;

  /// 设备主机名
  final String hostname;

  /// 设备架构（如 x86_64、arm64）
  final String architecture;

  /// CPU 核心数
  final int cpuCores;

  /// 总内存大小（字节）
  final int totalMemoryBytes;

  /// 设备最后在线时间（Unix 时间戳，毫秒）
  final int lastSeenTimestamp;

  /// 设备描述/备注
  final String description;

  /// 构造函数
  const DeviceInfo({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.port = 8080,
    this.osType = DeviceOsType.unknown,
    this.osVersion = '',
    this.status = DeviceStatus.offline,
    this.hostname = '',
    this.architecture = '',
    this.cpuCores = 0,
    this.totalMemoryBytes = 0,
    this.lastSeenTimestamp = 0,
    this.description = '',
  });

  /// 从 JSON Map 创建 DeviceInfo 实例
  ///
  /// [json] 包含设备信息的 Map
  /// 返回 DeviceInfo 实例
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ipAddress: json['ip_address'] as String? ?? '',
      port: json['port'] as int? ?? 8080,
      osType: _parseOsType(json['os_type'] as String?),
      osVersion: json['os_version'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      hostname: json['hostname'] as String? ?? '',
      architecture: json['architecture'] as String? ?? '',
      cpuCores: json['cpu_cores'] as int? ?? 0,
      totalMemoryBytes: json['total_memory_bytes'] as int? ?? 0,
      lastSeenTimestamp: json['last_seen_timestamp'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }

  /// 将 DeviceInfo 转换为 JSON Map
  ///
  /// 返回包含设备信息的 Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip_address': ipAddress,
      'port': port,
      'os_type': osType.name,
      'os_version': osVersion,
      'status': status.name,
      'hostname': hostname,
      'architecture': architecture,
      'cpu_cores': cpuCores,
      'total_memory_bytes': totalMemoryBytes,
      'last_seen_timestamp': lastSeenTimestamp,
      'description': description,
    };
  }

  /// 解析操作系统类型
  static DeviceOsType _parseOsType(String? value) {
    if (value == null) return DeviceOsType.unknown;
    return DeviceOsType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeviceOsType.unknown,
    );
  }

  /// 解析设备状态
  static DeviceStatus _parseStatus(String? value) {
    if (value == null) return DeviceStatus.offline;
    return DeviceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeviceStatus.offline,
    );
  }

  /// 创建副本并修改部分字段
  DeviceInfo copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    DeviceOsType? osType,
    String? osVersion,
    DeviceStatus? status,
    String? hostname,
    String? architecture,
    int? cpuCores,
    int? totalMemoryBytes,
    int? lastSeenTimestamp,
    String? description,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      osType: osType ?? this.osType,
      osVersion: osVersion ?? this.osVersion,
      status: status ?? this.status,
      hostname: hostname ?? this.hostname,
      architecture: architecture ?? this.architecture,
      cpuCores: cpuCores ?? this.cpuCores,
      totalMemoryBytes: totalMemoryBytes ?? this.totalMemoryBytes,
      lastSeenTimestamp: lastSeenTimestamp ?? this.lastSeenTimestamp,
      description: description ?? this.description,
    );
  }

  /// 获取格式化的总内存大小
  String get formattedTotalMemory {
    if (totalMemoryBytes <= 0) return '未知';
    final gb = totalMemoryBytes / (1024 * 1024 * 1024);
    if (gb >= 1) {
      return '${gb.toStringAsFixed(1)} GB';
    }
    final mb = totalMemoryBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  /// 获取最后在线时间的格式化字符串
  String get formattedLastSeen {
    if (lastSeenTimestamp <= 0) return '从未';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 判断设备是否在线
  bool get isOnline => status == DeviceStatus.online;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeviceInfo(id: $id, name: $name, ip: $ipAddress, status: ${status.displayName})';
  }
}
