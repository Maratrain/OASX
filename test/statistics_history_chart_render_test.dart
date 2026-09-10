// 统计柱状图渲染回归测试：行内柱子、数值徽标须正常渲染。
// 历史 bug：Tooltip 未包 Expanded 导致内层 Row 拿到无界宽度，release 下整棵子树不渲染。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/models/script_statistics_models.dart';
import 'package:oasx/modules/home/widgets/statistics_history_chart.dart';

ScriptTaskStatistics _stats(int runCount) {
  return ScriptTaskStatistics(
    runCount: runCount,
    totalDurationSeconds: 60.0 * runCount,
    battle: null,
    runs: const [],
    latestRunStartTime: null,
  );
}

ScriptStatisticsHistoryChart _chart() {
  final entries = <MapEntry<String, ScriptTaskStatistics>>[
    MapEntry('重启', _stats(5)),
    MapEntry('花合战', _stats(5)),
    MapEntry('金币妖怪', _stats(3)),
    MapEntry('结界蹭卡', _stats(3)),
    MapEntry('经验妖怪', _stats(2)),
  ];
  return ScriptStatisticsHistoryChart(
    entries: entries,
    metric: ScriptStatisticsChartMetric.runCount,
    focusedTaskName: '重启',
    onSelectTask: (_) {},
    flashingTaskName: '',
    flashToken: 0,
    highlightRealtimeTask: false,
  );
}

void main() {
  testWidgets('柱状图渲染柱子与柱外数值', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            // 34(轴头) + 8(间距) + 5 行 × 44 + 4 间距 × 10 = 302
            child: SizedBox(width: 325, height: 320, child: _chart()),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('重启'), findsOneWidget);
    // 数值徽标在柱外独立栏中渲染（"2" 含一个轴刻度，共两处）
    expect(find.text('5'), findsNWidgets(2));
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('2'), findsNWidgets(2));
  });
}
