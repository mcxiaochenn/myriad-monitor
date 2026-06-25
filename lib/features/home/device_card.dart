import 'package:flutter/material.dart';
import '../../core/models/device_info.dart';

/// 设备卡片组件
///
/// 展示单个设备的基本信息，包括设备名称、操作系统、IP 地址，
/// 以及右上角的状态指示灯（在线/离线）。
///
/// 使用 [Card] 组件并预留高斯模糊背景位置（通过 [ClipRRect] + [BackdropFilter]）。
/// 点击卡片时通过 [onTap] 回调通知父组件导航。
class DeviceCard extends StatelessWidget {
  /// 要展示的设备信息
  final DeviceInfo device;

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
      // 预留高斯模糊背景：实际背景图由父组件或后续状态数据提供
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        // 高斯模糊背景层 —— 当前使用纯色占位，后续可替换为设备截图或渐变
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
        _getOsIcon(),
        size: 28,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// 根据操作系统类型返回对应图标
  IconData _getOsIcon() {
    switch (device.osType) {
      case DeviceOsType.windows:
        return Icons.computer;
      case DeviceOsType.macos:
        return Icons.laptop_mac;
      case DeviceOsType.linux:
        return Icons.terminal;
      case DeviceOsType.unknown:
        return Icons.devices_other;
    }
  }

  /// 构建设备信息区域（名称、操作系统、IP）
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
        // 操作系统
        Text(
          device.osType.displayName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // IP 地址
        Text(
          device.ipAddress,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
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
                      color: dotColor.withOpacity(0.6),
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
          device.status.displayName,
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
