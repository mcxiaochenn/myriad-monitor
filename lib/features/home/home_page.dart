import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../client/device_manager.dart';
import '../../core/discovery/discovery_message.dart';
import '../../core/discovery/udp_discovery.dart';
import '../../core/discovery/discovery_integration.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_page.dart';
import '../detail/detail_page.dart';
import 'device_card.dart';
import 'scan_page.dart';

final deviceManagerProvider = Provider<DeviceManager>((ref) {
  final manager = DeviceManager();
  manager.loadDevices();
  manager.startOfflineDetection();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final discoveryIntegrationProvider = Provider<DiscoveryIntegration>((ref) {
  final deviceManager = ref.read(deviceManagerProvider);
  final config = ref.read(serverConfigProvider);
  final discoveryService = UdpDiscoveryService(deviceName: config.deviceName, servicePort: config.port);
  final integration = DiscoveryIntegration(discoveryService: discoveryService, deviceManager: deviceManager);
  integration.start();
  ref.onDispose(() { discoveryService.dispose(); integration.dispose(); });
  return integration;
});

enum SortType { time, name, status, ip }
enum SortDirection { ascending, descending }

final sortStateProvider = StateProvider<SortState>((ref) => SortState());

class SortState {
  final SortType type; final SortDirection direction;
  SortState({this.type = SortType.time, this.direction = SortDirection.descending});
  SortState copyWith({SortType? type, SortDirection? direction}) => SortState(type: type ?? this.type, direction: direction ?? this.direction);
}

final deviceListProvider = StateNotifierProvider<DeviceListNotifier, List<ManagedDevice>>((ref) {
  final manager = ref.watch(deviceManagerProvider);
  return DeviceListNotifier(manager);
});

class DeviceListNotifier extends StateNotifier<List<ManagedDevice>> {
  final DeviceManager _manager;
  final List<StreamSubscription> _subs = [];
  DeviceListNotifier(this._manager) : super(_manager.devices) {
    _subs.add(_manager.devicesChangedStream.listen((devices) { state = List.unmodifiable(devices); }));
    _subs.add(_manager.deviceStatusStream.listen((_) { state = List.unmodifiable(_manager.devices); }));
  }
  void addDevice(ManagedDevice d) { _manager.addDevice(d); state = List.unmodifiable(_manager.devices); }
  void removeDevice(String id) { _manager.removeDevice(id); state = List.unmodifiable(_manager.devices); }
  @override void dispose() { for (final s in _subs) { s.cancel(); } super.dispose(); }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceListProvider);
    final sortState = ref.watch(sortStateProvider);
    final l10n = AppLocalizations.of(context);
    final sorted = _sort(devices, sortState);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deviceList), centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: () => _showSort(context, ref, l10n), tooltip: l10n.sortDevices),
          PopupMenuButton<String>(icon: const Icon(Icons.add_circle_outline), tooltip: l10n.addDevice, onSelected: (v) {
            switch (v) {
              case 'add': _showAdd(context, ref, l10n);
              case 'scan': _scan(context, ref, l10n);
              case 'discover': _showDiscover(context, ref, l10n);
            }
          }, itemBuilder: (ctx) => [
            PopupMenuItem(value: 'add', child: ListTile(leading: const Icon(Icons.add), title: Text(l10n.addDevice), subtitle: Text(l10n.addDeviceDesc), contentPadding: EdgeInsets.zero)),
            PopupMenuItem(value: 'scan', child: ListTile(leading: const Icon(Icons.qr_code_scanner), title: Text(l10n.scanAddDevice), subtitle: Text(l10n.scanAddDeviceDesc), contentPadding: EdgeInsets.zero)),
            PopupMenuItem(value: 'discover', child: ListTile(leading: const Icon(Icons.search), title: Text(l10n.discoverDevice), subtitle: Text(l10n.discoverDeviceDesc), contentPadding: EdgeInsets.zero)),
          ]),
        ],
      ),
      body: Stack(children: [_blurBg(context), _deviceList(context, ref, sorted, l10n)]),
    );
  }

  List<ManagedDevice> _sort(List<ManagedDevice> list, SortState s) {
    final l = List<ManagedDevice>.from(list);
    final asc = s.direction == SortDirection.ascending;
    switch (s.type) {
      case SortType.time: l.sort((a, b) => asc ? a.discoveredAt.compareTo(b.discoveredAt) : b.discoveredAt.compareTo(a.discoveredAt));
      case SortType.name: l.sort((a, b) => asc ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
      case SortType.status: l.sort((a, b) => asc ? (a.isOnline ? 0 : 1).compareTo(b.isOnline ? 0 : 1) : (b.isOnline ? 0 : 1).compareTo(a.isOnline ? 0 : 1));
      case SortType.ip: l.sort((a, b) => asc ? a.ipAddress.compareTo(b.ipAddress) : b.ipAddress.compareTo(a.ipAddress));
    }
    return l;
  }

  void _showSort(BuildContext ctx, WidgetRef ref, AppLocalizations l10n) {
    final s = ref.read(sortStateProvider);
    showDialog(context: ctx, builder: (ctx) => AlertDialog(title: Text(l10n.sortDevices), content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(l10n.sortBy, style: Theme.of(ctx).textTheme.titleSmall), const SizedBox(height: 8),
      for (final t in [SortType.time, SortType.name, SortType.status, SortType.ip])
        RadioListTile<SortType>(title: Text(_name(t, l10n)), value: t, groupValue: s.type, onChanged: (v) { if (v != null) { ref.read(sortStateProvider.notifier).state = s.copyWith(type: v); Navigator.pop(ctx); } }),
      const Divider(), Text(l10n.sortDirection, style: Theme.of(ctx).textTheme.titleSmall), const SizedBox(height: 8),
      RadioListTile<SortDirection>(title: Text(l10n.ascending), value: SortDirection.ascending, groupValue: s.direction, onChanged: (v) { if (v != null) { ref.read(sortStateProvider.notifier).state = s.copyWith(direction: v); Navigator.pop(ctx); } }),
      RadioListTile<SortDirection>(title: Text(l10n.descending), value: SortDirection.descending, groupValue: s.direction, onChanged: (v) { if (v != null) { ref.read(sortStateProvider.notifier).state = s.copyWith(direction: v); Navigator.pop(ctx); } }),
    ])));
  }

  String _name(SortType t, AppLocalizations l) => switch (t) { SortType.time => l.sortByTime, SortType.name => l.sortByName, SortType.status => l.sortByStatus, SortType.ip => l.sortByIp };

  void _scan(BuildContext ctx, WidgetRef ref, AppLocalizations l10n) {
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => ScanPage(onDeviceFound: (device) {
      ref.read(deviceListProvider.notifier).addDevice(device);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.deviceAdded(device.name)), behavior: SnackBarBehavior.floating));
    })));
  }

  void _showAdd(BuildContext ctx, WidgetRef ref, AppLocalizations l10n) {
    final cfg = ref.read(serverConfigProvider);
    showDialog(context: ctx, builder: (c) => _AddDeviceDialog(defaultPort: cfg.port,
      onAdd: (d) { ref.read(deviceListProvider.notifier).addDevice(d); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.deviceAdded(d.name)), behavior: SnackBarBehavior.floating)); },
      l10n: l10n,
    ));
  }

  void _showDiscover(BuildContext ctx, WidgetRef ref, AppLocalizations l10n) {
    final di = ref.read(discoveryIntegrationProvider);
    final existing = ref.read(deviceListProvider);
    showDialog(context: ctx, builder: (c) => _DiscoveredDevicesDialog(discoveryIntegration: di, existingDevices: existing,
      onAdd: (d) { ref.read(deviceListProvider.notifier).addDevice(d); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.deviceAdded(d.name)), behavior: SnackBarBehavior.floating)); },
      l10n: l10n,
    ));
  }

  Widget _blurBg(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [cs.primary.withValues(alpha: 0.1), cs.surface])))));
  }

  Widget _deviceList(BuildContext ctx, WidgetRef ref, List<ManagedDevice> devices, AppLocalizations l10n) {
    if (devices.isEmpty) return _empty(ctx, l10n);
    final online = devices.where((d) => d.isOnline).length;
    final s = ref.watch(sortStateProvider);
    return RefreshIndicator(onRefresh: () async { await Future<void>.delayed(const Duration(seconds: 1)); }, child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.device_hub, size: 18, color: Theme.of(ctx).colorScheme.onSurfaceVariant), const SizedBox(width: 8), Text(l10n.deviceCount(devices.length, online), style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant))]),
        const SizedBox(height: 4),
        Text('${l10n.currentSort}: ${_name(s.type, l10n)} ${s.direction == SortDirection.ascending ? '↑' : '↓'}', style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
      ]))),
      SliverList(delegate: SliverChildBuilderDelegate((_, i) => DeviceCard(device: devices[i], onTap: () => _toDetail(ctx, devices[i])), childCount: devices.length)),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]));
  }

  Widget _empty(BuildContext ctx, AppLocalizations l10n) {
    final cs = Theme.of(ctx).colorScheme;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.devices_other, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)), const SizedBox(height: 16),
      Text(l10n.noDeviceFound, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 8), Text(l10n.ensureSameNetwork, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
    ]));
  }

  void _toDetail(BuildContext ctx, ManagedDevice device) {
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => DeviceDetailPage(device: device)));
  }
}

