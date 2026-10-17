import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/resource_stat_controller.dart';
import 'package:oasx/modules/home/models/resource_stat_models.dart';
import 'package:oasx/translation/i18n_content.dart';

const double _kPanelHorizontalPadding = 12.0;
const double _kPanelSectionSpacing = 12.0;
const double _kPanelCardSpacing = 10.0;

/// Main resource tab content for the active script, mirroring the reference
/// mock: date picker + refresh row, a 4-column icon card grid (red up /
/// green down), then the trend section and the per-day table.
class ResourceStatPanel extends StatelessWidget {
  /// Creates the resource statistics panel.
  const ResourceStatPanel({super.key});

  /// Controller that owns resource statistics state.
  ResourceStatController get controller =>
      Get.find<ResourceStatController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final snapshot = controller.snapshot.value;
      if (snapshot == null) {
        return _ResourcePlaceholder(
          loading: controller.loading.value,
          message: controller.lastErrorMessage.value,
          onRetry: () {
            final scriptName =
                controller.dashboardController.activeScriptName.value.trim();
            if (scriptName.isNotEmpty) {
              unawaited(controller.load(scriptName));
            }
          },
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          final scriptName = controller.boundScriptName.isNotEmpty
              ? controller.boundScriptName
              : controller.dashboardController.activeScriptName.value.trim();
          if (scriptName.isNotEmpty) {
            await controller.load(scriptName);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            _kPanelHorizontalPadding,
            _kPanelSectionSpacing,
            _kPanelHorizontalPadding,
            _kPanelSectionSpacing,
          ),
          children: [
            _HeaderSection(snapshot: snapshot, controller: controller),
            const SizedBox(height: _kPanelSectionSpacing),
            _ResourceCardGrid(controller: controller),
            const SizedBox(height: _kPanelSectionSpacing),
            _TrendSection(controller: controller),
          ],
        ),
      );
    });
  }
}

/// Header: date picker on the left, refresh button on the right.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.snapshot, required this.controller});

  final ResourceStatSnapshot snapshot;
  final ResourceStatController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                I18n.resourceStatTab.tr,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${I18n.resourceStatUpdated.tr}: '
                '${snapshot.updated.isEmpty ? '-' : snapshot.updated}',
                style: theme.textTheme.bodySmall?.copyWith(color: subtle),
              ),
            ],
          ),
        ),
        const _DateDropdown(),
        const SizedBox(width: 8),
        IconButton(
          tooltip: I18n.retry.tr,
          onPressed: () {
            final scriptName = controller.boundScriptName.isNotEmpty
                ? controller.boundScriptName
                : controller.dashboardController.activeScriptName.value.trim();
            if (scriptName.isNotEmpty) {
              unawaited(controller.load(scriptName));
            }
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

/// Dropdown of available day keys, styled like the mock's `10-12 ▾` pill.
class _DateDropdown extends StatelessWidget {
  const _DateDropdown();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ResourceStatController>();
    return Obx(() {
      final snapshot = controller.snapshot.value;
      final keys = snapshot?.dateKeys ?? const <String>[];
      final current = controller.selectedDateKey.value;
      final display = current.isEmpty ? '--' : current.substring(5);
      return PopupMenuButton<String>(
        tooltip: I18n.resourceStatDate.tr,
        initialValue: current.isEmpty ? null : current,
        onSelected: (value) => controller.selectDate(value),
        enabled: keys.isNotEmpty,
        itemBuilder: (context) {
          return keys.reversed.map((key) {
            return PopupMenuItem<String>(
              value: key,
              child: Text(key.substring(5)),
            );
          }).toList(growable: false);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(display, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      );
    });
  }
}

/// Responsive resource card grid: 4 columns on wide panes, fewer when narrow.
class _ResourceCardGrid extends StatelessWidget {
  const _ResourceCardGrid({required this.controller});

  final ResourceStatController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final row = controller.displayedDayRow;
      return LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 620 ? 4 : (width >= 420 ? 3 : 2);
        const spacing = _kPanelCardSpacing;
        const cardHeight = 92.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: cardWidth / cardHeight,
          children: [
            for (final key in kResourceStatKeys)
              _ResourceCard(
                name: kResourceStatLabels[key] ?? key,
                iconAsset: kResourceStatIcons[key] ?? '',
                value: row?[key] as int?,
                delta: row?['$key变化'] as int?,
                // 金币/体力基数大，折成万/亿；其余（含勾玉）显示确切数
                abbreviate: kResourceStatAbbreviated.contains(key),
              ),
          ],
        );
      });
    });
  }
}

