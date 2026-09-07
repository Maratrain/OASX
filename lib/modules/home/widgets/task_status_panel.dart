import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_status_row.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Renders the overview task list for the active config workbench.
class TaskStatusPanel extends StatefulWidget {
  const TaskStatusPanel({
    super.key,
    required this.controller,
    required this.scriptModel,
    required this.canQuickScheduleTask,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
  });

  final HomeDashboardController controller;
  final ScriptModel scriptModel;
  final bool Function(String taskName) canQuickScheduleTask;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;

  @override
  State<TaskStatusPanel> createState() => _TaskStatusPanelState();
}

class _TaskStatusPanelState extends State<TaskStatusPanel> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _hiddenTaskIds = <String>{};
  String _searchQuery = '';

  @override
  void didUpdateWidget(covariant TaskStatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptModel.name == widget.scriptModel.name) {
      return;
    }
    _clearSearchState();
    _scrollTaskListToTop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dragPayload = widget.controller.activeDragPayload.value;
      final quickScheduleLocked = widget.controller.isBulkQuickScheduling;
      final rawTasks = _collectTasks(widget.scriptModel);
      _pruneHiddenTaskIds(rawTasks);
      final visibleTasks = rawTasks
          .where((task) => !_hiddenTaskIds.contains(task.rowId))
          .where(_matchesTaskQuery)
          .toList();
      return Column(
        children: [
          _OverviewMetricCard(controller: widget.controller),
          const SizedBox(height: 10),
          _buildSearchField(),
          const SizedBox(height: 12),
          Expanded(
            child: visibleTasks.isEmpty
                ? Center(child: Text(_emptyMessage))
                : ListView.separated(
                    key: const PageStorageKey<String>('home-task-status-list'),
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: visibleTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      return TaskStatusRow(
                        key: ValueKey(task.rowId),
                        controller: widget.controller,
                        sourceScriptName: widget.scriptModel.name,
                        task: task,
                        canQuickSchedule: widget.canQuickScheduleTask(
                          task.name,
                        ),
                        quickScheduleLocked: quickScheduleLocked,
                        onSetNextRun: widget.onSetNextRun,
                        onQuickRun: widget.onQuickRun,
                        onQuickWait: widget.onQuickWait,
                        onEditTask: widget.onEditTask,
                        onDisableTask: _disableTask,
                        onDismissed: _markTaskHidden,
                        dragEnabled: widget.controller.canUseDesktopDragCopy,
                        swipeEnabled: !_isSwipeDisabled(task),
                        activeDragPayload: dragPayload,
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  /// Builds the local overview search field above the task list.
  Widget _buildSearchField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 31,
      child: TextField(
      controller: _searchController,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 17,
          color: isDark ? const Color(0xFF8A93AB) : const Color(0xFF9AA3B8),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 31),
        hintText: I18n.taskSearchHint.tr,
        hintStyle: TextStyle(
          fontSize: 11.5,
          color: isDark ? const Color(0xFF8A93AB) : const Color(0xFF9AA3B8),
        ),
        filled: true,
        fillColor: isDark ? const Color(0x14FFFFFF) : const Color(0xB3FFFFFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x171E283A),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x171E283A),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: MistPalette.accent),
        ),
      ),
      onChanged: (value) => setState(() {
        _searchQuery = value.trim().toLowerCase();
      }),
      ),
    );
  }

  /// Returns the placeholder message for the current filtered view.
  String get _emptyMessage {
    return _searchQuery.isEmpty ? I18n.homeNoTask.tr : I18n.taskNotFound.tr;
  }

  /// Collects the current overview task snapshot from the active script model.
  List<TaskStatusViewData> _collectTasks(ScriptModel model) {
    final tasks = <TaskStatusViewData>[];
    final runningName = model.runningTask.value.taskName.value.trim();
    if (runningName.isNotEmpty) {
      tasks.add(
        TaskStatusViewData(
          rowId: 'running::$runningName',
          name: runningName,
          type: TaskStatusType.running,
        ),
      );
    }
    for (final entry in model.pendingTaskList.indexed) {
      final name = entry.$2.taskName.value.trim();
      if (name.isEmpty) {
        continue;
      }
      final timeText = entry.$2.nextRun.value.trim();
      tasks.add(
        TaskStatusViewData(
          rowId: 'pending::${entry.$1}::$name::$timeText',
          name: name,
          type: TaskStatusType.pending,
          timeText: timeText,
        ),
      );
    }
    for (final entry in model.waitingTaskList.indexed) {
      final name = entry.$2.taskName.value.trim();
      if (name.isEmpty) {
        continue;
      }
      final timeText = entry.$2.nextRun.value.trim();
      tasks.add(
        TaskStatusViewData(
          rowId: 'waiting::${entry.$1}::$name::$timeText',
          name: name,
          type: TaskStatusType.waiting,
          timeText: timeText,
        ),
      );
    }
    return tasks;
  }

  /// Returns whether one overview task matches the local search query.
  bool _matchesTaskQuery(TaskStatusViewData task) {
    if (_searchQuery.isEmpty) {
      return true;
    }
    final localized = task.name.tr.toLowerCase();
    final original = task.name.toLowerCase();
    return localized.contains(_searchQuery) || original.contains(_searchQuery);
  }

  /// Requests disabling one overview task across the current linker scope.
  Future<bool> _disableTask(String taskName) {
    return widget.controller.toggleTaskEnabled(
      scriptName: widget.scriptModel.name,
      taskName: taskName,
      enable: false,
    );
  }

  /// Returns whether the overview row must reject left-swipe interaction.
  bool _isSwipeDisabled(TaskStatusViewData task) {
    return widget.scriptModel.state.value == ScriptState.running &&
        task.type == TaskStatusType.running;
  }

  /// Records one task that already finished its left-slide removal animation.
  void _markTaskHidden(String rowId) {
    setState(() {
      _hiddenTaskIds.add(rowId);
    });
  }

  /// Clears local search and hidden-row state when the active config changes.
  void _clearSearchState() {
    _hiddenTaskIds.clear();
    _searchController.clear();
    _searchQuery = '';
  }

  void _scrollTaskListToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(0);
    });
  }

  /// Releases optimistic hidden rows once the backend snapshot no longer emits them.
  void _pruneHiddenTaskIds(List<TaskStatusViewData> tasks) {
    final activeIds = tasks.map((task) => task.rowId).toSet();
    final staleIds = _hiddenTaskIds
        .where((rowId) => !activeIds.contains(rowId))
        .toList();
    if (staleIds.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || staleIds.isEmpty) {
        return;
      }
      setState(() {
        _hiddenTaskIds.removeAll(staleIds);
      });
    });
  }
}


