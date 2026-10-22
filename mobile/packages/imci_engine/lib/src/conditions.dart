/// Evaluates one condition node against the flat assessment map.
///
/// A missing number does not match a comparison. A missing bool is false.
///
/// Empty-list semantics follow standard logic:
///   - `{"all": []}` → **true**  (vacuous truth — no condition can falsify it)
///   - `{"any": []}` → **false** (no condition can satisfy it)
bool matchesCondition(Object? node, Map<String, Object?> fields) {
  if (node is! Map) return false;
  final map = node.cast<String, Object?>();
  if (map.containsKey('all')) {
    final items = map['all'];
    if (items is! List) return false;
    // Empty 'all' is vacuously true — no child condition can falsify it.
    if (items.isEmpty) return true;
    return items.every((item) => matchesCondition(item, fields));
  }
  if (map.containsKey('any')) {
    final items = map['any'];
    if (items is! List || items.isEmpty) return false;
    return items.any((item) => matchesCondition(item, fields));
  }
  if (map.containsKey('not')) {
    return !matchesCondition(map['not'], fields);
  }
  final op = map['op'];
  if (op == 'count_true_at_least') {
    final names = map['fields'];
    final need = map['value'];
    if (names is! List || need is! num) return false;
    var count = 0;
    for (final name in names) {
      if (name is String && fields[name] == true) count++;
    }
    return count >= need;
  }
  final field = map['field'];
  final expected = map['value'];
  if (field is! String || op is! String) return false;
  final actual = fields[field];
  if (actual == null) return false;
  return switch (op) {
    'eq' => actual == expected,
    'neq' => actual != expected,
    'gt' => actual is num && expected is num && actual > expected,
    'gte' => actual is num && expected is num && actual >= expected,
    'lt' => actual is num && expected is num && actual < expected,
    'lte' => actual is num && expected is num && actual <= expected,
    _ => false,
  };
}
