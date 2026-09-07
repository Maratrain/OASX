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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    final subtitle = Container(
      margin: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            I18n.mistNextRunShort.tr,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF8A93AB) : const Color(0xFF9AA3B8),
            ),
          ),
          const SizedBox(width: 4),
          DateTimePicker(
            value: task.timeText,
            notHoverStyle: TextStyle(
              fontSize: 11,
              fontFamily: 'Cascadia Code',
              color: isDark ? const Color(0xFFB8C0D4) : const Color(0xFF5A6378),
            ),
            hoverStyle: TextStyle(
              fontSize: 11,
              fontFamily: 'Cascadia Code',
              color: Theme.of(context).colorScheme.primary,
            ),
            onChange: (value) => unawaited(onSetNextRun(task.name, value)),
          ),
        ],
      ),
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
        if (task.timeText.isNotEmpty) subtitle,
      ],
    );
  }

  String get _tagLabel {
    return switch (task.type) {
      TaskStatusType.running => I18n.mistStateRunning.tr.toUpperCase(),
      TaskStatusType.pending || TaskStatusType.waiting =>
        I18n.mistStateWaiting.tr.toUpperCase(),
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
        if (onQuickRun != null)
          _MiniPillButton(
            icon: Icons.flash_on_rounded,
            label: I18n.homeQuickRun.tr,
            primary: true,
            onPressed: onQuickRun,
          ),
        if (onQuickRun != null) const SizedBox(width: 5),
        _MiniPillButton(
          icon: Icons.schedule_rounded,
          label: I18n.homeQuickWait.tr,
          onPressed: onQuickWait,
        ),
        const SizedBox(width: 5),
        _MiniPillButton(
          icon: Icons.tune_rounded,
          label: I18n.homeOpenTaskParams.tr,
          onPressed: onEditTask,
        ),
      ],
    );
  }
}

/// 「图标+文字」小胶囊按钮（设计稿 .mini / .mini.pri 样式）。
class _MiniPillButton extends StatelessWidget {
  const _MiniPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Widget content = Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: primary
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11.5,
            color: primary
                ? Colors.white
                : (isDark
                    ? const Color(0xFFB8C0D4)
                    : const Color(0xFF5A6378)),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: primary
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFFB8C0D4)
                      : const Color(0xFF5A6378)),
            ),
          ),
        ],
      ),
    );
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }
}
