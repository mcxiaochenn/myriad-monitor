import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket 连接状态枚举
enum ConnectionStatus {
  /// 未连接
  disconnected,

  /// 正在连接中
  connecting,

  /// 已连接
  connected,

  /// 连接出错
  error,
}

/// 系统信息数据模型
///
/// 表示从远程设备接收到的一条系统信息快照
class SystemInfoData {
  /// 设备标识
  final String deviceId;

  /// 设备名称
  final String deviceName;

  /// CPU 使用率（百分比 0~100）
  final double cpuUsage;

  /// 已用内存（字节）
  final int memoryUsed;

  /// 总内存（字节）
  final int memoryTotal;

  /// 磁盘使用率（百分比 0~100）
  final double diskUsage;

  /// 网络上传速度（字节/秒）
  final double networkUpload;

  /// 网络下载速度（字节/秒）
  final double networkDownload;

  /// CPU 温度（摄氏度，可能为 null）
  final double? cpuTemperature;

  /// 数据采集时间戳
  final DateTime timestamp;

  const SystemInfoData({
    required this.deviceId,
    required this.deviceName,
    required this.cpuUsage,
    required this.memoryUsed,
    required this.memoryTotal,
    required this.diskUsage,
    required this.networkUpload,
    required this.networkDownload,
    this.cpuTemperature,
    required this.timestamp,
  });

