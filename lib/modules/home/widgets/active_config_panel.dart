import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/common/widgets/mist_glass.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/home/widgets/analysis_panel.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/modules/home/widgets/task_catalog_panel.dart';
import 'package:oasx/modules/home/widgets/task_status_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

class ActiveConfigPanel extends StatelessWidget {
  const ActiveConfigPanel({
    super.key,
    required this.controller,
    required this.layoutMode,
    required this.onChangeTab,
    required this.onOpenTask,
    required this.onTogglePower,
    required this.onRenameScript,
    required this.onDeleteScript,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onBulkQuickRun,
    required this.onBulkQuickWait,
    this.onExpandRightSidebar,
    this.onBackToScripts,
  });

  final HomeDashboardController controller;
  final HomeWorkbenchLayoutMode layoutMode;
  final Future<void> Function(HomeWorkbenchTab tab) onChangeTab;
  final Future<void> Function(
    String taskName,
    HomeTaskParameterEntrySource source,
  )
  onOpenTask;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;
  final Future<void> Function(String scriptName) onRenameScript;
  final Future<void> Function(String scriptName) onDeleteScript;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function() onBulkQuickRun;
  final Future<void> Function() onBulkQuickWait;
  final VoidCallback? onExpandRightSidebar;
  final VoidCallback? onBackToScripts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          final script = controller.activeScriptModel;
          final currentTab = controller.displayedWorkbenchTabFor(layoutMode);
          final tabs = controller.workbenchTabsFor(layoutMode);
          if (script == null) {
            return Center(child: Text(I18n.homeNoScriptSelected.tr));
          }
          final isRunning = script.state.value == ScriptState.running;
          final bulkMode = controller.bulkQuickScheduleMode.value;
          final hasBulkTasks = controller
              .quickSchedulableTaskNamesFor(script)
              .isNotEmpty;
          final isBulkIdle = bulkMode == HomeBulkQuickScheduleMode.none;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBackToScripts != null)
                    IconButton(
                      tooltip: I18n.scriptList.tr,
                      onPressed: onBackToScripts,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Text(
                      script.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  MistStatusPill(
                    label: _scriptStateLabel(controller, script),
                    color: _scriptStateColor(controller, script),
                  ),
                  const SizedBox(width: 8),
                  _PowerGhostButton(
                    isRunning: isRunning,
                    onPressed: () => onTogglePower(script.name, !isRunning),
                  ),
                  if (onExpandRightSidebar != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      key: const ValueKey<String>(
                        'home-workbench-expand-right-sidebar',
                      ),
                      tooltip: I18n.homeRestoreSidebar.tr,
                      onPressed: onExpandRightSidebar,
                      icon: const Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              MistUnderlineTabs<HomeWorkbenchTab>(
                tabs: [
                  for (final tab in tabs) (tab, _tabLabel(tab)),
                ],
                selected: currentTab,
                onSelected: onChangeTab,
              ),
              const SizedBox(height: 10),
              _BulkActionBar(
                bulkMode: bulkMode,
                hasBulkTasks: hasBulkTasks,
                isBulkIdle: isBulkIdle,
                onBulkQuickRun: onBulkQuickRun,
                onBulkQuickWait: onBulkQuickWait,
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildTabContent(script, currentTab)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(ScriptModel script, HomeWorkbenchTab currentTab) {
    return switch (currentTab) {
      HomeWorkbenchTab.status => TaskStatusPanel(
        controller: controller,
        scriptModel: script,
        canQuickScheduleTask: (taskName) =>
            controller.canQuickScheduleTask(script, taskName),
        onSetNextRun: onSetNextRun,
        onQuickRun: onQuickRun,
        onQuickWait: onQuickWait,
        onEditTask: (taskName) =>
            onOpenTask(taskName, HomeTaskParameterEntrySource.overview),
      ),
      HomeWorkbenchTab.tasks => TaskCatalogPanel(
        controller: controller,
        scriptModel: script,
        onOpenTask: (taskName) =>
            onOpenTask(taskName, HomeTaskParameterEntrySource.tasks),
        onQuickRun: onQuickRun,
        onQuickWait: onQuickWait,
      ),
      HomeWorkbenchTab.stats => const ScriptStatisticsPanel(),
      HomeWorkbenchTab.analysis => const ScriptAnalysisPanel(),
      HomeWorkbenchTab.logs => LogCenterPanel(scriptName: script.name),
    };
  }

  String _tabLabel(HomeWorkbenchTab value) {
    return switch (value) {
      HomeWorkbenchTab.status => I18n.overview.tr,
      HomeWorkbenchTab.tasks => I18n.homeTasksTab.tr,
      HomeWorkbenchTab.stats => I18n.homeStatsTab.tr,
      HomeWorkbenchTab.analysis => I18n.homeAnalysisTab.tr,
      HomeWorkbenchTab.logs => I18n.log.tr,
    };
  }
}

/// 脚本电源 ghost 按钮（运行中=琥珀停止 / 停止=绿色启动）。
class _PowerGhostButton extends StatelessWidget {
  const _PowerGhostButton({required this.isRunning, required this.onPressed});

  final bool isRunning;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isRunning) {
      return MistGhostButton(
        icon: Icons.power_settings_new_rounded,
        label: I18n.stop.tr,
        foreground: const Color(0xFFB26A00),
        background: const Color(0xFFFFF4DE),
        borderColor: const Color(0xFFF5DFB2),
        onPressed: onPressed,
      );
    }
    return MistGhostButton(
      icon: Icons.power_settings_new_rounded,
      label: I18n.run.tr,
      foreground: const Color(0xFF0B7A4B),
      background: const Color(0xFFE2F7EC),
      borderColor: const Color(0xFFC2E9D4),
      onPressed: onPressed,
    );
  }
}

/// 「全部立即运行 / 全部等待」批量操作条（ghost 按钮对）。
class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({
    required this.bulkMode,
    required this.hasBulkTasks,
    required this.isBulkIdle,
    required this.onBulkQuickRun,
    required this.onBulkQuickWait,
  });

  final HomeBulkQuickScheduleMode bulkMode;
  final bool hasBulkTasks;
  final bool isBulkIdle;
  final Future<void> Function() onBulkQuickRun;
  final Future<void> Function() onBulkQuickWait;

  @override
  Widget build(BuildContext context) {
    if (!hasBulkTasks) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        MistGhostButton(
          icon: Icons.flash_on_rounded,
          label: I18n.homeQuickRunAll.tr,
          foreground: const Color(0xFFB26A00),
          background: const Color(0xFFFFF4DE),
          borderColor: const Color(0xFFF5DFB2),
          loading: bulkMode == HomeBulkQuickScheduleMode.runNow,
          onPressed: isBulkIdle ? onBulkQuickRun : null,
        ),
        const SizedBox(width: 8),
        MistGhostButton(
          icon: Icons.schedule_rounded,
          label: I18n.homeQuickWaitAll.tr,
          foreground: const Color(0xFF0B7A4B),
          background: const Color(0xFFE2F7EC),
          borderColor: const Color(0xFFC2E9D4),
          loading: bulkMode == HomeBulkQuickScheduleMode.waitNow,
          onPressed: isBulkIdle ? onBulkQuickWait : null,
        ),
      ],
    );
  }
}

/// 解析脚本状态胶囊文案。
String _scriptStateLabel(
  HomeDashboardController controller,
  ScriptModel script,
) {
  return switch (controller.scriptStateFor(script)) {
    HomeScriptStateFilter.running => I18n.mistStateRunning,
    HomeScriptStateFilter.abnormal || HomeScriptStateFilter.offline =>
      I18n.mistStateAbnormal,
    _ => I18n.mistStateStopped,
  }.tr;
}

/// 解析脚本状态胶囊颜色。
Color _scriptStateColor(
  HomeDashboardController controller,
  ScriptModel script,
) {
  return switch (controller.scriptStateFor(script)) {
    HomeScriptStateFilter.running => MistPalette.runGreen,
    HomeScriptStateFilter.abnormal || HomeScriptStateFilter.offline =>
      MistPalette.warnOrange,
    _ => MistPalette.stopGrey,
  };
}
