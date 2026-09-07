import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/common/models/config_drag_payload.dart';
import 'package:oasx/modules/common/widgets/drag_copy_feedback.dart';
import 'package:oasx/modules/common/widgets/mist_glass.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/widgets/split_scroll_row.dart';
import 'package:oasx/modules/home/widgets/task_status_swipe_container.dart';
import 'package:oasx/translation/i18n_content.dart';

part 'task_status_row_parts.dart';

/// Describes one task row rendered inside the overview task list.
class TaskStatusViewData {
  const TaskStatusViewData({
    required this.rowId,
    required this.name,
    required this.type,
    this.timeText = '',
  });

  final String rowId;
  final String name;
  final TaskStatusType type;
  final String timeText;
}

/// Defines the three task states rendered in the overview tab.
enum TaskStatusType { running, pending, waiting }

/// Renders one swipe-to-disable task row for the overview tab.
///
/// 「晨雾玻璃」行样式：圆角白卡 + 状态左色条 + 着色图标容器 +
/// 状态小徽标 + 右侧操作按钮组。
class TaskStatusRow extends StatelessWidget {
  const TaskStatusRow({
    super.key,
    required this.controller,
    required this.sourceScriptName,
    required this.task,
    required this.canQuickSchedule,
    required this.quickScheduleLocked,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
    required this.onDisableTask,
    required this.onDismissed,
    required this.dragEnabled,
    required this.swipeEnabled,
    required this.activeDragPayload,
  });

  final HomeDashboardController controller;
  final String sourceScriptName;
  final TaskStatusViewData task;
  final bool canQuickSchedule;
  final bool quickScheduleLocked;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;
  final Future<bool> Function(String taskName) onDisableTask;
  final ValueChanged<String> onDismissed;
  final bool dragEnabled;
  final bool swipeEnabled;
  final ConfigDragPayload? activeDragPayload;
  static const double _actionExtent = 132;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateColor = _stateColor(context);
    final rowColor = _rowColor(context, isDark);
    return TaskStatusSwipeContainer(
      enabled: swipeEnabled,
      onConfirmDismiss: () => onDisableTask(task.name),
      onDismissed: () => onDismissed(task.rowId),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: rowColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _borderColor(context, isDark)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: stateColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
              child: SplitScrollRow(
                minHeight: 40,
                trailingExtent: _actionExtent,
                trailingBackgroundColor: rowColor,
                trailing: _TaskActionBar(
                  stateColor: stateColor,
                  onQuickRun: !quickScheduleLocked && canQuickSchedule
                      ? () => onQuickRun(task.name)
                      : null,
                  onQuickWait: !quickScheduleLocked && canQuickSchedule
                      ? () => onQuickWait(task.name)
                      : null,
                  onEditTask: () => onEditTask(task.name),
                ),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TaskTypeIcon(type: task.type, stateColor: stateColor),
                    const SizedBox(width: 11),
                    _TaskMeta(
                      controller: controller,
                      sourceScriptName: sourceScriptName,
                      task: task,
                      stateColor: stateColor,
                      onSetNextRun: onSetNextRun,
                      dragEnabled: dragEnabled,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _stateColor(BuildContext context) {
    return switch (task.type) {
      TaskStatusType.running => MistPalette.runGreen,
      TaskStatusType.pending => MistPalette.warnOrange,
      TaskStatusType.waiting => const Color(0xFF7C8DB5),
    };
  }

  /// Resolves the row background: bucket tint merged with drag highlight.
  Color _rowColor(BuildContext context, bool isDark) {
    final scheme = Theme.of(context).colorScheme;
    final Color base;
    if (isDark) {
      base = switch (task.type) {
        TaskStatusType.running => scheme.tertiaryContainer.withValues(
          alpha: 0.16,
        ),
        TaskStatusType.pending => scheme.secondaryContainer.withValues(
          alpha: 0.14,
        ),
        TaskStatusType.waiting => Theme.of(context).cardColor,
      };
    } else {
      base = switch (task.type) {
        TaskStatusType.running => const Color(0x8CFFFFFF),
        TaskStatusType.pending => const Color(0x8CFFFFFF),
        TaskStatusType.waiting => const Color(0x73FFFFFF),
      };
    }
    final isDraggingTask =
        activeDragPayload?.matchesTask(sourceScriptName, task.name) ?? false;
    if (!isDraggingTask) {
      return base;
    }
    return Color.alphaBlend(
      scheme.primaryContainer.withValues(alpha: 0.42),
      base,
    );
  }

  /// Resolves the row border tint by task bucket.
  Color _borderColor(BuildContext context, bool isDark) {
    if (isDark) {
      return MistPalette.darkGlassBorder;
    }
    return switch (task.type) {
      TaskStatusType.running => MistPalette.runGreen.withValues(alpha: 0.28),
      TaskStatusType.pending => MistPalette.warnOrange.withValues(alpha: 0.30),
      TaskStatusType.waiting => const Color(0x14FFFFFF),
    };
  }
}
