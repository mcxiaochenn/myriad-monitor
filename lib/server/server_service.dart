import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'system_info_collector.dart';

/// WebSocket 服务器服务
///
/// 提供 WebSocket 服务器功能，支持：
/// - 启动/停止 WebSocket 服务器
/// - 监听客户端连接
/// - 定时推送系统信息数据
class ServerService {
  /// 服务器监听端口
  final int port;

  /// 服务器监听地址
  final String address;

  /// 系统信息采集器
  final SystemInfoCollector _collector;

  /// HTTP 服务器实例
  dynamic _server;

  /// 已连接的 WebSocket 客户端集合
  final Set<WebSocketChannel> _connectedClients = {};

  /// 服务器运行状态
  bool _isRunning = false;

  /// 数据推送定时器
  Timer? _pushTimer;

  /// 数据推送间隔（默认 1 秒）
  final Duration pushInterval;

  /// 构造函数
  ///
  /// [port] 服务器端口，默认 8080
  /// [address] 监听地址，默认 '0.0.0.0'（接受所有连接）
  /// [pushInterval] 数据推送间隔，默认 1 秒
  ServerService({
    this.port = 8080,
    this.address = '0.0.0.0',
    this.pushInterval = const Duration(seconds: 1),
  }) : _collector = SystemInfoCollector();

  /// 服务器是否正在运行
  bool get isRunning => _isRunning;

  /// 当前已连接的客户端数量
  int get clientCount => _connectedClients.length;

  /// 启动 WebSocket 服务器
  ///
  /// 创建 WebSocket 处理器并绑定到指定端口
  /// 返回是否启动成功
  Future<bool> start() async {
    if (_isRunning) {
      return true;
    }

    try {
      // TODO: 创建 WebSocket 处理器
      // 处理客户端连接、断开、消息接收等事件
      final handler = webSocketHandler((WebSocketChannel webSocket) {
        _onClientConnected(webSocket);
      });

      // TODO: 使用 shelf 启动 HTTP 服务器
      // _server = await shelf_io.serve(
      //   handler,
      //   address,
      //   port,
      // );

      _isRunning = true;

      // 启动系统信息采集
      _collector.startPeriodicCollection();

      // 启动数据推送
      _startPushingData();

      return true;
    } catch (e) {
      // 启动失败，记录错误
      return false;
    }
  }

  /// 停止 WebSocket 服务器
  ///
  /// 关闭所有客户端连接并停止服务器
  Future<void> stop() async {
    if (!_isRunning) {
      return;
    }

    // 停止数据推送
    _stopPushingData();

    // 停止系统信息采集
    _collector.stopPeriodicCollection();

    // 关闭所有客户端连接
    _disconnectAllClients();

    // 关闭 HTTP 服务器
    // await _server?.close(force: true);
    _server = null;

    _isRunning = false;
  }

  /// 处理客户端连接
  ///
  /// [webSocket] 新连接的 WebSocket 通道
  void _onClientConnected(WebSocketChannel webSocket) {
    // 将客户端添加到已连接集合
    _connectedClients.add(webSocket);

    // 监听客户端消息
    webSocket.stream.listen(
      (message) {
        _onClientMessage(webSocket, message);
      },
      onDone: () {
        // 客户端断开连接
        _onClientDisconnected(webSocket);
      },
      onError: (error) {
        // 连接错误，移除客户端
        _onClientDisconnected(webSocket);
      },
    );

    // 发送欢迎消息
    _sendToClient(webSocket, {
      'type': 'connected',
      'message': '已连接到 Myriad Monitor 服务器',
    });
  }

  /// 处理客户端断开连接
  ///
  /// [webSocket] 断开的 WebSocket 通道
  void _onClientDisconnected(WebSocketChannel webSocket) {
    _connectedClients.remove(webSocket);
  }

  /// 处理客户端消息
  ///
  /// [webSocket] 发送消息的客户端
  /// [message] 接收到的消息内容
  void _onClientMessage(WebSocketChannel webSocket, dynamic message) {
    // TODO: 解析并处理客户端请求
    // 例如：订阅特定监控项、请求历史数据等
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String?;

      switch (type) {
        case 'subscribe':
          // TODO: 处理订阅请求
          break;
        case 'unsubscribe':
          // TODO: 处理取消订阅请求
          break;
        case 'request':
          // TODO: 处理数据请求
          break;
        default:
          // 未知消息类型
          break;
      }
    } catch (e) {
      // 消息解析失败
    }
  }

  /// 启动数据推送定时器
  void _startPushingData() {
    _stopPushingData();

    _pushTimer = Timer.periodic(pushInterval, (_) async {
      await _pushSystemInfo();
    });
  }

  /// 停止数据推送定时器
  void _stopPushingData() {
    _pushTimer?.cancel();
    _pushTimer = null;
  }

  /// 推送系统信息到所有客户端
  Future<void> _pushSystemInfo() async {
    if (_connectedClients.isEmpty) {
      return;
    }

    try {
      // 采集系统信息
      final info = await _collector.collectAll();

      // 构造推送消息
      final message = {
        'type': 'systemInfo',
        'data': info.toJson(),
      };

      // 广播给所有客户端
      broadcastMessage(message);
    } catch (e) {
      // 采集或推送失败
    }
  }

  /// 向单个客户端发送消息
  ///
  /// [webSocket] 目标客户端
  /// [data] 要发送的数据（会被 JSON 编码）
  void _sendToClient(WebSocketChannel webSocket, Map<String, dynamic> data) {
    try {
      webSocket.sink.add(jsonEncode(data));
    } catch (e) {
      // 发送失败，移除客户端
      _onClientDisconnected(webSocket);
    }
  }

  /// 广播消息给所有已连接的客户端
  ///
  /// [data] 要广播的数据（会被 JSON 编码）
  void broadcastMessage(Map<String, dynamic> data) {
    final message = jsonEncode(data);

    // 遍历所有客户端并发送
    // 使用 toList() 避免在遍历时修改集合
    for (final client in _connectedClients.toList()) {
      try {
        client.sink.add(message);
      } catch (e) {
        // 发送失败，移除客户端
        _onClientDisconnected(client);
      }
    }
  }

  /// 断开所有客户端连接
  void _disconnectAllClients() {
    for (final client in _connectedClients.toList()) {
      try {
        client.sink.close();
      } catch (e) {
        // 关闭失败，忽略
      }
    }
    _connectedClients.clear();
  }

  /// 释放资源
  ///
  /// 停止服务器并清理所有资源
  Future<void> dispose() async {
    await stop();
    _collector.dispose();
  }
}
