/// 应用设置持久化存储
///
/// 使用 Hive 进行应用偏好设置的键值对存储。
library;

import 'package:hive_flutter/hive_flutter.dart';

/// 设置存储服务
///
/// 提供通用的键值对存储能力，支持任意类型的设置值。
/// 内部使用 Hive 的 Box 进行数据持久化。
class SettingsStorage {
  /// Hive 存储盒子名称
  static const _boxName = 'settings';

  /// 保存设置项
  ///
  /// [key] 设置键名，[value] 设置值（需可序列化为 Hive 支持的类型）。
  /// 若 key 已存在则覆盖旧值。
  Future<void> saveSetting(String key, dynamic value) async {
    final box = await Hive.openBox(_boxName);
    await box.put(key, value);
  }

  /// 读取设置项
  ///
  /// 根据 [key] 读取对应的设置值，并尝试转换为类型 [T]。
  /// 若 key 不存在或类型不匹配则返回 null。
  Future<T?> loadSetting<T>(String key) async {
    final box = await Hive.openBox(_boxName);
    final value = box.get(key);
    if (value is T) {
      return value;
    }
    return null;
  }

  /// 清除所有设置数据
  Future<void> clearSettings() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}
