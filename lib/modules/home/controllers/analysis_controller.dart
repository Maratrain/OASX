import 'dart:async';


import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/models/script_analysis_models.dart';

/// Replay playhead states for the analysis timeline.
enum ScriptAnalysisReplayState {
  idle,
  playing,
  finished,
}

/// Drives the analysis tab: selected day, operation set, heatmap and replay.
class HomeAnalysisController extends GetxController {
  /// Dashboard controller used to resolve the active script and tab.
  final HomeDashboardController dashboardController =
      Get.find<HomeDashboardController>();

  /// Latest user-visible error message.
  final lastErrorMessage = ''.obs;

  /// Whether the selected-date request is loading.
  final analysisLoading = false.obs;

  /// Available backend-provided dates for the active script.
  final availableDateKeys = <String>[].obs;

  /// Selected-date analysis document currently rendered.
  final analysis = Rxn<ScriptAnalysisDay>();

  /// Date currently selected in the header control.
  final selectedDateKey = ''.obs;

  /// Task filter (`''` shows all tasks).
  final selectedTaskName = ''.obs;

  /// Selected run key (`task#index`), `''` shows all runs.
  final selectedRunKey = ''.obs;

  /// Heatmap intensity in `0..100`.
  final heatIntensity = 45.obs;

  /// Whether swipe trails are drawn on the canvas.
  final showSwipes = true.obs;

  /// Whether the canvas grid is drawn.
  final showGrid = true.obs;

  /// Replay playhead in milliseconds from the first operation.
  final replayOffsetMs = 0.obs;

  /// Replay playback speed multiplier.
  final replaySpeed = 2.0.obs;

  /// Replay state.
  final replayState = ScriptAnalysisReplayState.idle.obs;

  Timer? _replayTimer;
  Worker? _dashboardWorker;
  String _boundScriptName = '';
  int _bindingRevision = 0;
  int _requestToken = 0;

  @override
  void onInit() {
    super.onInit();
    _dashboardWorker = everAll([
      dashboardController.activeScriptName,
      dashboardController.activeWorkbenchTab,
      dashboardController.activeWorkbenchSidebarTab,
      dashboardController.workbenchLayoutMode,
    ], (_) {
      unawaited(syncAnalysisBinding());
    });
    unawaited(syncAnalysisBinding());
  }

  @override
  void onClose() {
    _replayTimer?.cancel();
    _dashboardWorker?.dispose();
    super.onClose();
  }

  /// Script currently bound to this controller.
  String get scriptName => _boundScriptName;

  /// Operations visible after applying the run filter.
  List<ScriptAnalysisOperation> get visibleOperations {
    return visibleOperationsFor(analysis.value, selectedRunKey.value);
  }

  /// Pure filter used by views that already read the Rx values themselves.
  List<ScriptAnalysisOperation> visibleOperationsFor(
    ScriptAnalysisDay? day,
    String runKey,
  ) {
    if (day == null) {
      return const <ScriptAnalysisOperation>[];
    }
    if (runKey.isEmpty) {
      return day.operations;
    }
    for (final run in day.runs) {
      if (run.key == runKey) {
        return day.operations
            .where((op) =>
                op.taskName == run.taskName && op.runIndex == run.runIndex)
            .toList(growable: false);
      }
    }
    return day.operations;
  }

  ScriptAnalysisRun? _findRun(String key) {
    final day = analysis.value;
    if (day == null) {
      return null;
    }
    for (final run in day.runs) {
      if (run.key == key) {
        return run;
      }
    }
    return null;
  }

  /// Total replay window in milliseconds (first to last visible operation).
  int get replayTotalMs {
    final ops = visibleOperations;
    if (ops.isEmpty) {
      return 0;
    }
    return ops.last.offsetMs;
  }

  /// Whether the analysis tab is visible in the current layout.
  bool get _isAnalysisVisible {
    final mode = dashboardController.workbenchLayoutMode.value;
    if (mode == HomeWorkbenchLayoutMode.threePane) {
      return dashboardController.displayedWorkbenchSidebarTabFor(mode) ==
          HomeWorkbenchTab.analysis;
    }
    return dashboardController.activeWorkbenchTab.value ==
        HomeWorkbenchTab.analysis;
  }

  /// Rebinds the analysis data to the currently visible script context.
  Future<void> syncAnalysisBinding() async {
    final scriptName = dashboardController.activeScriptName.value.trim();
    if (!_isAnalysisVisible || scriptName.isEmpty) {
      return;
    }
    if (_boundScriptName == scriptName && availableDateKeys.isNotEmpty) {
      return;
    }
    final bindingRevision = ++_bindingRevision;
    _boundScriptName = scriptName;
    selectedTaskName.value = '';
    selectedRunKey.value = '';
    replayOffsetMs.value = 0;
    replayState.value = ScriptAnalysisReplayState.idle;
    analysis.value = null;
    availableDateKeys.clear();
    try {
      final dates =
          await ApiClient().getScriptStatisticsDates(scriptName);
      if (!_isBindingActive(bindingRevision, scriptName)) {
        return;
      }
      availableDateKeys.assignAll(dates.dates);
      if (availableDateKeys.isEmpty) {
        selectedDateKey.value = '';
        return;
      }
      selectedDateKey.value = availableDateKeys.first;
      await loadAnalysis();
    } catch (error) {
      if (!_isBindingActive(bindingRevision, scriptName)) {
        return;
      }
      lastErrorMessage.value = '$error';
    }
  }

