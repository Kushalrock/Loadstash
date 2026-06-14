abstract final class VariableDetector {
  static final _pattern = RegExp(r'\{\{([a-zA-Z][a-zA-Z0-9_]*)\}\}');

  // Returns deduplicated variable names in order of first appearance.
  static List<String> detect(String body) {
    final seen = <String>{};
    final result = <String>[];
    for (final match in _pattern.allMatches(body)) {
      final name = match.group(1)!;
      if (seen.add(name)) result.add(name);
    }
    return result;
  }

  // Substitutes known variables, leaves unknown ones as-is.
  static String substitute(String body, Map<String, String> values) {
    return body.replaceAllMapped(_pattern, (m) {
      final name = m.group(1)!;
      return values[name] ?? m.group(0)!;
    });
  }
}
