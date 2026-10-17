/// Resource statistics models for the OASX workbench resource tab.
///
/// The backend routes are `/income/{script_name}/dates`、`/history`、`?date=`
/// and the payload mirrors `module/log_income.py`：
/// 一天一行存在 `log/income/<配置名>.jsonl`，日志行只作 7 天内的兜底。
library;

/// Ordered resource field keys rendered by the resource tab (two rows of four).
/// Keys mirror the backend fields (tasks/ResourceStat/history.py, kongdr 方案).
const List<String> kResourceStatKeys = <String>[
  'gold',
  'jade',
  'ap',
  'sca_orochi_scales',
  'sca_reverse_scale',
  'sca_demon_souls',
  'sca_picture_book',
  'mystery_amulet',
];

/// Chinese display name for each resource field key.
const Map<String, String> kResourceStatLabels = <String, String>{
  'gold': '金币',
  'jade': '勾玉',
  'ap': '体力',
  'sca_orochi_scales': '八岐大蛇鳞片',
  'sca_reverse_scale': '大蛇的逆鳞',
  'sca_demon_souls': '逢魔之魂',
  'sca_picture_book': '被遗忘的绘本',
  'mystery_amulet': '神秘的符咒',
};

/// Resources whose raw counts get too long for the card, so the value is
/// collapsed into 万/亿 units. Everything else shows the exact OCR number
/// (e.g. jade 23749 stays 23749, no thousand separators).
const Set<String> kResourceStatAbbreviated = <String>{'gold', 'ap'};

/// Bundled icon asset for each resource key (icons from kongdr/OASX).
const Map<String, String> kResourceStatIcons = <String, String>{
  'gold': 'assets/images/resource_stat/gold.png',
  'jade': 'assets/images/resource_stat/jade.png',
  'ap': 'assets/images/resource_stat/ap.png',
  'sca_orochi_scales': 'assets/images/resource_stat/sca_orochi_scales.png',
  'sca_reverse_scale': 'assets/images/resource_stat/sca_reverse_scale.png',
  'sca_demon_souls': 'assets/images/resource_stat/sca_demon_souls.png',
  'sca_picture_book': 'assets/images/resource_stat/sca_picture_book.png',
  'mystery_amulet': 'assets/images/resource_stat/mystery_amulet.png',
};

/// Snapshot for one resource entry.
class ResourceStatItem {
  /// Creates a resource entry snapshot.
  const ResourceStatItem({
    required this.value,
    required this.delta,
    required this.text,
    required this.deltaText,
  });

  /// Latest recorded value, null when the backend never captured it.
  final int? value;

  /// Difference against the previous record.
  final int? delta;

  /// Display text already formatted with 万/亿 units.
  final String text;

  /// Display text for [delta], including the sign.
  final String deltaText;

  /// Whether the resource grew since the previous record.
  bool get isPositive => (delta ?? 0) > 0;

  /// Whether the resource shrank since the previous record.
  bool get isNegative => (delta ?? 0) < 0;

  /// Parses one entry from backend JSON.
  factory ResourceStatItem.fromJson(Map<String, dynamic> json) {
    return ResourceStatItem(
      value: json['value'] as int?,
      delta: json['delta'] as int?,
      text: (json['text'] as String?) ?? '-',
      deltaText: (json['deltaText'] as String?) ?? '-',
    );
  }

  /// Empty placeholder used before the first successful response.
  factory ResourceStatItem.empty() {
    return const ResourceStatItem(
      value: null,
      delta: null,
      text: '-',
      deltaText: '-',
    );
  }
}

/// One point of the resource trend series.
class ResourceStatPoint {
  /// Creates a trend point.
  const ResourceStatPoint({required this.timestamp, required this.values});

  /// Capture time string from the backend, `YYYY-MM-DD HH:MM:SS`.
  final String timestamp;

  /// Resource values keyed by resource name.
  final Map<String, int?> values;

  /// Reads one resource value.
  int? valueOf(String key) => values[key];

  /// Parses one point from backend JSON.
  ///
  /// `/income/history` 给的是 `{date, values:{...}}`；后端用 -1 表示当时没读到，
  /// 这里统一转成 null，不让 -1 参与做差。
  factory ResourceStatPoint.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    final values = <String, int?>{};
    for (final key in kResourceStatKeys) {
      final dynamic nested = rawValues is Map ? rawValues[key] : null;
      final dynamic raw = nested ?? json[key];
      values[key] = raw is int && raw >= 0 ? raw : null;
    }
    return ResourceStatPoint(
      timestamp: (json['ts'] as String?) ?? (json['date'] as String?) ?? '',
      values: values,
    );
  }
}

/// Whole resource statistics payload for one script instance.
class ResourceStatSnapshot {
  /// Creates a resource statistics snapshot.
  const ResourceStatSnapshot({
    required this.scriptName,
    required this.available,
    required this.updated,
    required this.count,
    required this.items,
    required this.series,
    required this.daily,
  });