  /// 从 JSON 映射构造实例
  factory SystemInfoData.fromJson(Map<String, dynamic> json) {
    return SystemInfoData(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsed: json['memoryUsed'] as int,
      memoryTotal: json['memoryTotal'] as int,
      diskUsage: (json['diskUsage'] as num).toDouble(),
      networkUpload: (json['networkUpload'] as num).toDouble(),
      networkDownload: (json['networkDownload'] as num).toDouble(),
      cpuTemperature: json['cpuTemperature'] != null
          ? (json['cpuTemperature'] as num).toDouble()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// 转换为 JSON 映射
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'cpuUsage': cpuUsage,
      'memoryUsed': memoryUsed,
      'memoryTotal': memoryTotal,
      'diskUsage': diskUsage,
      'networkUpload': networkUpload,
      'networkDownload': networkDownload,
      'cpuTemperature': cpuTemperature,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// WebSocket 客户端服务
///
/// 负责与远程监控设备建立 WebSocket 连接，接收系统信息数据，
/// 并管理连接的生命周期与状态。
class ClientService {
  /// WebSocket 连接地址
  final String serverUrl;

  /// 当前 WebSocket 通道
  WebSocketChannel? _channel;

  /// 连接状态监听流订阅
  StreamSubscription? _subscription;

  /// 心跳定时器
  Timer? _heartbeatTimer;

  /// 重连定时器
  Timer? _reconnectTimer;

  /// 心跳间隔（秒）
  static const int _heartbeatInterval = 10;

  /// 重连间隔（秒）
  static const int _reconnectInterval = 5;

  /// 最大重连次数
  static const int _maxReconnectAttempts = 10;

  /// 当前重连次数
  int _reconnectAttempts = 0;

  /// 当前连接状态
  ConnectionStatus _status = ConnectionStatus.disconnected;

  /// 连接状态变化控制器
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  /// 系统信息数据控制器
  final _dataController = StreamController<SystemInfoData>.broadcast();

  /// 错误信息控制器
  final _errorController = StreamController<String>.broadcast();

  /// 构造函数
  ///
  /// [serverUrl] - WebSocket 服务器地址，例如 "ws://192.168.1.100:8080"
  ClientService({required this.serverUrl});

  // ---------------------------------------------------------------------------
  // 公开流
  // ---------------------------------------------------------------------------

  /// 连接状态变化流
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// 系统信息数据流
  Stream<SystemInfoData> get dataStream => _dataController.stream;

  /// 错误信息流
  Stream<String> get errorStream => _errorController.stream;

  /// 当前连接状态
  ConnectionStatus get status => _status;

  // ---------------------------------------------------------------------------
  // 连接管理
  // ---------------------------------------------------------------------------

  /// 建立 WebSocket 连接
  ///
  /// 连接成功后将开始监听数据并启动心跳检测。
  /// 若连接失败，将根据配置自动重连。
  Future<void> connect() async {
    if (_status == ConnectionStatus.connecting ||
        _status == ConnectionStatus.connected) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    try {
      final uri = Uri.parse(serverUrl);
      _channel = WebSocketChannel.connect(uri);

      // 等待连接就绪
      await _channel!.ready;

      _updateStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;

      // 监听数据流
      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      // 启动心跳
      _startHeartbeat();

      debugPrint('[ClientService] 已连接到 $serverUrl');
    } catch (e) {
      debugPrint('[ClientService] 连接失败: $e');
      _onError(e);
    }
  }

  /// 断开 WebSocket 连接
  ///
  /// 主动断开连接，停止心跳与重连机制。
  Future<void> disconnect() async {
    _stopHeartbeat();
    _stopReconnect();

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _updateStatus(ConnectionStatus.disconnected);
    _reconnectAttempts = 0;

    debugPrint('[ClientService] 已断开连接');
  }

  /// 发送消息到服务器
  ///
  /// [message] - 要发送的消息内容（将被 JSON 编码）
  void sendMessage(Map<String, dynamic> message) {
    if (_status != ConnectionStatus.connected) {
      debugPrint('[ClientService] 未连接，无法发送消息');
      return;
    }

    try {
      final jsonStr = jsonEncode(message);
      _channel?.sink.add(jsonStr);
    } catch (e) {
      debugPrint('[ClientService] 发送消息失败: $e');
      _errorController.add('发送消息失败: $e');
    }
  }

  /// 发送心跳包
  ///
  /// 用于保持连接活跃并检测连接是否存活。
  void _sendHeartbeat() {
    sendMessage({'type': 'heartbeat', 'timestamp': DateTime.now().toIso8601String()});
  }

  // ---------------------------------------------------------------------------
  // 内部回调
  // ---------------------------------------------------------------------------

  /// 收到服务器数据时的回调
  void _onData(dynamic data) {
    try {
      final Map<String, dynamic> json = jsonDecode(data as String);
      final String type = json['type'] as String? ?? 'unknown';

      switch (type) {
        case 'systemInfo':
          final info = SystemInfoData.fromJson(json['payload'] as Map<String, dynamic>);
          _dataController.add(info);
          break;

        case 'heartbeat_ack':
          // 心跳响应，连接仍然存活
          debugPrint('[ClientService] 心跳响应正常');
          break;

        case 'error':
          final String errorMsg = json['message'] as String? ?? '未知错误';
          _errorController.add(errorMsg);
          break;

        default:
          debugPrint('[ClientService] 收到未知消息类型: $type');
      }
    } catch (e) {
      debugPrint('[ClientService] 解析数据失败: $e');
      _errorController.add('数据解析失败: $e');
    }
  }

  /// WebSocket 发生错误时的回调
  void _onError(Object error) {
    debugPrint('[ClientService] WebSocket 错误: $error');
    _errorController.add('连接错误: $error');
    _updateStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }

  /// WebSocket 连接关闭时的回调
  void _onDone() {
    debugPrint('[ClientService] WebSocket 连接已关闭');
    _stopHeartbeat();

    if (_status != ConnectionStatus.disconnected) {
      _updateStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // 心跳机制
  // ---------------------------------------------------------------------------

  /// 启动心跳定时器
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatInterval),
      (_) => _sendHeartbeat(),
    );
  }

  /// 停止心跳定时器
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ---------------------------------------------------------------------------
  // 重连机制
  // ---------------------------------------------------------------------------

  /// 调度一次重连
  void _scheduleReconnect() {
    _stopHeartbeat();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[ClientService] 已达最大重连次数 $_maxReconnectAttempts，停止重连');
      _errorController.add('重连失败：已达最大重连次数');
      _updateStatus(ConnectionStatus.error);
      return;
    }

    _reconnectAttempts++;
    debugPrint('[ClientService] 将在 $_reconnectInterval 秒后进行第 $_reconnectAttempts 次重连');

    _stopReconnect();
    _reconnectTimer = Timer(
      const Duration(seconds: _reconnectInterval),
      () => connect(),
    );
  }

  /// 停止重连定时器
  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ---------------------------------------------------------------------------
  // 工具方法
  // ---------------------------------------------------------------------------

  /// 更新连接状态并通知监听者
  void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// 释放所有资源
  ///
  /// 应在服务不再需要时调用，确保所有流和定时器被正确关闭。
  Future<void> dispose() async {
    await disconnect();

    await _statusController.close();
    await _dataController.close();
    await _errorController.close();
  }
}