/// One resource card: icon + name, then value with the signed delta.
class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.name,
    required this.iconAsset,
    required this.value,
    required this.delta,
    this.abbreviate = false,
  });

  final String name;
  final String iconAsset;
  final int? value;
  final int? delta;

  /// 数值基数过大时折成万/亿（金币/体力），否则显示确切数。
  final bool abbreviate;

  static const Color _upColor = Color(0xFFE5484D); // 红涨
  static const Color _downColor = Color(0xFF30A46C); // 绿跌

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deltaColor = delta == null
        ? theme.colorScheme.onSurfaceVariant
        : (delta! > 0
            ? _upColor
            : (delta! < 0 ? _downColor : theme.colorScheme.onSurfaceVariant));
    final deltaText =
        delta == null ? '-' : (delta! > 0 ? '+${_compact(delta!)}' : _compact(delta!));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconAsset.isNotEmpty)
                Image.asset(iconAsset,
                    width: 30, height: 30, filterQuality: FilterQuality.medium),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  _compact(value),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                deltaText,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: deltaColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 默认展示 OCR 采集到的确切数量（勾玉扫到 23749 就显示 23749，不加千分位）；
  /// 仅 [abbreviate] 的资源（金币）数值过大时才折成万/亿。
  String _compact(int? value) {
    if (value == null) {
      return '-';
    }
    if (abbreviate) {
      if (value.abs() >= 100000000) {
        return '${(value / 100000000).toStringAsFixed(2)}亿';
      }
      if (value.abs() >= 10000) {
        return '${(value / 10000).toStringAsFixed(2)}万';
      }
    }
    return '$value';
  }
}