  /// Script instance name owning the data.
  final String scriptName;

  /// Whether any history record exists.
  final bool available;

  /// Capture time of the newest record.
  final String updated;

  /// Total records loaded in the requested range.
  final int count;

  /// Latest values keyed by resource name.
  final Map<String, ResourceStatItem> items;

  /// Trend series ordered from oldest to newest.
  final List<ResourceStatPoint> series;

  /// Per-day aggregated rows.
  final List<Map<String, dynamic>> daily;

  /// Available day keys (`YYYY-MM-DD`) ordered from oldest to newest.
  List<String> get dateKeys => daily
      .map((row) => row['日期'] as String?)
      .whereType<String>()
      .toList(growable: false);

  /// Aggregated row for one day key, or null when absent.
  Map<String, dynamic>? dayRowFor(String dateKey) {
    for (final row in daily) {
      if (row['日期'] == dateKey) {
        return row;
      }
    }
    return null;
  }

  /// The newest aggregated row, or null when there is no data.
  Map<String, dynamic>? get latestDayRow =>
      daily.isEmpty ? null : daily.last;

  /// Reads one resource entry, falling back to an empty placeholder.
  ResourceStatItem itemOf(String key) =>
      items[key] ?? ResourceStatItem.empty();

  /// All series values for one resource, skipping missing samples.
  List<int> seriesValuesOf(String key) {
    final result = <int>[];
    for (final point in series) {
      final value = point.valueOf(key);
      if (value != null) {
        result.add(value);
      }
    }
    return result;
  }

  /// Parses a snapshot from backend JSON.
  factory ResourceStatSnapshot.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as Map<String, dynamic>? ?? const {};
    final items = <String, ResourceStatItem>{};
    rawItems.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        items[key] = ResourceStatItem.fromJson(value);
      }
    });
    final rawSeries = json['series'] as List<dynamic>? ?? const [];
    final series = rawSeries
        .whereType<Map<String, dynamic>>()
        .map(ResourceStatPoint.fromJson)
        .toList(growable: false);
    final rawDaily = json['daily'] as List<dynamic>? ?? const [];
    final daily = rawDaily
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    return ResourceStatSnapshot(
      scriptName: (json['script_name'] as String?) ?? '',
      available: json['available'] as bool? ?? false,
      updated: (json['updated'] as String?) ?? '',
      count: json['count'] as int? ?? 0,
      items: items,
      series: series,
      daily: daily,
    );
  }

  /// 从 `/income` 的三个响应组装快照。
  ///
  /// - [datesNewestFirst]：`/income/{name}/dates` 的日期列表，从新到旧。
  /// - [records]：`/income/{name}/history` 的 records，按日期升序。
  /// - [dayReport]：`/income/{name}?date=<最新一天>`，用来取采集时间。
  factory ResourceStatSnapshot.fromIncome({
    required String scriptName,
    required List<String> datesNewestFirst,
    required List<dynamic> records,
    required Map<String, dynamic>? dayReport,
  }) {
    final series = records
        .whereType<Map<String, dynamic>>()
        .map(ResourceStatPoint.fromJson)
        .toList(growable: false);
    // 后端一天一行，所以相邻两行的差就是日环比（当天净增减）
    final daily = <Map<String, dynamic>>[];
    Map<String, int?>? previous;
    for (final point in series) {
      final row = <String, dynamic>{'日期': point.timestamp, '次数': 1};
      for (final key in kResourceStatKeys) {
        final value = point.valueOf(key);
        final before = previous?[key];
        row[key] = value;
        row['$key变化'] = (value != null && before != null) ? value - before : null;
      }
      daily.add(row);
      previous = point.values;
    }

    final items = <String, ResourceStatItem>{};
    final rawItems = dayReport?['items'];
    if (rawItems is List) {
      for (final entry in rawItems.whereType<Map<String, dynamic>>()) {
        final name = entry['name'] as String?;
        if (name == null) {
          continue;
        }
        final value = entry['value'] as int?;
        items[name] = ResourceStatItem(
          value: value != null && value >= 0 ? value : null,
          delta: entry['delta'] as int?,
          text: '-',
          deltaText: '-',
        );
      }
    }

    return ResourceStatSnapshot(
      scriptName: scriptName,
      available: daily.isNotEmpty,
      updated: (dayReport?['collected_at'] as String?) ?? '',
      count: daily.length,
      items: items,
      series: series,
      daily: daily,
    );
  }

  /// 这个配置一条记录都没有时的占位快照。
  factory ResourceStatSnapshot.empty(String scriptName) {
    return ResourceStatSnapshot(
      scriptName: scriptName,
      available: false,
      updated: '',
      count: 0,
      items: const <String, ResourceStatItem>{},
      series: const <ResourceStatPoint>[],
      daily: const <Map<String, dynamic>>[],
    );
  }
}
