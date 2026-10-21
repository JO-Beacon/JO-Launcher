/// Launch-pipeline error: `key` is a localization-table key; `args` are
/// placeholder values.
class LaunchException implements Exception {
  const LaunchException(this.key, [this.args = const <String, Object>{}]);

  final String key;
  final Map<String, Object> args;

  @override
  String toString() => key;
}