/// Trend section: resource dropdown plus a lightweight line chart.
class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.controller});

  final ResourceStatController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  I18n.resourceStatTrend.tr,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Obx(() {
                final selected = controller.selectedResource.value;
                return DropdownButton<String>(
                  value: selected,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: [
                    for (final key in kResourceStatKeys)
                      DropdownMenuItem<String>(
                          value: key,
                          child: Text(kResourceStatLabels[key] ?? key)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectResource(value);
                    }
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: Obx(() {
              final samples = controller.chartSamples;
              if (samples.length < 2) {
                return Center(
                  child: Text(
                    I18n.resourceStatChartEmpty.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return _ResourceTrendChart(
                samples: samples,
                lineColor: theme.colorScheme.primary,
                gridColor: theme.dividerColor.withValues(alpha: 0.35),
                labelStyle: theme.textTheme.bodySmall ?? const TextStyle(),
                labelColor: theme.colorScheme.onSurfaceVariant,
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Line chart for one resource series, drawn with a custom painter.
class _ResourceTrendChart extends StatelessWidget {
  const _ResourceTrendChart({
    required this.samples,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
    required this.labelColor,
  });

  final List<({String timestamp, int value})> samples;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ResourceTrendChartPainter(
        samples: samples,
        lineColor: lineColor,
        gridColor: gridColor,
        labelStyle: labelStyle.copyWith(color: labelColor),
      ),
    );
  }
}

/// Paints grid lines and the polyline for the resource trend.
class _ResourceTrendChartPainter extends CustomPainter {
  _ResourceTrendChartPainter({
    required this.samples,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<({String timestamp, int value})> samples;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;

  static const double _leftGutter = 46;
  // 底部留出放时间刻度的空间，顶部留出最大值标签的空间
  static const double _bottomGutter = 30;
  static const double _topGutter = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _leftGutter;
    final chartHeight = size.height - _topGutter - _bottomGutter;
    if (chartWidth <= 0 || chartHeight <= 0 || samples.length < 2) {
      return;
    }
    final values = samples.map((sample) => sample.value.toDouble()).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final span = (maxValue - minValue).abs() < 1e-9
        ? 1.0
        : (maxValue - minValue) * 1.1;

    double toY(double value) {
      return _topGutter + chartHeight * (1 - (value - minValue) / span);
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var row = 0; row < 4; row += 1) {
      final y = _topGutter + chartHeight * row / 3;
      canvas.drawLine(
        Offset(_leftGutter, y),
        Offset(_leftGutter + chartWidth, y),
        gridPaint,
      );
    }

    final path = Path();
    for (var index = 0; index < samples.length; index += 1) {
      final x = _xAt(index, chartWidth);
      final y = toY(samples[index].value.toDouble());
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
    final lastX = _xAt(samples.length - 1, chartWidth);
    final lastY = toY(samples.last.value.toDouble());
    canvas.drawCircle(Offset(lastX, lastY), 3.5, Paint()..color = lineColor);

    // Y 轴：最大值对应曲线顶点（在上方），最小值对应底部，与 toY 的映射保持一致
    _drawLabel(
      canvas,
      _compact(maxValue),
      const Offset(2, 2),
      _leftGutter - 4,
    );
    _drawLabel(
      canvas,
      _compact(minValue),
      Offset(2, _topGutter + chartHeight - 12),
      _leftGutter - 4,
    );
    _drawTimeAxis(canvas, chartWidth, chartHeight);
  }

  /// 横坐标：按采集时间均匀打刻度，文本格式 'MM-DD HH:MM'。
  void _drawTimeAxis(Canvas canvas, double chartWidth, double chartHeight) {
    final tickCount = _resolveTickCount(chartWidth);
    if (tickCount < 2) {
      return;
    }
    final baseY = _topGutter + chartHeight;
    final tickPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < tickCount; i += 1) {
      final index = ((samples.length - 1) * i / (tickCount - 1)).round();
      final x = _xAt(index, chartWidth);
      canvas.drawLine(Offset(x, baseY), Offset(x, baseY + 4), tickPaint);
      // 首尾分别靠左/靠右对齐，避免标签被画布边缘裁掉
      final align = i == 0
          ? _LabelAlign.left
          : (i == tickCount - 1 ? _LabelAlign.right : _LabelAlign.center);
      _drawLabel(
        canvas,
        _shortTime(samples[index].timestamp),
        Offset(x, baseY + 7),
        96,
        align: align,
      );
    }
  }

  double _xAt(int index, double chartWidth) {
    return _leftGutter + chartWidth * index / (samples.length - 1);
  }

  /// 时间刻度数量按可用宽度自适应，最少 2 个、最多 5 个。
  int _resolveTickCount(double chartWidth) {
    final byWidth = (chartWidth / 96).floor();
    var count = byWidth < 2 ? 2 : (byWidth > 5 ? 5 : byWidth);
    if (count > samples.length) {
      count = samples.length;
    }
    return count;
  }

  /// 'YYYY-MM-DD HH:MM:SS' -> 'MM-DD HH:MM'
  String _shortTime(String timestamp) {
    if (timestamp.length >= 16) {
      return timestamp.substring(5, 16);
    }
    return timestamp;
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset,
    double maxWidth, {
    _LabelAlign align = _LabelAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final dx = align == _LabelAlign.center
        ? offset.dx - painter.width / 2
        : (align == _LabelAlign.right ? offset.dx - painter.width : offset.dx);
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  String _compact(double value) {
    final intValue = value.round();
    if (intValue.abs() >= 100000000) {
      return '${(intValue / 100000000).toStringAsFixed(2)}亿';
    }
    if (intValue.abs() >= 10000) {
      return '${(intValue / 10000).toStringAsFixed(2)}万';
    }
    return '$intValue';
  }

  @override
  bool shouldRepaint(covariant _ResourceTrendChartPainter oldDelegate) {
    if (oldDelegate.samples.length != samples.length ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor) {
      return true;
    }
    // 点数相同但数值/采集时间变了也要重绘，否则时间轴会停留在旧数据
    for (var i = 0; i < samples.length; i += 1) {
      if (oldDelegate.samples[i].timestamp != samples[i].timestamp ||
          oldDelegate.samples[i].value != samples[i].value) {
        return true;
      }
    }
    return false;
  }
}

/// Empty or error state for the resource tab.
class _ResourcePlaceholder extends StatelessWidget {
  const _ResourcePlaceholder({
    required this.loading,
    required this.message,
    required this.onRetry,
  });

  final bool loading;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = message.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Icon(
                hasError ? Icons.error_outline : Icons.insights_outlined,
                size: 34,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            const SizedBox(height: 12),
            Text(
              loading
                  ? I18n.resourceStatLoading.tr
                  : (hasError ? message : I18n.resourceStatEmptyHint.tr),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!loading) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(I18n.retry.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 画布文字标签的水平对齐方式。
enum _LabelAlign { left, center, right }
