/// Generates sequential identifiers for entities.
///
/// Given the existing ids `REQ-001`, `REQ-002`, the next id is `REQ-003`.
class IdGenerator {
  const IdGenerator._();

  static String next(String prefix, Iterable<String> existing) {
    final pattern = RegExp('^$prefix-(\\d+)\$');
    var highest = 0;
    for (final id in existing) {
      final match = pattern.firstMatch(id);
      if (match == null) continue;
      final number = int.tryParse(match.group(1)!);
      if (number != null && number > highest) {
        highest = number;
      }
    }
    return '$prefix-${(highest + 1).toString().padLeft(3, '0')}';
  }
}