  bool _isBindingActive(int bindingRevision, String scriptName) {
    return bindingRevision == _bindingRevision &&
        _boundScriptName == scriptName &&
        dashboardController.activeScriptName.value.trim() == scriptName;
  }

  /// Reloads the analysis document for the current selection.
  Future<void> loadAnalysis() async {
    if (_boundScriptName.isEmpty || selectedDateKey.value.isEmpty) {
      return;
    }
    final token = ++_requestToken;
    analysisLoading.value = true;
    lastErrorMessage.value = '';
    try {
      final result = await ApiClient().getScriptAnalysisDay(
        _boundScriptName,
        selectedDateKey.value,
        taskName: selectedTaskName.value,
      );
      if (token != _requestToken) {
        return;
      }
      analysis.value = result;
      selectedRunKey.value = '';
      _resetReplay();
    } catch (error) {
      if (token == _requestToken) {
        lastErrorMessage.value = '$error';
        analysis.value = null;
      }
    } finally {
      if (token == _requestToken) {
        analysisLoading.value = false;
      }
    }
  }

  /// Switches the selected date and reloads.
  Future<void> selectDate(String dateKey) async {
    if (dateKey == selectedDateKey.value) {
      return;
    }
    selectedDateKey.value = dateKey;
    selectedTaskName.value = '';
    selectedRunKey.value = '';
    await loadAnalysis();
  }

  /// Switches the task filter (empty clears it) and reloads.
  Future<void> selectTask(String taskName) async {
    if (taskName == selectedTaskName.value) {
      return;
    }
    selectedTaskName.value = taskName;
    selectedRunKey.value = '';
    await loadAnalysis();
  }

  /// Switches the focused run (empty clears focus).
  void selectRun(String runKey) {
    selectedRunKey.value = selectedRunKey.value == runKey ? '' : runKey;
    _resetReplay();
  }

  /// Clears the task filter.
  Future<void> clearTaskFilter() async {
    if (selectedTaskName.value.isEmpty) {
      return;
    }
    selectedTaskName.value = '';
    selectedRunKey.value = '';
    await loadAnalysis();
  }

  void _resetReplay() {
    _replayTimer?.cancel();
    replayState.value = ScriptAnalysisReplayState.idle;
    replayOffsetMs.value = 0;
  }

  /// Starts or resumes replay playback.
  void playReplay() {
    if (replayTotalMs <= 0) {
      return;
    }
    if (replayState.value == ScriptAnalysisReplayState.playing) {
      return;
    }
    if (replayState.value == ScriptAnalysisReplayState.finished ||
        replayOffsetMs.value >= replayTotalMs) {
      replayOffsetMs.value = 0;
    }
    replayState.value = ScriptAnalysisReplayState.playing;
    const tickMs = 120;
    _replayTimer?.cancel();
    _replayTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (replayState.value != ScriptAnalysisReplayState.playing) {
        timer.cancel();
        return;
      }
      final next = replayOffsetMs.value + (tickMs * replaySpeed.value).round();
      if (next >= replayTotalMs) {
        replayOffsetMs.value = replayTotalMs;
        replayState.value = ScriptAnalysisReplayState.finished;
        timer.cancel();
        return;
      }
      replayOffsetMs.value = next;
    });
  }

  /// Pauses replay playback.
  void pauseReplay() {
    if (replayState.value == ScriptAnalysisReplayState.playing) {
      replayState.value = ScriptAnalysisReplayState.idle;
      _replayTimer?.cancel();
    }
  }

  /// Restarts replay from zero and pauses.
  void resetReplay() {
    _resetReplay();
  }

  /// Seeks the replay playhead.
  void seekReplay(int offsetMs) {
    replayOffsetMs.value = offsetMs.clamp(0, replayTotalMs == 0 ? 0 : replayTotalMs);
    if (replayState.value == ScriptAnalysisReplayState.finished &&
        replayOffsetMs.value < replayTotalMs) {
      replayState.value = ScriptAnalysisReplayState.idle;
    }
  }

  /// Operations revealed by the current replay playhead.
  List<ScriptAnalysisOperation> replayedOperations() {
    final head = replayOffsetMs.value;
    return visibleOperations
        .where((op) => op.offsetMs <= head)
        .toList(growable: false);
  }
}
