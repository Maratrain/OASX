part of 'api_client.dart';

extension ApiClientAnalysisX on ApiClient {
  /// Fetches one selected-day analysis document.
  Future<ScriptAnalysisDay> getScriptAnalysisDay(
    String scriptName,
    String dateKey, {
    String taskName = '',
  }) async {
    final encoded = Uri.encodeComponent(scriptName);
    var path = '/analysis/$encoded?date=$dateKey';
    if (taskName.isNotEmpty) {
      path = '$path&task=${Uri.encodeComponent(taskName)}';
    }
    final res = await request(() => get(path));
    if (!res.isSuccess || res.data is! Map) {
      throw Exception(res.error ?? 'Invalid analysis response');
    }
    return parseScriptAnalysisDayAsync(
      Map<String, dynamic>.from(res.data),
      dateKey: dateKey,
    );
  }
}
