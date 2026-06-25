/// 设备数据持久化存储
///
/// 使用 Hive 进行本地设备列表的保存与读取。
library;

import 'package:hive_flutter/hive_flutter.dart';
import '../../client/device_manager.dart';

/// 设备存储服务
///
/// 负责将 [ManagedDevice] 列表持久化到本地 Hive 数据库，
/// 支持保存、加载和清除操作。
class DeviceStorage {
  /// Hive 存储盒子名称
  static const _boxName = 'devices';

  /// 设备列表的存储键名
  static const _devicesKey = 'device_list';

  /// 保存设备列表到本地存储
  ///
  /// 将 [devices] 序列化为 JSON 后写入 Hive 盒子。
  /// 每次保存会覆盖之前的数据。
  Future<void> saveDevices(List<ManagedDevice> devices) async {
    final box = await Hive.openBox(_boxName);
    final jsonList = devices.map((d) => d.toJson()).toList();
    await box.put(_devicesKey, jsonList);
  }

  /// 从本地存储加载设备列表
  ///
  /// 读取 Hive 盒子中的 JSON 数据并反序列化为 [ManagedDevice] 列表。
  /// 若存储为空则返回空列表。
  Future<List<ManagedDevice>> loadDevices() async {
    final box = await Hive.openBox(_boxName);
    final jsonList = box.get(_devicesKey) as List?;

    if (jsonList == null) return [];

    return jsonList
        .map((item) => ManagedDevice.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  /// 清除所有已保存的设备数据
  Future<void> clearDevices() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}
