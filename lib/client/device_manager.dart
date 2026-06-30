import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/storage/device_storage.dart';
import 'client_service.dart';

/// 设备在线状态枚举
enum DeviceOnlineStatus {
  /// 在线
  online,

  /// 离线
  offline,

  /// 未知（刚发现但尚未确认状态）
  unknown,
}

/// 已发现设备信息
///
/// 存储单台远程设备的基本信息与实时状态。
class ManagedDevice {
  /// 设备唯一标识
  final String deviceId;

  /// 设备显示名称
  String name;

  /// 设备 IP 地址
  String ipAddress;

  /// HTTP 服务端口
  int port;

  /// HTTP API 访问令牌（SHA256）
  String accessToken;

  /// 设备在线状态
  DeviceOnlineStatus onlineStatus;

  /// 最近一次接收到的系统信息
  SystemInfoData? lastSystemInfo;

  /// 设备首次发现时间
  final DateTime discoveredAt;

  /// 最后一次收到数据的时间
  DateTime? lastSeenAt;

  /// 备注信息
  String? remark;

  ManagedDevice({
    required this.deviceId,
    required this.name,
    required this.ipAddress,
    required this.port,
    this.accessToken = '',
    this.onlineStatus = DeviceOnlineStatus.unknown,
    this.lastSystemInfo,
    required this.discoveredAt,
    this.lastSeenAt,
    this.remark,
  });

  /// 完整 HTTP API 地址
  /// 格式: http://ip:port/deviceId/accessToken
  String get httpUrl => 'http://$ipAddress:$port/$deviceId/$accessToken';

  /// 是否在线
  bool get isOnline => onlineStatus == DeviceOnlineStatus.online;

  /// 转换为 JSON 映射（用于持久化存储）
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'accessToken': accessToken,
      'onlineStatus': onlineStatus.name,
      'discoveredAt': discoveredAt.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'remark': remark,
    };
  }

  /// 从 JSON 映射构造实例
  factory ManagedDevice.fromJson(Map<String, dynamic> json) {
    return ManagedDevice(
      deviceId: json['deviceId'] as String,
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
      accessToken: json['accessToken'] as String? ?? '',
      onlineStatus: DeviceOnlineStatus.values.firstWhere(
        (e) => e.name == json['onlineStatus'],
        orElse: () => DeviceOnlineStatus.unknown,
      ),
      discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String)
          : null,
      remark: json['remark'] as String?,
    );
  }
}

/// 设备管理器
///
/// 负责管理所有已发现的远程监控设备，包括：
/// - 设备的增删改查
/// - 设备在线状态跟踪
/// - 设备列表变化通知
class DeviceManager {
  /// 已注册设备映射表（deviceId -> ManagedDevice）
  final Map<String, ManagedDevice> _devices = {};

  /// 设备列表变化控制器
  final _devicesChangedController = StreamController<List<ManagedDevice>>.broadcast();

  /// 单设备状态变化控制器
  final _deviceStatusController = StreamController<ManagedDevice>.broadcast();

  /// 离线检测定时器
  Timer? _offlineCheckTimer;

  /// 设备离线判定超时时间（秒）
  ///
  /// 若超过此时间未收到设备数据，则将其标记为离线。
  static const int _offlineTimeoutSeconds = 30;

  /// 离线检测间隔（秒）
  static const int _offlineCheckInterval = 10;

  /// 设备存储服务
  final DeviceStorage _storage = DeviceStorage();

  /// 是否正在加载中（加载时跳过自动保存）
  bool _isLoading = false;

  /// 持久化防抖定时器
  Timer? _saveDebounceTimer;

  /// 防抖延迟（毫秒）
  static const int _saveDebounceMs = 500;

  /// 设备管理器构造函数
  DeviceManager();

  // ---------------------------------------------------------------------------
  // 公开流
  // ---------------------------------------------------------------------------

  /// 设备列表变化流
  ///
  /// 当设备被添加、移除或列表发生任何变化时触发。
  Stream<List<ManagedDevice>> get devicesChangedStream =>
      _devicesChangedController.stream;

  /// 单设备状态变化流
  ///
  /// 当某台设备的在线状态或系统信息更新时触发。
  Stream<ManagedDevice> get deviceStatusStream => _deviceStatusController.stream;

  // ---------------------------------------------------------------------------
  // 设备列表访问
  // ---------------------------------------------------------------------------

