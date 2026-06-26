/// UDP 多播设备发现实现
///
/// 基于 LocalSend 协议的设备发现机制：
/// - 使用多播组 224.0.0.0/24（兼容 Android 设备）
/// - UDP 端口 53317 进行设备发现
///
/// 工作流程：
/// 1. 启动时加入多播组，每 3 秒发送一次 announce 公告（共 5 次）
/// 2. 切换为每 30 秒发送一次心跳，维持在线状态
/// 3. 持续监听多播地址，接收其他设备的广播消息
/// 4. 对收到的心跳消息自动回复 heartbeat_ack
/// 5. 超过 90 秒未收到某设备心跳则判定其离线
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'discovery_message.dart';
import 'discovery_service.dart';

/// UDP 多播设备发现服务
///
/// 实现 [DiscoveryService] 接口，通过 UDP 多播协议实现设备自动发现。
class UdpDiscoveryService implements DiscoveryService {
  /// 多播组地址（LocalSend 使用 224.0.0.0/24 兼容 Android）
  static const String _multicastAddress = '224.0.0.0';

  /// 多播端口号（LocalSend 默认端口）
  static const int _multicastPort = 53317;

  /// 启动阶段公告间隔（毫秒），每 3 秒一次
  static const int _announceIntervalMs = 3000;

  /// 启动阶段公告次数
  static const int _announceCount = 5;

  /// 正常运行时心跳间隔（毫秒），每 30 秒一次
  static const int _heartbeatIntervalMs = 30000;

  /// 设备离线判定超时（毫秒），90 秒未收到心跳判定离线
  static const int _offlineTimeoutMs = 90000;

  /// 离线检测定时检查间隔（毫秒）
  static const int _offlineCheckIntervalMs = 10000;

  /// 本机设备唯一标识符（持久化存储）
  late final String _deviceId;

  /// 本机设备显示名称
  final String deviceName;

  /// 本机服务端口号
  final int servicePort;

  /// UDP 多播套接字
  RawDatagramSocket? _socket;

  /// 公告/心跳定时器
  Timer? _broadcastTimer;

  /// 离线检测定时器
  Timer? _offlineCheckTimer;

  /// 已发现设备的最后心跳时间记录
  /// key: deviceId, value: 最后一次收到消息的时间戳（毫秒）
  final Map<String, int> _deviceLastSeen = {};

  /// 设备发现事件控制器
  final _deviceDiscoveredController =
      StreamController<DiscoveryMessage>.broadcast();

  /// 设备离线事件控制器
  final _deviceLostController =
      StreamController<DiscoveryMessage>.broadcast();

  /// 服务是否已启动
  bool _isRunning = false;

  /// 已完成的公告次数
  int _announceSentCount = 0;

  /// 构造函数
  ///
  /// [deviceName] 本机设备名称，用于在局域网中标识本设备
  /// [servicePort] 本机服务端口号，其他设备连接时使用
  UdpDiscoveryService({
    required this.deviceName,
    required this.servicePort,
  });

