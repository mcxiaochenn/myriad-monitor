import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 实时折线图组件
/// 用于显示带时间轴的实时数据图表（如 CPU、内存、网络速率等）
class RealtimeLineChart extends StatelessWidget {
  /// 数据点列表
  final List<double> dataPoints;

  /// Y 轴最大值
  final double maxY;

  /// Y 轴最小值
  final double minY;

  /// 图表标题
  final String title;

  /// 数据单位
  final String unit;

  /// 折线颜色
  final Color lineColor;

  /// 是否显示当前最新值
  final bool showCurrentValue;

  /// 采样间隔（秒），用于计算 X 轴时间偏移
  final double intervalSeconds;

  /// 图表高度
  final double height;

  const RealtimeLineChart({
    super.key,
    required this.dataPoints,
    this.maxY = 100,
    this.minY = 0,
    required this.title,
    this.unit = '%',
    this.lineColor = Colors.blue,
    this.showCurrentValue = true,
    this.intervalSeconds = 1,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 获取最新值用于显示
    final currentValue =
        dataPoints.isNotEmpty ? dataPoints.last.toStringAsFixed(1) : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行：左侧标题 + 右侧当前值
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (showCurrentValue)
              Text(
                '$currentValue$unit',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: lineColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // 图表区域
        SizedBox(
          height: height,
          child: LineChart(
            _buildChartData(theme),
            duration: Duration.zero, // 禁用动画，适合实时更新
          ),
        ),
      ],
    );
  }

  /// 构建图表数据配置
  LineChartData _buildChartData(ThemeData theme) {
    final spots = <FlSpot>[];
    for (int i = 0; i < dataPoints.length; i++) {
      // X 轴为时间偏移，从最早到最新
      spots.add(FlSpot(i * intervalSeconds, dataPoints[i]));
    }

    // 计算 X 轴最大值
    final maxX = dataPoints.length > 1
        ? (dataPoints.length - 1) * intervalSeconds
        : intervalSeconds;

    return LineChartData(
      // 网格配置：水平虚线，无垂直线
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: (maxY - minY) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
            dashArray: [4, 4], // 虚线样式
          );
        },
      ),
      // 标题配置（坐标轴标签）
      titlesData: FlTitlesData(
        // 左侧 Y 轴标签
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: (maxY - minY) / 4,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        // 底部 X 轴标签（时间偏移）
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: _calcBottomInterval(maxX),
            getTitlesWidget: (value, meta) {
              // 计算相对于最新数据点的时间偏移
              final offset = value - maxX;
              return Text(
                '${offset.toInt()}s',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        // 隐藏右侧和顶部标签
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      // 边框配置
      borderData: FlBorderData(show: false),
      // 范围配置
      minX: 0,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      // 触摸提示配置
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) =>
              theme.colorScheme.inverseSurface.withValues(alpha: 0.85),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)}$unit',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
      // 折线数据
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3, // 平滑曲线
          color: lineColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false), // 不显示圆点
          // 线下方渐变填充
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lineColor.withValues(alpha: 0.3),
                lineColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 计算 X 轴标签间隔，避免标签过密
  double _calcBottomInterval(double maxX) {
    if (maxX <= 10) return 2;
    if (maxX <= 30) return 5;
    if (maxX <= 60) return 10;
    return 15;
  }
}

/// 迷你折线图组件
/// 用于设备卡片等空间有限的场景，仅显示折线和渐变填充
class MiniLineChart extends StatelessWidget {
  /// 数据点列表
  final List<double> dataPoints;

  /// 折线颜色
  final Color lineColor;

  /// 图表高度
  final double height;

  const MiniLineChart({
    super.key,
    required this.dataPoints,
    this.lineColor = Colors.blue,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LineChart(
        _buildChartData(),
        duration: Duration.zero, // 禁用动画
      ),
    );
  }

  /// 构建迷你图表数据
  LineChartData _buildChartData() {
    final spots = <FlSpot>[];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i]));
    }

    final maxX =
        dataPoints.length > 1 ? (dataPoints.length - 1).toDouble() : 1.0;

    return LineChartData(
      // 无网格
      gridData: const FlGridData(show: false),
      // 无坐标轴标签
      titlesData: const FlTitlesData(show: false),
      // 无边框
      borderData: FlBorderData(show: false),
      // 无触摸交互
      lineTouchData: const LineTouchData(enabled: false),
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: _calcMaxY(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: lineColor,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          // 线下方渐变填充
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lineColor.withValues(alpha: 0.3),
                lineColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 计算 Y 轴最大值，取数据最大值的 1.2 倍留出余量
  double _calcMaxY() {
    if (dataPoints.isEmpty) return 100;
    final max = dataPoints.reduce((a, b) => a > b ? a : b);
    return max * 1.2;
  }
}
