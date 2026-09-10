import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/script_statistics_models.dart';
import 'package:oasx/modules/home/widgets/statistics_history_axis_layout.dart';
import 'package:oasx/modules/home/widgets/statistics_formatters.dart';
import 'package:oasx/translation/i18n_content.dart';

const _kHistoryAxisLeadingWidth = 116.0;
const _kHistoryTaskLabelWidth = 108.0;
const _kHistoryTaskLabelSpacing = 8.0;
const _kHistoryAxisSpacing = 8.0;
const _kHistoryRowHeight = 44.0;
const _kHistoryRowSpacing = 10.0;
const _kHistoryMaxVisibleRows = 5;

/// Task comparison chart with a fixed top axis.
class ScriptStatisticsHistoryChart extends StatelessWidget {
  /// Creates a task comparison chart.
  const ScriptStatisticsHistoryChart({
    super.key,
    required this.entries,
    required this.metric,
    required this.focusedTaskName,
    required this.onSelectTask,
    required this.flashingTaskName,
    required this.flashToken,
    required this.highlightRealtimeTask,
  });

  /// Task aggregates sorted by the selected metric.
  final List<MapEntry<String, ScriptTaskStatistics>> entries;

  /// Metric currently shown by the chart.
  final ScriptStatisticsChartMetric metric;

  /// Currently focused task name.
  final String focusedTaskName;

  /// Called when the user taps a task bar.
  final ValueChanged<String> onSelectTask;

  /// Task currently highlighted by a realtime update.
  final String flashingTaskName;

  /// Token used to restart the flash animation.
  final int flashToken;