  /// 初始化设备 ID（从持久化存储加载或生成新的）
  Future<void> _initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id') ?? const Uuid().v4();
    await prefs.setString('device_id', _deviceId);
  }

  /// 本机设备 ID
  String get deviceId => _deviceId;

  @override
  Stream<DiscoveryMessage> get onDeviceDiscovered =>
      _deviceDiscoveredController.stream;

  @override
  Stream<DiscoveryMessage> get onDeviceLost => _deviceLostController.stream;

  @override
  void start() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      // 初始化设备 ID
      await _initDeviceId();

      // 绑定到多播端口，允许端口复用
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _multicastPort,
        reuseAddress: true,
      );

      // 加入多播组
      _socket!.joinMulticast(
        InternetAddress(_multicastAddress),
      );

      // 开始监听数据包
      _socket!.listen(_onDataReceived);

      // 启动公告阶段
      _startAnnouncePhase();

      // 启动离线检测
      _startOfflineDetection();

      print('[Discovery] 服务已启动，设备 ID: $_deviceId');
      print('[Discovery] 多播地址: $_multicastAddress:$_multicastPort');
    } catch (e) {
      _isRunning = false;
      print('[Discovery] 启动失败: $e');
      rethrow;
    }
  }

  @override
  void stop() {
    if (!_isRunning) return;
    _isRunning = false;

    // 取消所有定时器
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    _offlineCheckTimer?.cancel();
    _offlineCheckTimer = null;

    // 关闭 UDP 套接字
    _socket?.close();
    _socket = null;

    // 清空设备记录
    _deviceLastSeen.clear();

    // 关闭事件流
    _deviceDiscoveredController.close();
    _deviceLostController.close();

    print('[Discovery] 服务已停止');
  }

  /// 获取本机局域网 IP 地址
  ///
  /// 遍历所有网络接口，返回第一个非回环的 IPv4 地址。
  /// 如果无法获取则返回 `127.0.0.1`。
  Future<String> _getLocalIp() async {
    try {
      for (final interface in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      )) {
        for (final addr in interface.addresses) {
          // 排除回环地址
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {
      // 网络接口获取失败时使用回环地址
    }
    return '127.0.0.1';
  }

  /// 获取当前操作系统标识
  ///
  /// 返回小写的操作系统名称：windows / macos / linux / android / ios
  String _getOsName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// 构建公告/心跳消息
  Future<DiscoveryMessage> _buildMessage(String type) async {
    final localIp = await _getLocalIp();
    return DiscoveryMessage(
      type: type,
      deviceId: _deviceId,
      deviceName: deviceName,
      ip: localIp,
      port: servicePort,
      os: _getOsName(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 发送多播消息
  ///
  /// 将 [message] 序列化为 JSON 字符串，通过 UDP 发送到多播地址。
  void _sendMulticast(DiscoveryMessage message) {
    if (_socket == null) return;

    try {
      final data = utf8.encode(message.toJsonString());
      _socket!.send(
        data,
        InternetAddress(_multicastAddress),
        _multicastPort,
      );
      print('[Discovery] 发送 ${message.type} 到 $_multicastAddress:$_multicastPort');
    } catch (e) {
      // 发送失败静默忽略，避免因网络波动导致服务中断
      print('[Discovery] 发送失败: $e');
    }
  }

  /// 启动公告阶段
  ///
  /// 每 3 秒发送一次 announce 公告，共发送 5 次。
  /// 公告完成后自动切换到心跳阶段。
  void _startAnnouncePhase() {
    _announceSentCount = 0;

    // 立即发送第一次公告
    _sendAnnounce();

    // 设置后续公告定时器
    _broadcastTimer = Timer.periodic(
      const Duration(milliseconds: _announceIntervalMs),
      (timer) {
        if (_announceSentCount >= _announceCount) {
          // 公告阶段完成，切换到心跳阶段
          timer.cancel();
          _startHeartbeatPhase();
          return;
        }
        _sendAnnounce();
      },
    );
  }

  /// 发送一次公告消息
  void _sendAnnounce() async {
    _announceSentCount++;
    final message = await _buildMessage(DiscoveryMessageType.announce);
    _sendMulticast(message);
  }

  /// 启动心跳阶段
  ///
  /// 每 30 秒发送一次心跳消息，维持设备在线状态。
  void _startHeartbeatPhase() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(
      const Duration(milliseconds: _heartbeatIntervalMs),
      (_) => _sendHeartbeat(),
    );
  }

  /// 发送一次心跳消息
  void _sendHeartbeat() async {
    final message = await _buildMessage(DiscoveryMessageType.heartbeat);
    _sendMulticast(message);
  }

  /// 启动离线检测
  ///
  /// 定期检查已发现设备的心跳时间，超过 90 秒未响应则判定离线。
  void _startOfflineDetection() {
    _offlineCheckTimer = Timer.periodic(
      const Duration(milliseconds: _offlineCheckIntervalMs),
      (_) => _checkOfflineDevices(),
    );
  }

  /// 检查并清理离线设备
  void _checkOfflineDevices() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final offlineDeviceIds = <String>[];

    for (final entry in _deviceLastSeen.entries) {
      if (now - entry.value > _offlineTimeoutMs) {
        offlineDeviceIds.add(entry.key);
      }
    }

    for (final deviceId in offlineDeviceIds) {
      _deviceLastSeen.remove(deviceId);
      // 通知上层设备离线
      _deviceLostController.add(DiscoveryMessage(
        type: DiscoveryMessageType.heartbeat,
        deviceId: deviceId,
        deviceName: '',
        ip: '',
        port: 0,
        os: '',
        timestamp: now,
      ));
      print('[Discovery] 设备离线: $deviceId');
    }
  }

  /// 处理接收到的 UDP 数据包
  void _onDataReceived(RawSocketEvent event) {
    if (event != RawSocketEvent.read || _socket == null) return;

    final datagram = _socket!.receive();
    if (datagram == null) return;

    try {
      final messageString = utf8.decode(datagram.data);
      final message = DiscoveryMessage.fromJsonString(messageString);

      // 忽略自己发送的消息
      if (message.deviceId == _deviceId) return;

      print('[Discovery] 收到 ${message.type} 来自 ${message.deviceName} (${message.ip})');

      // 更新设备最后在线时间
      _deviceLastSeen[message.deviceId] = DateTime.now().millisecondsSinceEpoch;

      switch (message.type) {
        case DiscoveryMessageType.announce:
          // 收到其他设备的公告，通知上层并回复心跳确认
          _deviceDiscoveredController.add(message);
          _sendHeartbeatAck();
          break;

        case DiscoveryMessageType.heartbeat:
          // 收到心跳消息，回复确认
          _sendHeartbeatAck();
          break;

        case DiscoveryMessageType.heartbeatAck:
          // 收到心跳确认，仅更新在线时间（已在上方处理）
          break;
      }
    } catch (e) {
      // 解析失败的消息静默忽略，可能是非本协议的数据包
      print('[Discovery] 解析消息失败: $e');
    }
  }

  /// 发送心跳确认消息
  void _sendHeartbeatAck() async {
    final message = await _buildMessage(DiscoveryMessageType.heartbeatAck);
    _sendMulticast(message);
  }
}
