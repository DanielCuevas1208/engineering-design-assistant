/// A raw quantity expression entered by a user.
///
/// The expression is stored as text and parsed on demand by the unit engine.
/// This preserves the original input and lets validation report unknown units.
class QuantityText {
  final String raw;

  const QuantityText(this.raw);

  static const QuantityText empty = QuantityText('');

  bool get isEmpty => raw.trim().isEmpty;

  @override
  bool operator ==(Object other) => other is QuantityText && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;

  @override
  String toString() => raw;
}
