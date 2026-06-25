import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'chart_widget.dart';

/// 设备详情页
/// 展示单台设备的实时监控数据，包括 CPU、内存、GPU、磁盘、网络等信息
class DeviceDetailPage extends StatelessWidget {
  /// 设备名称
  final String deviceName;

  /// 设备 IP 地址
  final String deviceIp;

  const DeviceDetailPage({
    super.key,
    required this.deviceName,
    required this.deviceIp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 生成演示用的模拟数据
    final cpuData = _generateDemoData(30, 10, 80);
    final uploadData = _generateDemoData(30, 0, 35);
    final downloadData = _generateDemoData(30, 5, 80);

    return Scaffold(
      // 应用栏：设备名称 + 返回按钮 + 状态指示灯
      appBar: AppBar(
        title: Text(deviceName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 绿色状态指示灯
          Center(
            child: Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== 设备信息卡片 =====
            _buildDeviceInfoCard(theme),
            const SizedBox(height: 12),

            // ===== CPU 使用率卡片 =====
            _buildCpuCard(theme, cpuData),
            const SizedBox(height: 12),

            // ===== 内存卡片 =====
            _buildMemoryCard(theme),
            const SizedBox(height: 12),

            // ===== GPU 卡片 =====
            _buildGpuCard(theme),
            const SizedBox(height: 12),

            // ===== 磁盘卡片 =====
            _buildDiskCard(theme),
            const SizedBox(height: 12),

            // ===== 网络卡片 =====
            _buildNetworkCard(theme, uploadData, downloadData),
          ],
        ),
      ),
    );
  }

  /// 生成模拟数据点
  List<double> _generateDemoData(int count, double min, double max) {
    final random = math.Random(42); // 固定种子，保证每次数据一致
    return List.generate(count, (i) {
      // 使用正弦波 + 随机噪声，生成更自然的波动
      final base = (min + max) / 2;
      final amplitude = (max - min) / 2;
      final sine = math.sin(i * 0.3) * amplitude * 0.6;
      final noise = (random.nextDouble() - 0.5) * amplitude * 0.4;
      return (base + sine + noise).clamp(min, max);
    });
  }

  // ============================================================
  // 设备信息卡片
  // ============================================================

  Widget _buildDeviceInfoCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            Row(
              children: [
                Icon(Icons.computer, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('设备信息', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            // 三项信息横向排列：主机名、操作系统、运行时长
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  theme,
                  Icons.badge,
                  '主机名',
                  deviceName,
                ),
                _buildInfoItem(
                  theme,
                  Icons.laptop_windows,
                  '操作系统',
                  'Windows 11',
                ),
                _buildInfoItem(
                  theme,
                  Icons.schedule,
                  '运行时长',
                  '3天 12小时',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 单个信息项：图标 + 标签 + 值
  Widget _buildInfoItem(
      ThemeData theme, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CPU 使用率卡片
  // ============================================================

  Widget _buildCpuCard(ThemeData theme, List<double> cpuData) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            Row(
              children: [
                Icon(Icons.memory, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('CPU 使用率', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            // 实时折线图
            RealtimeLineChart(
              dataPoints: cpuData,
              title: 'CPU 使用率',
              unit: '%',
              lineColor: Colors.green,
              maxY: 100,
              minY: 0,
              height: 180,
              intervalSeconds: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 内存卡片
  // ============================================================

  Widget _buildMemoryCard(ThemeData theme) {
    const usedGb = 8.2;
    const totalGb = 16.0;
    const usage = usedGb / totalGb; // 使用比例

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            Row(
              children: [
                Icon(Icons.storage, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('内存', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            // 使用量文本
            Text(
              '已用 ${usedGb.toStringAsFixed(1)} GB / 总共 ${totalGb.toStringAsFixed(1)} GB',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: usage,
                minHeight: 10,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  usage > 0.8 ? Colors.red : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // 百分比
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(usage * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GPU 卡片
  // ============================================================

  Widget _buildGpuCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            Row(
              children: [
                Icon(Icons.videocam, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('GPU', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            // 2x2 网格布局
            Row(
              children: [
                Expanded(
                  child: _buildGpuItem(
                    theme,
                    Icons.developer_board,
                    '型号',
                    'NVIDIA RTX 4070',
                  ),
                ),
                Expanded(
                  child: _buildGpuItem(
                    theme,
                    Icons.thermostat,
                    '温度',
                    '65°C',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildGpuItem(
                    theme,
                    Icons.memory,
                    '显存',
                    '8 GB / 12 GB',
                  ),
                ),
                Expanded(
                  child: _buildGpuItem(
                    theme,
                    Icons.speed,
                    '利用率',
                    '45%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// GPU 单项信息
  Widget _buildGpuItem(
      ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 磁盘卡片
  // ============================================================

  Widget _buildDiskCard(ThemeData theme) {
    // 磁盘分区演示数据
    final partitions = [
      const _DiskPartition('C:', 'NTFS', 186.5, 237.0),
      const _DiskPartition('D:', 'NTFS', 412.3, 931.5),
      const _DiskPartition('E:', 'NTFS', 28.7, 100.0),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            Row(
              children: [
                Icon(Icons.disc_full, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('磁盘', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            // 分区列表
            ...partitions.map((p) => _buildDiskPartitionItem(theme, p)),
          ],
        ),
      ),
    );
  }

  /// 单个磁盘分区项
  Widget _buildDiskPartitionItem(ThemeData theme, _DiskPartition partition) {
    final usage = partition.used / partition.total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分区名 + 文件系统 + 使用比例
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${partition.name}  ${partition.filesystem}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(usage * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: usage,
              minHeight: 8,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                usage > 0.9 ? Colors.red : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 已用 / 共
          Text(
            '已用 ${partition.used.toStringAsFixed(1)} GB / 共 ${partition.total.toStringAsFixed(1)} GB',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 网络卡片
  // ============================================================

  Widget _buildNetworkCard(
    ThemeData theme,
    List<double> uploadData,
    List<double> downloadData,
  ) {
    // 当前速率取最新值
    final currentUpload =
        uploadData.isNotEmpty ? uploadData.last.toStringAsFixed(1) : '--';
    final currentDownload =
        downloadData.isNotEmpty ? downloadData.last.toStringAsFixed(1) : '--';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卡片标题
            Row(
              children: [
                Icon(Icons.wifi, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('网络', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            // 当前速率文字
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '上行速率',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentUpload MB/s',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '下行速率',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentDownload MB/s',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.cyan,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 上行速率图表
            RealtimeLineChart(
              dataPoints: uploadData,
              title: '上行速率',
              unit: 'MB/s',
              lineColor: Colors.orange,
              maxY: 50,
              minY: 0,
              height: 140,
              intervalSeconds: 1,
            ),
            const SizedBox(height: 16),

            // 下行速率图表
            RealtimeLineChart(
              dataPoints: downloadData,
              title: '下行速率',
              unit: 'MB/s',
              lineColor: Colors.cyan,
              maxY: 100,
              minY: 0,
              height: 140,
              intervalSeconds: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// 磁盘分区数据模型（内部使用）
class _DiskPartition {
  final String name;
  final String filesystem;
  final double used; // 已用 GB
  final double total; // 总共 GB

  const _DiskPartition(this.name, this.filesystem, this.used, this.total);
}
