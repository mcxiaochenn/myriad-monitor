import 'dart:async';
import 'package:flutter/material.dart';
import '../../client/client_service.dart';
import '../../client/device_manager.dart';
import '../../l10n/app_localizations.dart';
import 'chart_widget.dart';

/// 设备详情页
///
/// 接收 [ManagedDevice]，创建 [ClientService] 通过 HTTP 轮询拉取
/// 真实的系统监控数据，替代原先的模拟数据。
class DeviceDetailPage extends StatefulWidget {
  final ManagedDevice device;

  const DeviceDetailPage({super.key, required this.device});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  ClientService? _client;
  StreamSubscription? _dataSub;
  StreamSubscription? _statusSub;
  SystemInfoData? _latestData;
  ConnectionStatus _connectionStatus = ConnectionStatus.connecting;
  String? _errorMessage;
  final List<double> _cpuHistory = [];
  final List<double> _uploadHistory = [];
  final List<double> _downloadHistory = [];
  static const int _maxHistory = 30;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _statusSub?.cancel();
    _client?.disconnect();
    super.dispose();
  }

  void _connect() {
    final url = widget.device.httpUrl;
    if (url.isEmpty) {
      setState(() {
        _connectionStatus = ConnectionStatus.error;
        _errorMessage = AppLocalizations.of(context).deviceInfoIncomplete;
      });
      return;
    }

    _client?.disconnect();
    _dataSub?.cancel();
    _statusSub?.cancel();

    _client = ClientService(serverUrl: url);

    _statusSub = _client!.statusStream.listen((status) {
      if (mounted) setState(() => _connectionStatus = status);
    });

    _dataSub = _client!.dataStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _latestData = data;
        _connectionStatus = ConnectionStatus.connected;
        _cpuHistory.add(data.cpuUsage);
        _uploadHistory.add(data.uploadSpeed.toDouble());
        _downloadHistory.add(data.downloadSpeed.toDouble());
        if (_cpuHistory.length > _maxHistory) _cpuHistory.removeAt(0);
        if (_uploadHistory.length > _maxHistory) _uploadHistory.removeAt(0);
        if (_downloadHistory.length > _maxHistory) _downloadHistory.removeAt(0);
      });
    });

    _client!.connect();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatSpeed(double bps) {
    if (bps < 1024) return '${bps.toStringAsFixed(1)} B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  Color get _statusColor => switch (_connectionStatus) {
    ConnectionStatus.connected => Colors.green,
    ConnectionStatus.connecting => Colors.orange,
    _ => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final cpuData = _cpuHistory.isNotEmpty ? _cpuHistory : List.filled(_maxHistory, 0.0);
    final uploadData = _uploadHistory.isNotEmpty ? _uploadHistory : List.filled(_maxHistory, 0.0);
    final downloadData = _downloadHistory.isNotEmpty ? _downloadHistory : List.filled(_maxHistory, 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          Center(
            child: Container(
              width: 10, height: 10, margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
      body: _buildBody(theme, l10n, cpuData, uploadData, downloadData),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n,
      List<double> cpu, List<double> up, List<double> down) {
    if (_connectionStatus == ConnectionStatus.connecting && _latestData == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(), const SizedBox(height: 16), Text(l10n.connectingDevice),
      ]));
    }
    if (_connectionStatus == ConnectionStatus.error && _latestData == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(_errorMessage ?? l10n.connectionFailed, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () { setState(() { _connectionStatus = ConnectionStatus.connecting; _errorMessage = null; }); _connect(); }, child: Text(l10n.retry)),
      ]));
    }

    final d = _latestData;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      _infoCard(theme, l10n, d), const SizedBox(height: 12),
      _cpuCard(theme, l10n, cpu, d), const SizedBox(height: 12),
      _memCard(theme, l10n, d), const SizedBox(height: 12),
      _diskCard(theme, l10n, d), const SizedBox(height: 12),
      _netCard(theme, l10n, up, down, d),
    ]));
  }

  // ── 设备信息 ──
  Widget _infoCard(ThemeData t, AppLocalizations l, SystemInfoData? d) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.computer, color: t.colorScheme.primary), const SizedBox(width: 8), Text(l.detailDeviceInfo, style: t.textTheme.titleMedium)]),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _infoItem(t, Icons.badge, l.detailHostName, d?.deviceName ?? widget.device.name),
        _infoItem(t, Icons.laptop_windows, l.detailOs, widget.device.ipAddress),
        _infoItem(t, Icons.schedule, l.detailUptime, d != null ? _formatTime(d.timestamp) : '--'),
      ]),
    ])),
  );

  Widget _infoItem(ThemeData t, IconData ic, String label, String v) => Column(children: [
    Icon(ic, size: 28, color: t.colorScheme.primary), const SizedBox(height: 6),
    Text(label, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
    const SizedBox(height: 4),
    Text(v, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
  ]);

  // ── CPU ──
  Widget _cpuCard(ThemeData t, AppLocalizations l, List<double> data, SystemInfoData? d) {
    final cur = d?.cpuUsage ?? 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.memory, color: t.colorScheme.primary), const SizedBox(width: 8),
          Text(l.detailCpuUsage, style: t.textTheme.titleMedium),
          const Spacer(),
          Text('${cur.toStringAsFixed(1)}%', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        RealtimeLineChart(dataPoints: data, title: l.detailCpuUsage, unit: '%', lineColor: Colors.green, maxY: 100, minY: 0, height: 180, intervalSeconds: 1),
      ])),
    );
  }

  // ── 内存 ──
  Widget _memCard(ThemeData t, AppLocalizations l, SystemInfoData? d) {
    final used = d?.memoryUsed ?? 0; final total = d?.memoryTotal ?? 0;
    final usage = total > 0 ? used / total : 0.0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.storage, color: t.colorScheme.primary), const SizedBox(width: 8), Text(l.detailMemory, style: t.textTheme.titleMedium)]),
        const SizedBox(height: 16),
        Text(l.detailMemoryUsage(_formatBytes(used), _formatBytes(total)), style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: usage, minHeight: 10, backgroundColor: t.colorScheme.surfaceContainerHighest, valueColor: AlwaysStoppedAnimation(usage > 0.8 ? Colors.red : Colors.blue))),
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerRight, child: Text('${(usage * 100).toStringAsFixed(0)}%', style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant))),
      ])),
    );
  }

  // ── 磁盘 ──
  Widget _diskCard(ThemeData t, AppLocalizations l, SystemInfoData? d) {
    final disks = d?.disks ?? [];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.disc_full, color: t.colorScheme.primary), const SizedBox(width: 8), Text(l.detailDisk, style: t.textTheme.titleMedium)]),
        const SizedBox(height: 16),
        if (disks.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Center(child: Text(l.detailWaitingForData, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))))
        else ...disks.map((disk) {
          final u = disk.totalSpace > 0 ? disk.usedSpace / disk.totalSpace : 0.0;
          return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${disk.mountPoint}  ${disk.fileSystem}', style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text('${(u * 100).toStringAsFixed(0)}%', style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: u, minHeight: 8, backgroundColor: t.colorScheme.surfaceContainerHighest, valueColor: AlwaysStoppedAnimation(u > 0.9 ? Colors.red : Colors.blue))),
            const SizedBox(height: 4),
            Text(l.usedOf(_formatBytes(disk.usedSpace), _formatBytes(disk.totalSpace)), style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]));
        }),
      ])),
    );
  }

  // ── 网络 ──
  Widget _netCard(ThemeData t, AppLocalizations l, List<double> up, List<double> down, SystemInfoData? d) {
    final us = d?.uploadSpeed ?? 0; final ds = d?.downloadSpeed ?? 0;
    final upMax = (up.isNotEmpty ? (up.reduce((a, b) => a > b ? a : b) * 1.2).clamp(50.0, 10000.0) : 50.0).toDouble();
    final downMax = (down.isNotEmpty ? (down.reduce((a, b) => a > b ? a : b) * 1.2).clamp(50.0, 10000.0) : 100.0).toDouble();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.wifi, color: t.colorScheme.primary), const SizedBox(width: 8), Text(l.detailNetwork, style: t.textTheme.titleMedium)]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [Text(l.detailUploadSpeed, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)), const SizedBox(height: 4), Text(_formatSpeed(us.toDouble()), style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.orange))]),
          Column(children: [Text(l.detailDownloadSpeed, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)), const SizedBox(height: 4), Text(_formatSpeed(ds.toDouble()), style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.cyan))]),
        ]),
        const SizedBox(height: 16),
        RealtimeLineChart(dataPoints: up, title: l.detailUploadSpeed, unit: 'B/s', lineColor: Colors.orange, maxY: upMax, minY: 0, height: 140, intervalSeconds: 1),
        const SizedBox(height: 16),
        RealtimeLineChart(dataPoints: down, title: l.detailDownloadSpeed, unit: 'B/s', lineColor: Colors.cyan, maxY: downMax, minY: 0, height: 140, intervalSeconds: 1),
      ])),
    );
  }
}
