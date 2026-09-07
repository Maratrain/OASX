import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/analysis_controller.dart';
import 'package:oasx/modules/home/models/script_analysis_models.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Analysis tab content: run summary, heat canvas and timeline replay.
class ScriptAnalysisPanel extends StatelessWidget {
  /// Creates the analysis panel.
  const ScriptAnalysisPanel({super.key});

  HomeAnalysisController get controller => Get.find<HomeAnalysisController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final day = controller.analysis.value;
      final loading = controller.analysisLoading.value;
      if (loading && day == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (day == null) {
        return _AnalysisPlaceholder(
          message: controller.lastErrorMessage.value.isEmpty
              ? I18n.noData.tr
              : controller.lastErrorMessage.value,
        );
      }
      return _AnalysisBody(controller: controller, day: day);
    });
  }
}

class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({required this.controller, required this.day});

  final HomeAnalysisController controller;
  final ScriptAnalysisDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      // Read Rx values inside Obx so updates re-render the whole body.
      final day = controller.analysis.value;
      final runKey = controller.selectedRunKey.value;
      final ops = day == null
          ? const <ScriptAnalysisOperation>[]
          : controller.visibleOperationsFor(day, runKey);
      return ListView(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),
          _buildSummaryCards(context),
          const SizedBox(height: 12),
          _buildHeatCanvasCard(context, ops),
          const SizedBox(height: 12),
          _buildReplayCard(context),
          const SizedBox(height: 12),
          _buildRunList(context, theme),
        ],
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final hasFailed = day.runs.any((run) => run.failed);
    return Row(
        children: [
          Text(
            '${day.scriptName} · ${day.dateKey}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: hasFailed
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              hasFailed
                  ? I18n.homeAnalysisStatusFailed.tr
                  : I18n.homeAnalysisStatusSuccess.tr,
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasFailed
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final theme = Theme.of(context);
    Widget card(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(I18n.homeAnalysisClickTotal.tr, '${day.totalClickCount}'),
        const SizedBox(width: 8),
        card(I18n.homeAnalysisSwipeTotal.tr, '${day.totalSwipeCount}'),
        const SizedBox(width: 8),
        card(
            I18n.homeAnalysisRuntime.tr,
            _formatDuration(day.totalRuntimeSeconds)),
      ],
    );
  }

  Widget _buildHeatCanvasCard(BuildContext context, List<ScriptAnalysisOperation> ops) {
    final theme = Theme.of(context);
    return Obx(() {
      final replayOps = controller.replayedOperations();
      final visible = controller.replayState.value ==
              ScriptAnalysisReplayState.playing ||
              controller.replayState.value == ScriptAnalysisReplayState.finished ||
              controller.replayOffsetMs.value > 0
          ? replayOps
          : ops;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  I18n.homeAnalysisHeatCanvas.tr,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  '${visible.length} / ${day.totalOperationCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${day.canvasWidth} × ${day.canvasHeight}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CanvasToggle(
                  label: I18n.homeAnalysisShowClicks.tr,
                  value: true,
                  onChanged: null,
                ),
                _CanvasToggle(
                  label: I18n.homeAnalysisShowSwipes.tr,
                  value: controller.showSwipes.value,
                  onChanged: (v) => controller.showSwipes.value = v,
                ),
                _CanvasToggle(
                  label: I18n.homeAnalysisShowTrajectory.tr,
                  value: controller.showSwipes.value,
                  onChanged: (v) => controller.showSwipes.value = v,
                ),
                _CanvasToggle(
                  label: I18n.homeAnalysisShowGrid.tr,
                  value: controller.showGrid.value,
                  onChanged: (v) => controller.showGrid.value = v,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final boxWidth = constraints.maxWidth;
              final aspect = day.canvasHeight / day.canvasWidth;
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: boxWidth,
                  height: (boxWidth * aspect).clamp(160.0, 420.0),
                  child: _AnalysisCanvas(
                    operations: visible,
                    canvasWidth: day.canvasWidth,
                    canvasHeight: day.canvasHeight,
                    intensity: controller.heatIntensity.value / 100.0,
                    showSwipes: controller.showSwipes.value,
                    showGrid: controller.showGrid.value,
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    I18n.homeAnalysisIntensity.tr,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: controller.heatIntensity.value.toDouble(),
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: (v) => controller.heatIntensity.value = v.round(),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${controller.heatIntensity.value}%',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildReplayCard(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final totalMs = controller.replayTotalMs;
      final head = controller.replayOffsetMs.value;
      final playing =
          controller.replayState.value == ScriptAnalysisReplayState.playing;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              I18n.homeAnalysisTimelineReplay.tr,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  tooltip: I18n.homeAnalysisTimelineReplay.tr,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: totalMs <= 0
                      ? null
                      : () => playing
                          ? controller.pauseReplay()
                          : controller.playReplay(),
                ),
                IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed:
                      totalMs <= 0 ? null : () => controller.resetReplay(),
                ),
                Expanded(
                  child: Slider(
                    value: totalMs <= 0 ? 0 : head.toDouble(),
                    min: 0,
                    max: totalMs <= 0 ? 1 : totalMs.toDouble(),
                    onChanged: totalMs <= 0
                        ? null
                        : (v) => controller.seekReplay(v.round()),
                  ),
                ),
                Text(
                  '${_formatClock(head)} / ${_formatClock(totalMs)}',
                  style: theme.textTheme.labelSmall,
                ),
                PopupMenuButton<double>(
                  initialValue: controller.replaySpeed.value,
                  onSelected: (v) => controller.replaySpeed.value = v,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 0.5, child: Text('0.5×')),
                    PopupMenuItem(value: 1.0, child: Text('1×')),
                    PopupMenuItem(value: 2.0, child: Text('2×')),
                    PopupMenuItem(value: 4.0, child: Text('4×')),
                    PopupMenuItem(value: 8.0, child: Text('8×')),
                  ],
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      '${_formatSpeed(controller.replaySpeed.value)} ▾',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRunList(BuildContext context, ThemeData theme) {
    return Obx(() {
      final runs = day.runs;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            I18n.homeAnalysisRunRecords.tr,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (runs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  I18n.homeAnalysisEmpty.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...runs.map((run) {
              final selected = controller.selectedRunKey.value == run.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: selected
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => controller.selectRun(run.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      child: Row(
                        children: [
                          Icon(
                            run.failed
                                ? Icons.error_outline
                                : Icons.check_circle,
                            size: 17,
                            color: run.failed
                                ? theme.colorScheme.error
                                : theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            run.startTimeText,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${run.taskLabel} · #${run.runIndex}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            '${run.clickCount} ${I18n.homeAnalysisShowClicks.tr}'
                            ' · ${run.swipeCount} ${I18n.homeAnalysisShowSwipes.tr}'
                            ' · ${_formatDuration(run.durationSeconds)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      );
    });
  }
}

class _CanvasToggle extends StatelessWidget {
  const _CanvasToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onChanged != null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: value
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (enabled)
              Icon(
                value ? Icons.check_box : Icons.check_box_outline_blank,
                size: 14,
                color: value
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              )
            else
              const SizedBox(width: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: value
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCanvas extends StatelessWidget {
  const _AnalysisCanvas({
    required this.operations,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.intensity,
    required this.showSwipes,
    required this.showGrid,
  });

  final List<ScriptAnalysisOperation> operations;
  final int canvasWidth;
  final int canvasHeight;
  final double intensity;
  final bool showSwipes;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      return CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _AnalysisCanvasPainter(
          operations: operations,
          canvasWidth: canvasWidth,
          canvasHeight: canvasHeight,
          intensity: intensity,
          showSwipes: showSwipes,
          showGrid: showGrid,
          gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          clickColor: theme.colorScheme.primary,
          swipeColor: theme.colorScheme.tertiary,
          textColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
    });
  }
}

class _AnalysisCanvasPainter extends CustomPainter {
  _AnalysisCanvasPainter({
    required this.operations,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.intensity,
    required this.showSwipes,
    required this.showGrid,
    required this.gridColor,
    required this.clickColor,
    required this.swipeColor,
    required this.textColor,
  });

  final List<ScriptAnalysisOperation> operations;
  final int canvasWidth;
  final int canvasHeight;
  final double intensity;
  final bool showSwipes;
  final bool showGrid;
  final Color gridColor;
  final Color clickColor;
  final Color swipeColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);

    final swipes = operations.where((op) => op.isSwipe).toList(growable: false);
    final clicks = operations.where((op) => !op.isSwipe).toList(growable: false);

    if (showSwipes) {
      for (final op in swipes) {
        canvas.drawLine(
          _scale(op.x1, op.y1, size),
          _scale(op.x2 ?? op.x1, op.y2 ?? op.y1, size),
          Paint()
            ..color = swipeColor.withValues(alpha: 0.65)
            ..strokeWidth = 1.6,
        );
      }
    }

    // Click hotspots: darker ink for higher local density.
    final radius = 5.0 + 6.0 * intensity;
    for (final op in clicks) {
      final center = _scale(op.x1, op.y1, size);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = clickColor.withValues(
              alpha: (0.10 + 0.30 * intensity).clamp(0.0, 1.0)),
      );
    }
    for (final op in clicks) {
      final center = _scale(op.x1, op.y1, size);
      canvas.drawCircle(
        center,
        1.2,
        Paint()..color = clickColor.withValues(alpha: 0.85),
      );
    }

    // Draw the replay head position number for the newest few operations.
    final recent = clicks.length.clamp(0, 1);
    if (recent > 0 && clicks.isNotEmpty) {
      final last = clicks.last;
      final center = _scale(last.x1, last.y1, size);
      final paint = TextPaint(textColor: textColor, fontSize: 10);
      paint.paint(
        canvas,
        Offset(center.dx + 6, center.dy - 6),
        '${clicks.length}',
      );
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: 0.94),
    );
    if (!showGrid) {
      return;
    }
    const cell = 100;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final labelStyle = TextPaint(textColor: textColor, fontSize: 9);
    for (int x = 0; x <= canvasWidth; x += cell) {
      final p = _scaleX(x, size.width);
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), gridPaint);
      if (x % 200 == 0 && x < canvasWidth) {
        labelStyle.paint(canvas, Offset(p + 2, 2), '$x');
      }
    }
    for (int y = 0; y <= canvasHeight; y += cell) {
      final p = _scaleY(y, size.height);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), gridPaint);
      if (y % 200 == 0 && y < canvasHeight) {
        labelStyle.paint(canvas, Offset(2, p + 2), '$y');
      }
    }
  }

  double _scaleX(int x, double width) => x / canvasWidth * width;

  double _scaleY(int y, double height) => y / canvasHeight * height;

  Offset _scale(int x, int y, Size size) =>
      Offset(_scaleX(x, size.width), _scaleY(y, size.height));

  @override
  bool shouldRepaint(covariant _AnalysisCanvasPainter oldDelegate) {
    return oldDelegate.operations != operations ||
        oldDelegate.intensity != intensity ||
        oldDelegate.showSwipes != showSwipes ||
        oldDelegate.showGrid != showGrid;
  }
}

class TextPaint {
  TextPaint({required this.textColor, required this.fontSize});

  final Color textColor;
  final double fontSize;

  void paint(Canvas canvas, Offset offset, String text) {
    final builder = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: textColor, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    builder.paint(canvas, offset);
  }
}

String _formatDuration(double seconds) {
  final total = seconds.round();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  if (h > 0) {
    return '${h}h ${m}m';
  }
  if (m > 0) {
    return '${m}m ${s}s';
  }
  return '${s}s';
}

String _formatClock(int ms) {
  final totalSeconds = ms ~/ 1000;
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String _formatSpeed(double speed) =>
    speed == speed.roundToDouble()
        ? '${speed.round()}×'
        : '${speed.toStringAsFixed(1)}×';

class _AnalysisPlaceholder extends StatelessWidget {
  const _AnalysisPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
