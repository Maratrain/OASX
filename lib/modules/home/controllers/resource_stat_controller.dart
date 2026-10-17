import 'dart:async';

import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/resource_stat_models.dart';

/// Range options offered by the resource statistics header.
enum ResourceStatRange {
  /// Last 7 days.
  sevenDays(7),

  /// Last 30 days.
  thirtyDays(30),

  /// Last 90 days.
  ninetyDays(90);

  /// Creates a range option with its day count.
  const ResourceStatRange(this.days);

  /// Days loaded from the backend.
  final int days;
}

/// Drives resource statistics state for the active script workbench.
class ResourceStatController extends GetxController {
  /// Dashboard controller used to resolve the active script and tab.
  final HomeDashboardController dashboardController =
      Get.find<HomeDashboardController>();

  /// Whether a request is in flight.
  final loading = false.obs;

  /// Latest user-visible error message.
  final lastErrorMessage = ''.obs;

  /// Newest snapshot currently rendered.
  final snapshot = Rxn<ResourceStatSnapshot>();

  /// Range selected in the header.
  final range = ResourceStatRange.thirtyDays.obs;

  /// Resource currently focused by the trend chart.
  final selectedResource = kResourceStatKeys.first.obs;

  /// Day key selected in the header date picker.
  final selectedDateKey = ''.obs;

  /// Script currently bound by the resource tab.
  String _boundScriptName = '';

  /// Worker that keeps the controller bound to dashboard context.
  Worker? _dashboardWorker;

  /// Sequence used to invalidate stale requests.
  int _requestRevision = 0;

  @override
  void onInit() {
    _dashboardWorker = everAll([
      dashboardController.activeScriptName,
      dashboardController.activeWorkbenchTab,
      dashboardController.activeWorkbenchSidebarTab,
      dashboardController.workbenchLayoutMode,
    ], (_) {
      unawaited(syncBinding());
    });
    unawaited(syncBinding());
    super.onInit();
  }

  @override
  void onClose() {
    _dashboardWorker?.dispose();
    _dashboardWorker = null;
    super.onClose();
  }

  /// Whether the resource tab is currently displayed.
  bool get isVisible => dashboardController.isResourceStatVisibleInCurrentLayout;

  /// Script name bound to the rendered snapshot.
  String get boundScriptName => _boundScriptName;

  /// Trend samples for the focused resource, ordered from oldest to newest.
  List<({String timestamp, int value})> get chartSamples {
    final key = selectedResource.value;
    final current = snapshot.value;
    if (current == null) {
      return const [];
    }
    final result = <({String timestamp, int value})>[];
    for (final point in current.series) {
      final value = point.valueOf(key);
      if (value != null) {
        result.add((timestamp: point.timestamp, value: value));
      }
    }
    return List<({String timestamp, int value})>.unmodifiable(result);
  }

  /// Re-binds the controller to the visible script and reloads data.
  Future<void> syncBinding() async {
    final scriptName = dashboardController.activeScriptName.value.trim();
    if (!isVisible || scriptName.isEmpty) {
      await resetState();
      return;
    }
    if (_boundScriptName == scriptName && snapshot.value != null) {
      return;
    }
    await load(scriptName);
  }

  /// Reloads the snapshot for the given script.
  Future<void> load(String scriptName) async {
    final revision = ++_requestRevision;
    _boundScriptName = scriptName;
    loading.value = true;
    lastErrorMessage.value = '';
    try {
      final dates = await ApiClient().getIncomeDates(scriptName);
      if (revision != _requestRevision) {
        return;
      }
      if (dates.isEmpty) {
        snapshot.value = ResourceStatSnapshot.empty(scriptName);
        _syncSelectedDate();
        return;
      }
      final records = await ApiClient().getIncomeHistory(
        scriptName,
        days: range.value.days,
      );
      if (revision != _requestRevision) {
        return;
      }
      // 最新一天的报告只用来取采集时间；拿不到也不影响卡片按历史渲染
      Map<String, dynamic>? dayReport;
      try {
        dayReport = await ApiClient().getIncomeDay(scriptName, dates.first);
      } catch (_) {
        dayReport = null;
      }
      if (revision != _requestRevision) {
        return;
      }
      snapshot.value = ResourceStatSnapshot.fromIncome(
        scriptName: scriptName,
        datesNewestFirst: dates,
        records: records,
        dayReport: dayReport,
      );
      _syncSelectedDate();
    } catch (error) {
      if (revision != _requestRevision) {
        return;
      }
      snapshot.value = null;
      lastErrorMessage.value = error.toString();
    } finally {
      if (revision == _requestRevision) {
        loading.value = false;
      }
    }
  }

  /// Switches the focused resource of the trend chart.
  void selectResource(String key) {
    if (selectedResource.value == key) {
      return;
    }
    selectedResource.value = key;
  }

  /// Keeps the selected date inside the available range, defaulting to latest.
  void _syncSelectedDate() {
    final current = snapshot.value;
    final keys = current?.dateKeys ?? const <String>[];
    if (keys.isEmpty) {
      selectedDateKey.value = '';
      return;
    }
    if (!keys.contains(selectedDateKey.value)) {
      selectedDateKey.value = keys.last;
    }
  }

  /// Switches the day shown by the resource cards.
  void selectDate(String dateKey) {
    if (selectedDateKey.value == dateKey) {
      return;
    }
    selectedDateKey.value = dateKey;
  }

  /// Aggregated row currently shown by the cards, or null without data.
  Map<String, dynamic>? get displayedDayRow {
    final current = snapshot.value;
    if (current == null) {
      return null;
    }
    final row = current.dayRowFor(selectedDateKey.value);
    return row ?? current.latestDayRow;
  }

  /// Changes the loaded range and refreshes immediately.
  Future<void> selectRange(ResourceStatRange next) async {
    if (range.value == next) {
      return;
    }
    range.value = next;
    final scriptName = _boundScriptName.isNotEmpty
        ? _boundScriptName
        : dashboardController.activeScriptName.value.trim();
    if (scriptName.isNotEmpty) {
      await load(scriptName);
    }
  }

  /// Clears rendered state when the tab becomes invisible.
  Future<void> resetState() async {
    _requestRevision += 1;
    _boundScriptName = '';
    snapshot.value = null;
    selectedDateKey.value = '';
    loading.value = false;
  }
}