/// 添加设备对话框（含令牌和连通性验证）
class _AddDeviceDialog extends StatefulWidget {
  final Function(ManagedDevice) onAdd; final AppLocalizations l10n; final int defaultPort;
  const _AddDeviceDialog({required this.onAdd, required this.l10n, required this.defaultPort});
  @override State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _fk = GlobalKey<FormState>();
  final _n = TextEditingController(), _ip = TextEditingController(), _port = TextEditingController(), _tok = TextEditingController();
  bool _vfy = false; String? _vr;

  @override void initState() { super.initState(); _port.text = widget.defaultPort.toString(); }
  @override void dispose() { _n.dispose(); _ip.dispose(); _port.dispose(); _tok.dispose(); super.dispose(); }

  Future<void> _verify() async {
    if (!_fk.currentState!.validate()) return;
    setState(() { _vfy = true; _vr = null; });
    final ip = _ip.text; final port = int.parse(_port.text); final tok = _tok.text;
    final client = HttpClient(); client.connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(Uri.parse('http://$ip:$port/health'));
      final resp = await req.close().timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        if (tok.isNotEmpty) {
          final r2 = await client.getUrl(Uri.parse('http://$ip:$port/_/$tok'));
          final resp2 = await r2.close().timeout(const Duration(seconds: 5));
          setState(() { _vr = resp2.statusCode == 200 ? '✅ 设备在线，令牌有效' : resp2.statusCode == 403 ? '⚠️ 设备在线但令牌无效' : '✅ 设备在线（状态码 ${resp2.statusCode}）'; _vfy = false; });
        } else { setState(() { _vr = '⚠️ 设备在线但未填写令牌（将无法获取数据）'; _vfy = false; }); }
      } else { setState(() { _vr = '❌ 设备无响应（${resp.statusCode}）'; _vfy = false; }); }
    } catch (e) { setState(() { _vr = '❌ 无法连接: $e'; _vfy = false; }); }
    finally { client.close(); }
  }

  @override
  Widget build(BuildContext ctx) => AlertDialog(
    title: Text(widget.l10n.addDevice),
    content: Form(key: _fk, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _n, decoration: InputDecoration(labelText: widget.l10n.deviceName, hintText: widget.l10n.deviceNameHint, prefixIcon: const Icon(Icons.devices)), validator: (v) => (v == null || v.isEmpty) ? widget.l10n.enterDeviceName : null),
      const SizedBox(height: 12),
      TextFormField(controller: _ip, decoration: InputDecoration(labelText: widget.l10n.ipAddress, hintText: widget.l10n.ipAddressHint, prefixIcon: const Icon(Icons.language)), keyboardType: TextInputType.url, validator: (v) { if (v == null || v.isEmpty) return widget.l10n.enterIpAddress; if (!RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(v)) return widget.l10n.invalidIpAddress; return null; }),
      const SizedBox(height: 12),
      TextFormField(controller: _port, decoration: InputDecoration(labelText: widget.l10n.port, hintText: widget.l10n.portHint, prefixIcon: const Icon(Icons.numbers)), keyboardType: TextInputType.number, validator: (v) { if (v == null || v.isEmpty) return widget.l10n.enterPort; final p = int.tryParse(v); if (p == null || p < 1 || p > 65535) return widget.l10n.invalidPort; return null; }),
      const SizedBox(height: 12),
      TextFormField(controller: _tok, decoration: InputDecoration(labelText: widget.l10n.accessTokenLabel, hintText: widget.l10n.accessTokenHint, prefixIcon: const Icon(Icons.key))),
      if (_vr != null) ...[const SizedBox(height: 12), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: Text(_vr!, style: const TextStyle(fontSize: 13)))],
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _vfy ? null : _verify, icon: _vfy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_find), label: Text(_vfy ? widget.l10n.verifying : widget.l10n.verifyConnection))),
    ]))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(widget.l10n.cancel)),
      FilledButton(onPressed: () {
        if (_fk.currentState!.validate()) {
          widget.onAdd(ManagedDevice(deviceId: const Uuid().v4(), name: _n.text, ipAddress: _ip.text, port: int.parse(_port.text), accessToken: _tok.text, onlineStatus: DeviceOnlineStatus.unknown, discoveredAt: DateTime.now()));
          Navigator.pop(ctx);
        }
      }, child: Text(widget.l10n.add)),
    ],
  );
}

