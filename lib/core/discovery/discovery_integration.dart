/// 设备发现集成层
///
/// 将设备发现模块与设备管理器连接起来，
/// 处理设备发现、心跳、离线等事件。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../client/device_manager.dart';
import 'discovery_message.dart';
import 'discovery_service.dart';

/// 设备发现集成服务
///
/// 负责协调 [DiscoveryService] 和 [DeviceManager] 之间的交互：
/// - 设备发现时添加到设备管理器
/// - 设备离线时标记为离线
/// - 心跳消息更新设备最后在线时间
class DiscoveryIntegration {
  /// 设备发现服务
  final DiscoveryService _discoveryService;

  /// 设备管理器
  final DeviceManager _deviceManager;

  /// 事件订阅
  final List<StreamSubscription> _subscriptions = [];

  /// 构造函数
  DiscoveryIntegration({
    required DiscoveryService discoveryService,
    required DeviceManager deviceManager,
  })  : _discoveryService = discoveryService,
        _deviceManager = deviceManager;

  /// 设备发现事件流（暴露给外部使用）
  Stream<DiscoveryMessage> get onDeviceDiscovered =>
      _discoveryService.onDeviceDiscovered;

  /// 启动集成服务
  ///
  /// 开始监听设备发现和离线事件，并将它们转发给设备管理器。
  Future<void> start() async {
    // 启动设备发现服务
    await _discoveryService.start();

    // 监听设备发现事件
    _subscriptions.add(
      _discoveryService.onDeviceDiscovered.listen(_onDeviceDiscovered),
    );

    // 监听设备离线事件
    _subscriptions.add(
      _discoveryService.onDeviceLost.listen(_onDeviceLost),
    );

    debugPrint('[DiscoveryIntegration] 集成服务已启动');
  }

  /// 停止集成服务
  ///
  /// 停止所有事件监听并释放资源。
  void stop() {
    // 取消所有订阅
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // 停止设备发现服务
    _discoveryService.stop();

    debugPrint('[DiscoveryIntegration] 集成服务已停止');
  }

  /// 处理设备发现事件
  ///
  /// 当发现新设备时，将其添加到设备管理器。
  /// 如果设备已存在，则更新其信息。
  void _onDeviceDiscovered(DiscoveryMessage message) {
    debugPrint('[DiscoveryIntegration] 发现设备: ${message.deviceName} (${message.ip})');

    // 检查设备是否已存在
    final existingDevice = _deviceManager.getDevice(message.deviceId);

    if (existingDevice == null) {
      // 添加新设备
      final newDevice = ManagedDevice(
        deviceId: message.deviceId,
        name: message.deviceName,
        ipAddress: message.ip,
        port: message.port,
        onlineStatus: DeviceOnlineStatus.online,
        discoveredAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );

      _deviceManager.addDevice(newDevice);
      debugPrint('[DiscoveryIntegration] 已添加新设备: ${message.deviceName}');
    } else {
      // 更新已有设备信息
      _deviceManager.updateDevice(message.deviceId, (device) {
        device.name = message.deviceName;
        device.ipAddress = message.ip;
        device.port = message.port;
        device.onlineStatus = DeviceOnlineStatus.online;
        device.lastSeenAt = DateTime.now();
      });
      debugPrint('[DiscoveryIntegration] 已更新设备信息: ${message.deviceName}');
    }
  }

  /// 处理设备离线事件
  ///
  /// 当检测到设备离线时，将其标记为离线。
  void _onDeviceLost(DiscoveryMessage message) {
    debugPrint('[DiscoveryIntegration] 设备离线: ${message.deviceName} (${message.ip})');

    _deviceManager.markDeviceOffline(message.deviceId);
  }

  /// 释放所有资源
  ///
  /// 停止集成服务并清理资源。
  void dispose() {
    stop();
  }
}
