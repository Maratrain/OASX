part of 'task_status_row.dart';

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({
    required this.controller,
    required this.sourceScriptName,
    required this.task,
    required this.stateColor,
    required this.onSetNextRun,
    required this.dragEnabled,
  });

  final HomeDashboardController controller;
  final String sourceScriptName;
  final TaskStatusViewData task;
  final Color stateColor;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final bool dragEnabled;

  @override
  Widget build(BuildContext context) {
    final payload = controller.buildTaskDragPayload(
      sourceConfig: sourceScriptName,
      taskName: task.name,
    );
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            task.name.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        MistMiniTag(label: _tagLabel, color: stateColor),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dragEnabled
            ? Draggable<ConfigDragPayload>(
                data: payload,
                feedback: DragCopyFeedback(label: payload.displayLabel),
                onDragStarted: () => controller.startConfigDrag(payload),
                onDragCompleted: controller.clearConfigDrag,
                onDraggableCanceled: (_, __) => controller.clearConfigDrag(),
                onDragEnd: (_) => controller.clearConfigDrag(),
                child: title,
              )
            : title,
        if (task.timeText.isNotEmpty) ...[
          const SizedBox(height: 3),
          DateTimePicker(
            value: task.timeText,
            notHoverStyle: TextStyle(
              fontSize: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFB8C0D4)
                  : const Color(0xFF5A6378),
            ),
            hoverStyle: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.primary,
            ),
            onChange: (value) => unawaited(onSetNextRun(task.name, value)),
          ),
        ],
      ],
    );
  }

  String get _tagLabel {
    return switch (task.type) {
      TaskStatusType.running => I18n.mistStateRunning.tr.toUpperCase(),
      TaskStatusType.pending => I18n.mistStateWaiting.tr.toUpperCase(),
      TaskStatusType.waiting => I18n.mistStateWaiting.tr.toUpperCase(),
    };
  }
}

class _TaskTypeIcon extends StatelessWidget {
  const _TaskTypeIcon({required this.type, required this.stateColor});

  final TaskStatusType type;
  final Color stateColor;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      TaskStatusType.running => Icons.play_arrow_rounded,
      TaskStatusType.pending => Icons.layers_rounded,
      TaskStatusType.waiting => Icons.schedule_rounded,
    };
    return Container(
      width: 33,
      height: 33,
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: stateColor),
    );
  }
}

class _TaskActionBar extends StatelessWidget {
  const _TaskActionBar({
    required this.stateColor,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
  });

  final Color stateColor;
  final VoidCallback? onQuickRun;
  final VoidCallback? onQuickWait;
  final VoidCallback? onEditTask;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TaskActionIcon(
          icon: Icons.flash_on_rounded,
          tooltip: I18n.homeQuickRun.tr,
          highlight: true,
          onPressed: onQuickRun,
        ),
        const SizedBox(width: 4),
        _TaskActionIcon(
          icon: Icons.schedule_rounded,
          tooltip: I18n.homeQuickWait.tr,
          onPressed: onQuickWait,
        ),
        const SizedBox(width: 4),
        _TaskActionIcon(
          icon: Icons.tune_rounded,
          tooltip: I18n.homeOpenTaskParams.tr,
          onPressed: onEditTask,
        ),
      ],
    );
  }
}

class _TaskActionIcon extends StatelessWidget {
  const _TaskActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlight = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// 主操作按钮：靛紫渐变底白图标（设计稿「立即运行」）。
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Widget content = Container(
      width: 28,
      height: 26,
      decoration: highlight
          ? MistDecor.accentCapsule(radius: 8)
          : BoxDecoration(
              color:
                  isDark ? const Color(0x14FFFFFF) : const Color(0xBFFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0x1FFFFFFF)
                    : const Color(0x171E283A),
              ),
            ),
      child: Icon(
        icon,
        size: 14,
        color: highlight
            ? Colors.white
            : (isDark ? const Color(0xFFB8C0D4) : const Color(0xFF5A6378)),
      ),
    );
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 32),
      onPressed: onPressed,
      icon: content,
    );
  }
}
