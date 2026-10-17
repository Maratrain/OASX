part of 'api_client.dart';

/// 每日收益，对应 OAS 后端 `/income` 路由（module/server/income_router.py）。
///
/// 数据本身由 DailyTrifles 任务侧写：日志行 `收益快照: gold=... ` 落在
/// `log/<日期>_<配置名>.txt`，日汇总落在 `log/income/<配置名>.jsonl`（一天一行）。
/// 这里只做只读查询。
extension ApiClientResourceStatX on ApiClient {
  /// 有收益记录的日期，从新到旧。
  Future<List<String>> getIncomeDates(String scriptName) async {
    final path = '/income/${Uri.encodeComponent(scriptName)}/dates';
    final res = await request(() => get(path));
    if (!res.isSuccess || res.data is! Map) {
      throw Exception(res.error ?? '读取收益日期失败');
    }
    final raw = (res.data as Map)['dates'] as List<dynamic>? ?? const [];
    return raw
        .map((item) => item?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  /// 最近 days 天的收益记录，按日期升序；没跑任务的那天不会出现。
  Future<List<dynamic>> getIncomeHistory(
    String scriptName, {
    int days = 30,
  }) async {
    final path = '/income/${Uri.encodeComponent(scriptName)}/history?days=$days';
    final res = await request(() => get(path));
    if (!res.isSuccess || res.data is! Map) {
      throw Exception(res.error ?? '读取收益历史失败');
    }
    return (res.data as Map)['records'] as List<dynamic>? ?? const [];
  }

  /// 某一天的收益快照，以及与上一个有记录日期的逐项差值。
  Future<Map<String, dynamic>> getIncomeDay(
    String scriptName,
    String date,
  ) async {
    final path = '/income/${Uri.encodeComponent(scriptName)}'
        '?date=${Uri.encodeComponent(date)}';
    final res = await request(() => get(path));
    if (!res.isSuccess || res.data is! Map) {
      throw Exception(res.error ?? '读取当日收益失败');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }
}