/// 已发现设备对话框
class _DiscoveredDevicesDialog extends StatefulWidget {
  final DiscoveryIntegration discoveryIntegration; final List<ManagedDevice> existingDevices; final Function(ManagedDevice) onAdd; final AppLocalizations l10n;
  const _DiscoveredDevicesDialog({required this.discoveryIntegration, required this.existingDevices, required this.onAdd, required this.l10n});
  @override State<_DiscoveredDevicesDialog> createState() => _DiscoveredDevicesDialogState();
}

class _DiscoveredDevicesDialogState extends State<_DiscoveredDevicesDialog> {
  final List<DiscoveryMessage> _list = []; bool _scanning = false; StreamSubscription? _sub;
  @override void initState() { super.initState(); _start(); }
  @override void dispose() { _sub?.cancel(); super.dispose(); }
  void _start() { setState(() { _scanning = true; _list.clear(); }); _sub?.cancel(); _sub = widget.discoveryIntegration.onDeviceDiscovered.listen((m) { if (mounted && !_list.any((d) => d.deviceId == m.deviceId)) setState(() => _list.add(m)); }); Future.delayed(const Duration(seconds: 10), () { if (mounted) setState(() => _scanning = false); }); }
  bool _added(String id) => widget.existingDevices.any((d) => d.deviceId == id);

