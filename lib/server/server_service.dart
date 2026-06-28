import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../core/access_token.dart';
import '../core/constants.dart';
import 'system_info_collector.dart';
import 'windows_collector.dart';

/// CORS 响应头（允许跨域访问）
const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

/// JSON 响应头
const _jsonHeaders = {
  'Content-Type': 'application/json; charset=utf-8',
};

/// HTTP 服务器服务
///
/// 提供 HTTP API 服务，支持：
/// - GET /{deviceId}/{accessToken} → 返回系统信息 JSON
/// - GET /health → 健康检查
///
/// 客户端通过 HTTP GET 轮询拉取数据，替代原先的 WebSocket 推送。
class ServerService {
  /// 服务器监听端口
  final int port;

  /// 服务器监听地址
  final String address;

  /// 系统信息采集器
  final SystemInfoCollector _collector;

  /// HTTP 服务器实例
  HttpServer? _server;

  /// 服务器运行状态
  bool _isRunning = false;

  /// 本机设备 ID
  String _deviceId = '';

  /// 本机设备名称
  String _deviceName = '';

  /// 预期的访问令牌（从持久化存储加载）
  String _expectedToken = '';

  /// 构造函数
  ///
  /// [port] 服务器端口，默认 19191
  /// [address] 监听地址，默认 '0.0.0.0'（接受所有连接）
  /// [collector] 系统信息采集器，默认使用 WindowsCollector
  ServerService({
    this.port = NetworkConstants.defaultHttpPort,
    this.address = '0.0.0.0',
    SystemInfoCollector? collector,
  }) : _collector = collector ?? WindowsCollector();

  /// 服务器是否正在运行
  bool get isRunning => _isRunning;

  /// 启动 HTTP 服务器
  ///
  /// [deviceId] 本机设备唯一标识
  /// [deviceName] 本机设备显示名称
  /// 返回是否启动成功
  Future<bool> start({
    required String deviceId,
    required String deviceName,
  }) async {
    if (_isRunning) return true;

    try {
      _deviceId = deviceId;
      _deviceName = deviceName;
      _expectedToken = await loadAccessToken();

      // 启动 HTTP 服务器
      _server = await shelf_io.serve(
        _handleRequest,
        address,
        port,
      );

      // 启动系统信息采集（后台缓存最新数据）
      _collector.startPeriodicCollection();

      _isRunning = true;

      debugPrint('[ServerService] HTTP 服务已启动: http://$address:$port');
      debugPrint('[ServerService] 设备 ID: $_deviceId');
      return true;
    } catch (e) {
      debugPrint('[ServerService] 启动失败: $e');
      return false;
    }
  }

  /// 停止 HTTP 服务器
  ///
  /// 停止采集并关闭服务器。
  Future<void> stop() async {
    if (!_isRunning) return;

    _collector.stopPeriodicCollection();

    await _server?.close(force: true);
    _server = null;

    _isRunning = false;
    debugPrint('[ServerService] HTTP 服务已停止');
  }

  /// HTTP 请求处理器
  Future<Response> _handleRequest(Request request) async {
    final cors = Map<String, String>.from(_corsHeaders);

    // CORS 预检请求
    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: cors);
    }

    // 健康检查
    if (request.url.path == 'health') {
      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {..._jsonHeaders, ...cors},
      );
    }

    // 系统信息 API: GET /{deviceId}/{accessToken}
    final segments = request.url.pathSegments;
    if (request.method == 'GET' && segments.length == 2) {
      final reqDeviceId = segments[0];
      final reqToken = segments[1];

      if (reqDeviceId != _deviceId || reqToken != _expectedToken) {
        return Response.forbidden(
          jsonEncode({'error': 'Forbidden: invalid device ID or access token'}),
          headers: {..._jsonHeaders, ...cors},
        );
      }

      // 采集系统信息并返回 JSON
      try {
        final info = await _collector.collectAll();
        final responseJson = {
          'deviceId': _deviceId,
          'deviceName': _deviceName,
          ...info.toJson(),
        };

        return Response.ok(
          jsonEncode(responseJson),
          headers: {..._jsonHeaders, ...cors},
        );
      } catch (e) {
        debugPrint('[ServerService] 采集失败: $e');
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to collect system info'}),
          headers: {..._jsonHeaders, ...cors},
        );
      }
    }

    // 未匹配的路由
    return Response.notFound(
      jsonEncode({'error': 'Not Found'}),
      headers: {..._jsonHeaders, ...cors},
    );
  }

  /// 释放资源
  ///
  /// 停止服务器并清理所有资源。
  Future<void> dispose() async {
    await stop();
    _collector.dispose();
  }
}
