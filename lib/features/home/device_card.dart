import 'package:flutter/material.dart';
import '../../client/device_manager.dart';

/// 设备卡片组件
///
/// 展示单个设备的基本信息，包括设备名称、IP 地址，
/// 以及右上角的状态指示灯（在线/离线）。
///
/// 使用 [Card] 组件，点击卡片时通过 [onTap] 回调通知父组件导航。
class DeviceCard extends StatelessWidget {
  /// 要展示的设备信息
  final ManagedDevice device;

  /// 点击卡片时的回调
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainerHigh,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左侧：设备图标
                _buildDeviceIcon(colorScheme),
                const SizedBox(width: 16),
                // 中间：设备信息
                Expanded(child: _buildDeviceInfo(theme)),
                // 右侧：状态指示灯
                _buildStatusIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建设备图标区域
  Widget _buildDeviceIcon(ColorScheme colorScheme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getDeviceIcon(),
        size: 28,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// 根据设备名称或 IP 返回对应图标
  IconData _getDeviceIcon() {
    // 根据设备名称推断类型
    final name = device.name.toLowerCase();
    if (name.contains('server') || name.contains('服务器')) {
      return Icons.dns;
    } else if (name.contains('laptop') || name.contains('笔记本')) {
      return Icons.laptop;
    } else if (name.contains('desktop') || name.contains('台式机')) {
      return Icons.desktop_windows;
    } else if (name.contains('phone') || name.contains('手机')) {
      return Icons.phone_android;
    } else if (name.contains('tablet') || name.contains('平板')) {
      return Icons.tablet;
    }
    return Icons.computer;
  }

  /// 构建设备信息区域（名称、IP、最后在线时间）
  Widget _buildDeviceInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 设备名称
        Text(
          device.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // IP 地址
        Text(
          device.ipAddress,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // 最后在线时间
        if (device.lastSeenAt != null)
          Text(
            '最后在线: ${_formatLastSeen(device.lastSeenAt!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  /// 格式化最后在线时间
  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}秒前';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }

  /// 构建状态指示灯
  ///
  /// 在线时显示绿色脉冲圆点，离线时显示灰色圆点。
  Widget _buildStatusIndicator() {
    final isOnline = device.isOnline;
    final dotColor = isOnline ? Colors.greenAccent : Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 状态圆点
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            // 在线时添加发光效果
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        // 状态文字
        Text(
          isOnline ? '在线' : '离线',
          style: TextStyle(
            fontSize: 11,
            color: dotColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