  @override
  Widget build(BuildContext ctx) => AlertDialog(
    title: Row(children: [Text(widget.l10n.discoverDevice), if (_scanning) ...[const SizedBox(width: 8), const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))]]),
    content: SizedBox(width: double.maxFinite, height: 300, child: _list.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search, size: 48, color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)), const SizedBox(height: 16),
      Text(_scanning ? widget.l10n.scanning : widget.l10n.noDevicesFound, style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
      if (!_scanning) ...[const SizedBox(height: 8), TextButton(onPressed: _start, child: Text(widget.l10n.scanAgain))],
    ])) : ListView.builder(itemCount: _list.length, itemBuilder: (_, i) {
      final d = _list[i]; final added = _added(d.deviceId);
      return ListTile(leading: Icon(Icons.devices, color: Theme.of(ctx).colorScheme.primary), title: Text(d.deviceName), subtitle: Text('${d.ip}:${d.port}'),
        trailing: added ? Chip(label: Text(widget.l10n.added), backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHighest) : FilledButton(onPressed: () {
          widget.onAdd(ManagedDevice(deviceId: d.deviceId, name: d.deviceName, ipAddress: d.ip, port: d.port, accessToken: '', onlineStatus: DeviceOnlineStatus.online, discoveredAt: DateTime.now(), lastSeenAt: DateTime.now()));
          Navigator.pop(ctx);
        }, child: Text(widget.l10n.add)));
    })),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(widget.l10n.close))],
  );
}
