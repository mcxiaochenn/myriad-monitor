import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// 连接状态枚举
enum ConnectionStatus {
  /// 未连接
  disconnected,

  /// 正在连接中
  connecting,

  /// 已连接（正在轮询）
  connected,

  /// 连接出错
  error,
}

/// 磁盘信息数据
class DiskInfoData {
  /// 磁盘挂载点
  final String mountPoint;

  /// 磁盘文件系统类型
  final String fileSystem;

  /// 磁盘总容量（字节）
  final int totalSpace;

  /// 已使用空间（字节）
  final int usedSpace;

  /// 可用空间（字节）
  final int freeSpace;

  /// 使用率（百分比，0-100）
  final double usage;

  const DiskInfoData({
    required this.mountPoint,
    required this.fileSystem,
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
    required this.usage,
  });

  /// 从 JSON 构造
  factory DiskInfoData.fromJson(Map<String, dynamic> json) {
    return DiskInfoData(
      mountPoint: json['mountPoint'] as String? ?? '',
      fileSystem: json['fileSystem'] as String? ?? '',
      totalSpace: json['totalSpace'] as int? ?? 0,
      usedSpace: json['usedSpace'] as int? ?? 0,
      freeSpace: json['freeSpace'] as int? ?? 0,
      usage: (json['usage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// 系统信息数据模型
///
/// 表示从远程设备 HTTP API 获取的系统信息快照。
/// 包含设备标识、CPU/内存/磁盘/网络等核心指标。
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

  /// 内存使用率（百分比 0~100）
  final double memoryUsage;

  /// 磁盘信息列表
  final List<DiskInfoData> disks;

  /// 网络上传速度（字节/秒）
  final double uploadSpeed;

  /// 网络下载速度（字节/秒）
  final double downloadSpeed;

  /// 数据采集时间戳
  final DateTime timestamp;

  const SystemInfoData({
    required this.deviceId,
    required this.deviceName,
    required this.cpuUsage,
    required this.memoryUsed,
    required this.memoryTotal,
    required this.memoryUsage,
    required this.disks,
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.timestamp,
  });

  /// 磁盘总使用率（取首个磁盘）
  double get diskUsage =>
      disks.isNotEmpty ? disks.first.usage : 0.0;

  /// 网络上传速度（兼容旧字段名）
  double get networkUpload => uploadSpeed;

  /// 网络下载速度（兼容旧字段名）
  double get networkDownload => downloadSpeed;

  /// 从 HTTP API 响应的 JSON 构造实例
  factory SystemInfoData.fromJson(Map<String, dynamic> json) {
    // 解析磁盘列表
    final disksJson = json['disks'] as List<dynamic>?;
    final diskList = disksJson != null
        ? disksJson
            .map((d) => DiskInfoData.fromJson(d as Map<String, dynamic>))
            .toList()
        : <DiskInfoData>[];

    // 解析网络流量（兼容嵌套 networkTraffic 和扁平格式）
    Map<String, dynamic>? networkJson;
    if (json['networkTraffic'] is Map<String, dynamic>) {
      networkJson = json['networkTraffic'] as Map<String, dynamic>;
    }

    return SystemInfoData(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      cpuUsage: (json['cpuUsage'] as num?)?.toDouble() ?? 0.0,
      memoryUsed: json['memoryUsed'] as int? ?? 0,
      memoryTotal: json['memoryTotal'] as int? ?? 0,
      memoryUsage: (json['memoryUsage'] as num?)?.toDouble() ?? 0.0,
      disks: diskList,
      uploadSpeed:
          (networkJson?['uploadSpeed'] ?? json['uploadSpeed'] as num?)?.toDouble() ?? 0.0,
      downloadSpeed:
          (networkJson?['downloadSpeed'] ?? json['downloadSpeed'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// HTTP 轮询客户端服务
///
/// 通过周期性 HTTP GET 请求拉取远程设备的系统信息。
/// 替代原先的 WebSocket 推送模式。
class ClientService {
  /// 远程设备 HTTP API 地址
  /// 格式: http://ip:port/deviceId/accessToken
  final String serverUrl;

  /// HTTP 客户端
  HttpClient? _httpClient;

  /// 轮询定时器
  Timer? _pollTimer;

  /// 当前连接状态
  ConnectionStatus _status = ConnectionStatus.disconnected;

  /// 当前重试次数
  int _retryCount = 0;

  /// 连接状态变化控制器
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  /// 系统信息数据控制器
  final _dataController = StreamController<SystemInfoData>.broadcast();

  /// 错误信息控制器
  final _errorController = StreamController<String>.broadcast();

  /// 构造函数
  ///
  /// [serverUrl] - HTTP API 地址
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

  /// 启动 HTTP 轮询
  ///
  /// 立即执行一次拉取，之后按固定间隔轮询。
  Future<void> connect() async {
    if (_status == ConnectionStatus.connected) return;

    _updateStatus(ConnectionStatus.connecting);
    _retryCount = 0;
    _httpClient = HttpClient();
    _httpClient!.connectionTimeout =
        const Duration(seconds: NetworkConstants.connectionTimeoutSeconds);

    // 立即执行第一次拉取
    final success = await _fetchData();

    if (success) {
      _updateStatus(ConnectionStatus.connected);
      _retryCount = 0;
      _startPolling();
      debugPrint('[ClientService] 已连接到 $serverUrl');
    } else {
      _updateStatus(ConnectionStatus.error);
      debugPrint('[ClientService] 初始化连接失败: $serverUrl');
    }
  }

  /// 断开连接
  ///
  /// 停止轮询并关闭 HTTP 客户端。
  void disconnect() {
    _stopPolling();

    _httpClient?.close(force: true);
    _httpClient = null;

    _updateStatus(ConnectionStatus.disconnected);
    _retryCount = 0;

    debugPrint('[ClientService] 已断开连接');
  }

  // ---------------------------------------------------------------------------
  // 数据拉取
  // ---------------------------------------------------------------------------

  /// 执行一次 HTTP GET 拉取
  Future<bool> _fetchData() async {
    final client = _httpClient;
    if (client == null) return false;

    try {
      final uri = Uri.parse(serverUrl);
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      final response = await request.close().timeout(
            const Duration(seconds: NetworkConstants.connectionTimeoutSeconds),
          );

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final info = SystemInfoData.fromJson(json);
        _dataController.add(info);
        return true;
      } else if (response.statusCode == 403) {
        _errorController.add('访问被拒绝：无效的设备 ID 或访问令牌');
      } else {
        _errorController.add('HTTP ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('[ClientService] 请求超时');
    } on SocketException catch (e) {
      debugPrint('[ClientService] 网络错误: $e');
    } catch (e) {
      debugPrint('[ClientService] 拉取失败: $e');
      _errorController.add('拉取失败: $e');
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // 轮询机制
  // ---------------------------------------------------------------------------

  /// 启动轮询定时器
  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(
      const Duration(seconds: NetworkConstants.pollingIntervalSeconds),
      (_) async {
        final success = await _fetchData();
        if (!success) {
          _retryCount++;
          if (_retryCount >= NetworkConstants.maxRetryAttempts) {
            debugPrint('[ClientService] 连续失败 $_retryCount 次，标记为错误');
            _updateStatus(ConnectionStatus.error);
            _stopPolling();
          }
        } else {
          _retryCount = 0;
        }
      },
    );
  }

  /// 停止轮询定时器
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ---------------------------------------------------------------------------
  // 工具方法
  // ---------------------------------------------------------------------------

  /// 更新连接状态并通知监听者
  void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  /// 释放所有资源
  ///
  /// 应在服务不再需要时调用，确保所有流和定时器被正确关闭。
  Future<void> dispose() async {
    disconnect();

    await _statusController.close();
    await _dataController.close();
    await _errorController.close();
  }
}