  /// 获取所有已注册设备的不可变列表
  List<ManagedDevice> get devices => List.unmodifiable(_devices.values);

  /// 获取所有在线设备
  List<ManagedDevice> get onlineDevices =>
      _devices.values.where((d) => d.isOnline).toList();

  /// 获取所有离线设备
  List<ManagedDevice> get offlineDevices =>
      _devices.values.where((d) => !d.isOnline).toList();

  /// 设备总数
  int get deviceCount => _devices.length;

  /// 在线设备数
  int get onlineDeviceCount => onlineDevices.length;

  /// 根据 ID 获取设备信息，不存在时返回 null
  ManagedDevice? getDevice(String deviceId) => _devices[deviceId];

  /// 是否存在指定 ID 的设备
  bool hasDevice(String deviceId) => _devices.containsKey(deviceId);

  // ---------------------------------------------------------------------------
  // 设备管理
  // ---------------------------------------------------------------------------

  /// 添加新设备
  ///
  /// 如果已存在相同 [deviceId] 的设备，将被忽略并返回 false。
  /// 返回 true 表示添加成功。
  bool addDevice(ManagedDevice device) {
    if (_devices.containsKey(device.deviceId)) {
      debugPrint('[DeviceManager] 设备已存在: ${device.deviceId}');
      return false;
    }

    _devices[device.deviceId] = device;
    _notifyDevicesChanged();
    debugPrint('[DeviceManager] 已添加设备: ${device.name} (${device.deviceId})');
    return true;
  }

  /// 移除设备
  ///
  /// 返回 true 表示移除成功，false 表示设备不存在。
  bool removeDevice(String deviceId) {
    final removed = _devices.remove(deviceId);
    if (removed == null) {
      debugPrint('[DeviceManager] 设备不存在，无法移除: $deviceId');
      return false;
    }

    _notifyDevicesChanged();
    debugPrint('[DeviceManager] 已移除设备: ${removed.name} ($deviceId)');
    return true;
  }

  /// 更新设备信息
  ///
  /// 通过回调函数对已有设备信息进行原地修改。
  /// 设备不存在时返回 false。
  bool updateDevice(String deviceId, void Function(ManagedDevice device) updater) {
    final device = _devices[deviceId];
    if (device == null) {
      debugPrint('[DeviceManager] 设备不存在，无法更新: $deviceId');
      return false;
    }

    updater(device);
    _notifyDevicesChanged();
    debugPrint('[DeviceManager] 已更新设备信息: ${device.name} ($deviceId)');
    return true;
  }

  /// 清空所有设备
  void clearDevices() {
    _devices.clear();
    _notifyDevicesChanged();
    debugPrint('[DeviceManager] 已清空所有设备');
  }

  // ---------------------------------------------------------------------------
  // 状态跟踪
  // ---------------------------------------------------------------------------

  /// 更新设备的系统信息数据
  ///
  /// 当收到远程设备的系统信息推送时调用此方法。
  /// 同时会将设备标记为在线并更新 [lastSeenAt]。
  void updateSystemInfo(SystemInfoData data) {
    final device = _devices[data.deviceId];

    if (device == null) {
      // 自动注册新发现的设备
      final newDevice = ManagedDevice(
        deviceId: data.deviceId,
        name: data.deviceName,
        ipAddress: '', // IP 将在连接时确定
        port: 0,       // 端口将在连接时确定
        onlineStatus: DeviceOnlineStatus.online,
        lastSystemInfo: data,
        discoveredAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );
      _devices[data.deviceId] = newDevice;
      _notifyDevicesChanged();
      _notifyDeviceStatusChanged(newDevice);
      debugPrint('[DeviceManager] 自动发现新设备: ${data.deviceName}');
      return;
    }

    // 更新已有设备
    device.lastSystemInfo = data;
    device.lastSeenAt = DateTime.now();

    // 若之前为未知/离线，切换为在线
    if (device.onlineStatus != DeviceOnlineStatus.online) {
      device.onlineStatus = DeviceOnlineStatus.online;
      debugPrint('[DeviceManager] 设备已上线: ${device.name}');
    }

    _notifyDeviceStatusChanged(device);
  }