/// 「晨雾玻璃」总览指标条：总开关 / 运行中任务 / 控制脚本 / 下次调度。
class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({required this.controller});

  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MistPalette.accent.withValues(alpha: 0.08),
            const Color(0xFF7C5BFA).withValues(alpha: 0.05),
          ],
        ),
        color: isDark ? const Color(0x0AFFFFFF) : const Color(0x99FFFFFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark ? const Color(0x1FFFFFFF) : const Color(0x171E283A),
        ),
      ),
      child: Obx(() {
        final script = controller.activeScriptModel;
        var runningCount = 0;
        var enabledTotal = 0;
        var nextSchedule = '';
        if (script != null) {
          if (script.runningTask.value.taskName.value.trim().isNotEmpty) {
            runningCount += 1;
          }
          enabledTotal =
              script.pendingTaskList.length +
              script.waitingTaskList.length +
              runningCount;
          final times = <String>[
            for (final task in script.pendingTaskList)
              if (task.nextRun.value.trim().isNotEmpty) task.nextRun.value,
            for (final task in script.waitingTaskList)
              if (task.nextRun.value.trim().isNotEmpty) task.nextRun.value,
          ]..sort();
          if (times.isNotEmpty) {
            nextSchedule = times.first;
          }
        }
        return OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          spacing: 14,
          overflowSpacing: 8,
          children: [
            _masterSwitch(context),
            _verticalDivider(isDark),
            _metric(
              context,
              I18n.mistMetricRunningTasks.tr,
              '$runningCount',
              suffix: ' / $enabledTotal ${I18n.mistMetricEnabled.tr}',
            ),
            _verticalDivider(isDark),
            _metric(
              context,
              I18n.mistMetricControlScripts.tr,
              '${controller.validControlScriptCount}',
              suffix: ' ${I18n.mistMetricCountUnit.tr}',
            ),
            _metric(
              context,
              I18n.mistMetricNextSchedule.tr,
              nextSchedule.isEmpty ? '—' : nextSchedule,
              accent: true,
            ),
          ],
        );
      }),
    );
  }

  Widget _masterSwitch(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _metricLabel(context, I18n.mistMetricMaster.tr),
          Transform.scale(
            scale: 0.72,
            alignment: Alignment.centerLeft,
            child: Switch(
              value: controller.isAllControlScriptsRunning(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: controller.isBatchSwitching.value
                  ? null
                  : (value) => controller.toggleAllControlScripts(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value, {
    String suffix = '',
    bool accent = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _metricLabel(context, label),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Cascadia Code',
                fontWeight: FontWeight.w600,
                color: accent
                    ? MistPalette.accent
                    : (isDark
                        ? const Color(0xFFE8ECF7)
                        : const Color(0xFF232A3B)),
              ),
            ),
            if (suffix.isNotEmpty)
              Text(
                suffix,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark
                      ? const Color(0xFF8A93AB)
                      : const Color(0xFF9AA3B8),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _metricLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.14,
          color: isDark ? const Color(0xFF8A93AB) : const Color(0xFF9AA3B8),
        ),
      ),
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x171E283A),
    );
  }
}
