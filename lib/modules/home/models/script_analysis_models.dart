
import 'dart:isolate';

import 'package:flutter/foundation.dart' show kIsWeb;

/// One recorded click/swipe operation on the 1280x720 game canvas.
class ScriptAnalysisOperation {
  ScriptAnalysisOperation({
    required this.timeText,
    required this.offsetMs,
    required this.isSwipe,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.name,
    required this.taskName,
    required this.runIndex,
  });

  final String timeText;
  final int offsetMs;
  final bool isSwipe;
  final int x1;
  final int y1;
  final int? x2;
  final int? y2;
  final String name;
  final String taskName;
  final int runIndex;

  static ScriptAnalysisOperation fromJson(Map<String, dynamic> json) {
    return ScriptAnalysisOperation(
      timeText: _readString(json['ts']),
      offsetMs: _readInt(json['offset_ms']),
      isSwipe: _readString(json['type']) == 'swipe',
      x1: _readInt(json['x1']),
      y1: _readInt(json['y1']),
      x2: json['x2'] == null ? null : _readInt(json['x2']),
      y2: json['y2'] == null ? null : _readInt(json['y2']),
      name: _readString(json['name']),
      taskName: _readString(json['task']),
      runIndex: _readInt(json['run_index']),
    );
  }
}

/// One task run window with its operation counters.
class ScriptAnalysisRun {
  ScriptAnalysisRun({
    required this.taskName,
    required this.taskLabel,
    required this.runIndex,
    required this.startTimeText,
    required this.endTimeText,
    required this.startIso,
    required this.endIso,
    required this.durationSeconds,
    required this.clickCount,
    required this.swipeCount,
    required this.failed,
  });

  final String taskName;
  final String taskLabel;
  final int runIndex;
  final String startTimeText;
  final String endTimeText;
  final String startIso;
  final String endIso;
  final double durationSeconds;
  final int clickCount;
  final int swipeCount;
  final bool failed;

  static ScriptAnalysisRun fromJson(Map<String, dynamic> json) {
    return ScriptAnalysisRun(
      taskName: _readString(json['task']),
      taskLabel: _readString(json['task_cn']),
      runIndex: _readInt(json['run_index']),
      startTimeText: _readString(json['start_time']),
      endTimeText: _readString(json['end_time']),
      startIso: _readString(json['start_iso']),
      endIso: _readString(json['end_iso']),
      durationSeconds: _readDouble(json['duration_seconds']),
      clickCount: _readInt(json['click_count']),
      swipeCount: _readInt(json['swipe_count']),
      failed: json['failed'] == true,
    );
  }

  /// Stable key used for selection state.
  String get key => '$taskName#$runIndex';
}

/// One selected-day analysis document served by `/analysis/{script}`.
class ScriptAnalysisDay {
  ScriptAnalysisDay({
    required this.scriptName,
    required this.dateKey,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.totalClickCount,
    required this.totalSwipeCount,
    required this.totalRuntimeSeconds,
    required this.tasks,
    required this.runs,
    required this.operations,
  });

  final String scriptName;
  final String dateKey;
  final int canvasWidth;
  final int canvasHeight;
  final int totalClickCount;
  final int totalSwipeCount;
  final double totalRuntimeSeconds;
  final List<String> tasks;
  final List<ScriptAnalysisRun> runs;
  final List<ScriptAnalysisOperation> operations;

  static ScriptAnalysisDay fromJson(Map<String, dynamic> json, String dateKey) {
    final runs = <ScriptAnalysisRun>[];
    final rawRuns = json['runs'];
    if (rawRuns is List) {
      for (final item in rawRuns) {
        if (item is Map) {
          runs.add(ScriptAnalysisRun.fromJson(
            Map<String, dynamic>.from(item),
          ));
        }
      }
    }

    final operations = <ScriptAnalysisOperation>[];
    final rawOps = json['operations'];
    if (rawOps is List) {
      for (final item in rawOps) {
        if (item is Map) {
          operations.add(ScriptAnalysisOperation.fromJson(
            Map<String, dynamic>.from(item),
          ));
        }
      }
    }

    final tasks = <String>[];
    final rawTasks = json['tasks'];
    if (rawTasks is List) {
      for (final item in rawTasks) {
        if (item is String) {
          tasks.add(item);
        }
      }
    }

    return ScriptAnalysisDay(
      scriptName: _readString(json['script_name']),
      dateKey: dateKey,
      canvasWidth: _readInt(json['canvas_width'], fallback: 1280),
      canvasHeight: _readInt(json['canvas_height'], fallback: 720),
      totalClickCount: _readInt(json['total_click_count']),
      totalSwipeCount: _readInt(json['total_swipe_count']),
      totalRuntimeSeconds: _readDouble(json['total_runtime_seconds']),
      tasks: tasks,
      runs: runs,
      operations: operations,
    );
  }

  /// Total operation count for the whole day.
  int get totalOperationCount =>
      totalClickCount + totalSwipeCount;
}

/// Parses one selected-day analysis document in a background isolate.
Future<ScriptAnalysisDay> parseScriptAnalysisDayAsync(
  Map<String, dynamic> json, {
  required String dateKey,
}) {
  Future<ScriptAnalysisDay> parse() {
    return Future<ScriptAnalysisDay>.value(
      ScriptAnalysisDay.fromJson(json, dateKey),
    );
  }

  if (kIsWeb) {
    return parse();
  }
  return Isolate.run(() => ScriptAnalysisDay.fromJson(json, dateKey));
}

String _readString(dynamic value) {
  if (value is String) {
    return value;
  }
  return '';
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}
