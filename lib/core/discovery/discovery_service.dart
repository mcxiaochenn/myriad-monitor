/// 设备发现服务抽象层
///
/// 定义设备发现服务的统一接口，屏蔽底层网络实现细节。
/// 上层业务逻辑应依赖此抽象接口，而非直接使用 UDP 实现。
library;

import 'discovery_message.dart';

/// 设备发现服务抽象接口
///
/// 提供设备上线公告广播、心跳维持、设备发现监听等能力。
/// 当前实现为 [UdpDiscoveryService]，未来可扩展为 mDNS 或其他协议。
abstract class DiscoveryService {
  /// 启动设备发现服务
  ///
  /// 开始广播本设备信息并监听局域网内其他设备的广播。
  /// 启动后会发送 announce 公告，随后进入心跳循环。
  Future<void> start();

  /// 停止设备发现服务
  ///
  /// 停止所有广播和监听，释放网络资源。
  /// 调用后服务不可再重新启动，需创建新实例。
  void stop();

  /// 设备发现事件流
  ///
  /// 当发现新设备（收到其他设备的 announce 消息）时触发。
  /// 已知设备重复收到 announce 时也会触发，用于更新设备信息。
  Stream<DiscoveryMessage> get onDeviceDiscovered;

  /// 设备离线事件流
  ///
  /// 当检测到设备离线（心跳超时）时触发。
  /// 通常在最后一次收到心跳后 90 秒判定设备离线。
  Stream<DiscoveryMessage> get onDeviceLost;
}
