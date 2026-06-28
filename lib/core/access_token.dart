import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设备访问密钥 Provider
///
/// 用于 HTTP API 的访问鉴权，格式为 SHA256 哈希字符串（64 位 HEX）。
/// 首次使用时自动生成并持久化，可通过设置页面手动重置。
final accessTokenProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');

  if (token == null || token.isEmpty) {
    token = _generateToken();
    await prefs.setString('access_token', token);
  }

  return token;
});

/// 重置访问密钥
///
/// 生成新的随机 SHA256 令牌并保存到 SharedPreferences。
/// 返回新生成的令牌字符串。
Future<String> resetAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  final newToken = _generateToken();
  await prefs.setString('access_token', newToken);
  return newToken;
}

/// 从持久化存储同步读取访问密钥（非 Provider 场景使用）
Future<String> loadAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');

  if (token == null || token.isEmpty) {
    token = _generateToken();
    await prefs.setString('access_token', token);
  }

  return token;
}

/// 生成随机 SHA256 令牌
///
/// 使用密码学安全的随机数生成 32 字节数据，
/// 再通过 SHA256 哈希得到 64 位十六进制字符串。
String _generateToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return sha256.convert(bytes).toString();
}