  /// 将指定设备标记为离线
  void markDeviceOffline(String deviceId) {
    final device = _devices[deviceId];
    if (device == null) return;

    if (device.onlineStatus != DeviceOnlineStatus.offline) {
      device.onlineStatus = DeviceOnlineStatus.offline;
      _notifyDeviceStatusChanged(device);
      _notifyDevicesChanged();
      debugPrint('[DeviceManager] 设备已离线: ${device.name}');
    }
  }

  /// 启动离线检测
  ///
  /// 定期检查所有设备的最后通信时间，将超时设备标记为离线。
  void startOfflineDetection() {
    stopOfflineDetection();
    _offlineCheckTimer = Timer.periodic(
      const Duration(seconds: _offlineCheckInterval),
      (_) => _checkOfflineDevices(),
    );
    debugPrint('[DeviceManager] 离线检测已启动');
  }

  /// 停止离线检测
  void stopOfflineDetection() {
    _offlineCheckTimer?.cancel();
    _offlineCheckTimer = null;
  }

  /// 检查并标记超时设备为离线
  void _checkOfflineDevices() {
    final now = DateTime.now();
    const timeout = Duration(seconds: _offlineTimeoutSeconds);

    for (final device in _devices.values) {
      if (device.onlineStatus == DeviceOnlineStatus.online &&
          device.lastSeenAt != null &&
          now.difference(device.lastSeenAt!) > timeout) {
        device.onlineStatus = DeviceOnlineStatus.offline;
        _notifyDeviceStatusChanged(device);
        _notifyDevicesChanged();
        debugPrint('[DeviceManager] 设备超时离线: ${device.name}');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 查询与排序
  // ---------------------------------------------------------------------------

  /// 按名称搜索设备（模糊匹配，不区分大小写）
  List<ManagedDevice> searchByName(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _devices.values
        .where((d) => d.name.toLowerCase().contains(lowerKeyword))
        .toList();
  }

  /// 获取设备列表的排序副本
  ///
  /// [compare] - 自定义比较函数，默认按名称字母顺序排列。
  List<ManagedDevice> getSortedDevices({
    int Function(ManagedDevice a, ManagedDevice b)? compare,
  }) {
    final list = devices;
    list.sort(compare ?? (a, b) => a.name.compareTo(b.name));
    return list;
  }

  // ---------------------------------------------------------------------------
  // 持久化
  // ---------------------------------------------------------------------------

  /// 将设备列表保存到本地存储
  Future<void> saveDevices() async {
    try {
      await _storage.saveDevices(devices);
      debugPrint('[DeviceManager] 设备列表已保存，共 ${_devices.length} 台');
    } catch (e) {
      debugPrint('[DeviceManager] 保存设备列表失败: $e');
    }
  }

  /// 从本地存储加载设备列表
  Future<void> loadDevices() async {
    _isLoading = true;
    try {
      final loaded = await _storage.loadDevices();
      _devices.clear();
      for (final device in loaded) {
        _devices[device.deviceId] = device;
      }
      _notifyDevicesChanged();
      debugPrint('[DeviceManager] 设备列表已加载，共 ${_devices.length} 台');
    } catch (e) {
      debugPrint('[DeviceManager] 加载设备列表失败: $e');
    } finally {
      _isLoading = false;
    }
  }

  // ---------------------------------------------------------------------------
  // 内部通知
  // ---------------------------------------------------------------------------

  /// 通知设备列表发生变化
  void _notifyDevicesChanged() {
    if (!_devicesChangedController.isClosed) {
      _devicesChangedController.add(devices);
    }
    // 加载时跳过自动保存，避免循环
    if (!_isLoading) {
      // 防抖：500ms 内多次变更只触发一次持久化写入
      _saveDebounceTimer?.cancel();
      _saveDebounceTimer = Timer(
        const Duration(milliseconds: _saveDebounceMs),
        () => saveDevices(),
      );
    }
  }

  /// 通知单台设备状态发生变化
  void _notifyDeviceStatusChanged(ManagedDevice device) {
    if (!_deviceStatusController.isClosed) {
      _deviceStatusController.add(device);
    }
  }

  // ---------------------------------------------------------------------------
  // 资源释放
  // ---------------------------------------------------------------------------

  /// 释放所有资源
  ///
  /// 应在管理器不再需要时调用，关闭所有流和定时器。
  void dispose() {
    stopOfflineDetection();
    _saveDebounceTimer?.cancel();
    _devicesChangedController.close();
    _deviceStatusController.close();
    debugPrint('[DeviceManager] 已释放资源');
  }
}