  /// Whether realtime task highlighting is active.
  final bool highlightRealtimeTask;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxValue = entries.fold<double>(
      0,
      (current, entry) =>
          math.max(current, entry.value.metricValueFor(metric)).toDouble(),
    );
    final interval = _resolveInterval(maxValue);
    final axisMax = _resolveAxisMax(maxValue, interval);
    final ticks = _buildTicks(axisMax, interval);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryAxisHeader(
          ticks: ticks,
          axisMax: axisMax,
          metric: metric,
        ),
        const SizedBox(height: _kHistoryAxisSpacing),
        SizedBox(
          height: _resolveViewportHeight(),
          child: ListView.separated(
            primary: false,
            padding: EdgeInsets.zero,
            physics: entries.length > _kHistoryMaxVisibleRows
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: _kHistoryRowSpacing),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _HistoryBarRow(
                entry: entry,
                metric: metric,
                axisMax: axisMax,
                ticks: ticks,
                focused: entry.key == focusedTaskName,
                flashing:
                    highlightRealtimeTask && flashingTaskName == entry.key,
                flashToken: flashToken,
                onTap: () => onSelectTask(entry.key),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds fixed axis ticks using the resolved interval.
  List<double> _buildTicks(double axisMax, double interval) {
    final ticks = <double>[0];
    var cursor = interval;
    while (cursor <= axisMax) {
      ticks.add(cursor);
      cursor += interval;
    }
    return ticks;
  }

  /// Resolves the chart max to the next interval step.
  double _resolveAxisMax(double maxValue, double interval) {
    if (interval <= 0) {
      return 1.0;
    }
    return math
        .max(interval, (maxValue / interval).ceil() * interval)
        .toDouble();
  }

  /// Resolves a stable axis interval for the current metric family.
  double _resolveInterval(double maxValue) {
    if (statisticsMetricUsesDuration(metric)) {
      if (maxValue <= 600) {
        return 120.0;
      }
      if (maxValue <= 3600) {
        return 600.0;
      }
      if (maxValue <= 4 * 3600) {
        return 1800.0;
      }
      return 3600.0;
    }
    if (maxValue <= 10) {
      return 2.0;
    }
    if (maxValue <= 50) {
      return 10.0;
    }
    if (maxValue <= 100) {
      return 20.0;
    }
    return math.max((maxValue / 5).ceilToDouble(), 1.0).toDouble();
  }

  /// Resolves the visible viewport height from the number of visible rows.
  double _resolveViewportHeight() {
    return _resolveRowsHeight(
        math.min(entries.length, _kHistoryMaxVisibleRows));
  }

  /// Resolves the row stack height for the provided row count.
  double _resolveRowsHeight(int rowCount) {
    if (rowCount <= 0) {
      return 0;
    }
    return rowCount * _kHistoryRowHeight + (rowCount - 1) * _kHistoryRowSpacing;
  }
}

class _HistoryAxisHeader extends StatelessWidget {
  const _HistoryAxisHeader({
    required this.ticks,
    required this.axisMax,
    required this.metric,
  });

  final List<double> ticks;
  final double axisMax;
  final ScriptStatisticsChartMetric metric;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Row(
      children: [
        const SizedBox(width: _kHistoryAxisLeadingWidth),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final visibleTickLayouts = resolveStatisticsHistoryAxisLabels(
                ticks: ticks,
                labels: ticks
                    .map((tick) => formatStatisticsMetricByType(tick, metric))
                    .toList(growable: false),
                axisMax: axisMax,
                availableWidth: width,
                style: labelStyle,
                textDirection: Directionality.of(context),
              );
              return SizedBox(
                height: 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    ...visibleTickLayouts.map((layout) {
                      return Positioned(
                        left: layout.left,
                        child: SizedBox(
                          width: layout.width,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              layout.label,
                              textAlign: TextAlign.center,
                              style: labelStyle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryBarRow extends StatelessWidget {
  const _HistoryBarRow({
    required this.entry,
    required this.metric,
    required this.axisMax,
    required this.ticks,
    required this.focused,
    required this.flashing,
    required this.flashToken,
    required this.onTap,
  });

  final MapEntry<String, ScriptTaskStatistics> entry;
  final ScriptStatisticsChartMetric metric;
  final double axisMax;
  final List<double> ticks;
  final bool focused;
  final bool flashing;
  final int flashToken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = entry.value.metricValueFor(metric);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: _kHistoryRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: focused
              ? scheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _kHistoryTaskLabelWidth,
              child: Text(
                entry.key.tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: focused ? scheme.primary : null,
                      fontWeight: focused ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: _kHistoryTaskLabelSpacing),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final ratio =
                      axisMax <= 0 ? 0.0 : (value / axisMax).clamp(0.0, 1.0);
                  final barWidth =
                      math.max(width * ratio, 8.0).toDouble();
                  return Tooltip(
                    preferBelow: false,
                    verticalOffset: 20,
                    message: _tooltipText(),
                    child: SizedBox(
                      height: _kHistoryRowHeight,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          for (final tick in ticks)
                            if (tick > 0 && tick < axisMax)
                              Positioned(
                                left: width * tick / axisMax,
                                top: 8,
                                bottom: 8,
                                width: 1,
                                child: ColoredBox(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.28),
                                ),
                              ),
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: barWidth,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(
                                      scheme.primary, Colors.white, 0.22)!,
                                  scheme.primary,
                                ],
                              ),
                            ),
                          ),
                          if (focused)
                            Positioned(
                              left: math.max(barWidth - 4.0, 0.0),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.primary,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            left: math.min(
                              barWidth + 8.0,
                              math.max(width - 56.0, 0.0),
                            ),
                            child: _HistoryValueBadge(
                              label: formatStatisticsMetricByType(
                                  value, metric),
                              color: scheme.primary,
                              flashing: flashing,
                              flashToken: flashToken,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds tooltip lines without repeating the task name.
  String _tooltipText() {
    return '${I18n.homeStatsTotalDuration.tr}: '
        '${formatStatisticsDuration(entry.value.totalDurationSeconds)}\n'
        '${I18n.homeStatsRunCount.tr}: ${entry.value.runCount}\n'
        '${I18n.homeStatsBattleCount.tr}: ${entry.value.battleCount}\n'
        '${I18n.homeStatsBattleAvgDuration.tr}: '
        '${formatStatisticsDuration(entry.value.battleAvgDurationSeconds)}\n'
        '${I18n.homeStatsAvgRunDuration.tr}: '
        '${formatStatisticsDuration(entry.value.avgRunDurationSeconds)}';
  }
}

class _HistoryValueBadge extends StatelessWidget {
  const _HistoryValueBadge({
    required this.label,
    required this.color,
    required this.flashing,
    required this.flashToken,
  });

  final String label;
  final Color color;
  final bool flashing;
  final int flashToken;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      key: ValueKey('$label|$flashToken|$flashing'),
      tween: Tween<double>(begin: flashing ? 1 : 0, end: 0),
      duration: Duration(milliseconds: flashing ? 1300 : 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = flashing ? value : 0.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.transparent,
              color.withValues(alpha: 0.18),
              pulse,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Color.lerp(
                    Colors.transparent,
                    color.withValues(alpha: 0.56),
                    pulse,
                  ) ??
                  Colors.transparent,
            ),
            boxShadow: pulse > 0
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.26 * pulse),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: pulse > 0.02 ? scheme.onSurface : null,
                  ),
            ),
          ),
        );
      },
    );
  }
}
