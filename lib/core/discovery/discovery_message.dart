/// 设备发现消息格式
///
/// 定义设备之间通过 UDP 多播通信的消息结构，
/// 支持设备上线公告、心跳检测和心跳确认三种消息类型。
library;

import 'dart:convert';

/// 发现消息类型常量
class DiscoveryMessageType {
  /// 设备上线公告
  static const String announce = 'announce';

  /// 心跳检测请求
  static const String heartbeat = 'heartbeat';

  /// 心跳确认响应
  static const String heartbeatAck = 'heartbeat_ack';

  /// 禁止实例化
  DiscoveryMessageType._();
}

/// 设备发现消息
///
/// 用于设备之间的 UDP 多播通信，包含设备的基本信息和消息类型。
/// 所有设备通过多播地址 `224.0.0.0:53317` 互相发现。
/// 注意：access_token 不通过多播传输，由 QR 码/手动输入等带外方式交换。
class DiscoveryMessage {
  /// 消息类型：announce / heartbeat / heartbeat_ack
  final String type;

  /// 设备唯一标识符（UUID v4）
  final String deviceId;

  /// 设备显示名称
  final String deviceName;

  /// 设备 IP 地址
  final String ip;

  /// 设备服务端口号
  final int port;

  /// 操作系统标识（如 windows、macos、linux）
  final String os;

  /// 消息发送时的 Unix 时间戳（毫秒）
  final int timestamp;

  /// 构造函数
  const DiscoveryMessage({
    required this.type,
    required this.deviceId,
    required this.deviceName,
    required this.ip,
    required this.port,
    required this.os,
    required this.timestamp,
  });

  /// 从 JSON Map 创建 DiscoveryMessage 实例
  ///
  /// [json] 包含消息数据的 Map
  /// 返回 DiscoveryMessage 实例，字段缺失时使用默认值
  factory DiscoveryMessage.fromJson(Map<String, dynamic> json) {
    return DiscoveryMessage(
      type: json['type'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      ip: json['ip'] as String? ?? '',
      port: json['port'] as int? ?? 0,
      os: json['os'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  /// 将 DiscoveryMessage 转换为 JSON Map
  ///
  /// 返回可序列化为 JSON 字符串的 Map
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'device_id': deviceId,
      'device_name': deviceName,
      'ip': ip,
      'port': port,
      'os': os,
      'timestamp': timestamp,
    };
  }

  /// 从 JSON 字符串解析 DiscoveryMessage
  ///
  /// [jsonString] JSON 格式的字符串
  /// 返回 DiscoveryMessage 实例
  factory DiscoveryMessage.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return DiscoveryMessage.fromJson(map);
  }

  /// 将消息序列化为 JSON 字符串
  ///
  /// 返回 JSON 格式的字符串，适合直接通过 UDP 发送
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 创建指定类型的消息副本
  ///
  /// [newType] 新的消息类型
  /// 返回使用新类型和当前时间戳创建的消息副本
  DiscoveryMessage withType(String newType) {
    return DiscoveryMessage(
      type: newType,
      deviceId: deviceId,
      deviceName: deviceName,
      ip: ip,
      port: port,
      os: os,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 判断是否为公告消息
  bool get isAnnounce => type == DiscoveryMessageType.announce;

  /// 判断是否为心跳消息
  bool get isHeartbeat => type == DiscoveryMessageType.heartbeat;

  /// 判断是否为心跳确认消息
  bool get isHeartbeatAck => type == DiscoveryMessageType.heartbeatAck;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveryMessage &&
        other.type == type &&
        other.deviceId == deviceId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(type, deviceId, timestamp);

  @override
  String toString() {
    return 'DiscoveryMessage(type: $type, deviceId: $deviceId, '
        'name: $deviceName, ip: $ip, port: $port)';
  }
}
