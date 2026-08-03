/// Base quantities defined by the International System of Units (SI).
enum SiBase {
  length('m'),
  mass('kg'),
  time('s'),
  current('A'),
  temperature('K'),
  amount('mol'),
  luminousIntensity('cd');

  const SiBase(this.symbol);

  final String symbol;
}

/// Exponents over the seven SI base quantities.
///
/// A quantity is dimensionless when every exponent is zero.
class Dimension {
  final List<int> exponents;

  const Dimension._(this.exponents);

  static const Dimension dimensionless = Dimension._([0, 0, 0, 0, 0, 0, 0]);
  static const Dimension length = Dimension._([1, 0, 0, 0, 0, 0, 0]);
  static const Dimension mass = Dimension._([0, 1, 0, 0, 0, 0, 0]);
  static const Dimension time = Dimension._([0, 0, 1, 0, 0, 0, 0]);
  static const Dimension current = Dimension._([0, 0, 0, 1, 0, 0, 0]);
  static const Dimension temperature = Dimension._([0, 0, 0, 0, 1, 0, 0]);
  static const Dimension amount = Dimension._([0, 0, 0, 0, 0, 1, 0]);
  static const Dimension luminousIntensity = Dimension._([0, 0, 0, 0, 0, 0, 1]);

  static const Dimension velocity = Dimension._([1, 0, -1, 0, 0, 0, 0]);
  static const Dimension acceleration = Dimension._([1, 0, -2, 0, 0, 0, 0]);
  static const Dimension area = Dimension._([2, 0, 0, 0, 0, 0, 0]);
  static const Dimension volume = Dimension._([3, 0, 0, 0, 0, 0, 0]);
  static const Dimension force = Dimension._([1, 1, -2, 0, 0, 0, 0]);
  static const Dimension energy = Dimension._([2, 1, -2, 0, 0, 0, 0]);
  static const Dimension power = Dimension._([2, 1, -3, 0, 0, 0, 0]);
  static const Dimension pressure = Dimension._([-1, 1, -2, 0, 0, 0, 0]);
  static const Dimension frequency = Dimension._([0, 0, -1, 0, 0, 0, 0]);

  /// True when the quantity has no physical dimension.
  bool get isDimensionless => exponents.every((e) => e == 0);

  /// Returns a new dimension scaled by [exponent].
  Dimension scale(int exponent) =>
      Dimension._([for (final e in exponents) e * exponent]);

  /// Combines this dimension with [other] using the given [sign].
  Dimension combine(Dimension other, int sign) => Dimension._([
    for (var i = 0; i < exponents.length; i++)
      exponents[i] + sign * other.exponents[i],
  ]);

  Dimension operator *(Dimension other) => combine(other, 1);

  Dimension operator /(Dimension other) => combine(other, -1);

  Dimension operator +(Dimension other) => combine(other, 1);

  Dimension operator -(Dimension other) => combine(other, -1);

  @override
  bool operator ==(Object other) =>
      other is Dimension && _listEquals(exponents, other.exponents);

  @override
  int get hashCode => Object.hashAll(exponents);

  /// Named derived units whose exponents map to a familiar symbol.
  static const Map<String, Dimension> _derivedLabels = {
    'N': force,
    'Pa': pressure,
    'J': energy,
    'W': power,
    'Hz': frequency,
    'm/s': velocity,
    'm/s²': acceleration,
    'm²': area,
    'm³': volume,
    'kg/m³': Dimension._([-3, 1, 0, 0, 0, 0, 0]),
    'N·m': energy,
  };

  /// A compact symbolic label, for example `N` or `kg·m/s²`.
  String get siLabel {
    for (final entry in _derivedLabels.entries) {
      if (entry.value == this) return entry.key;
    }
    if (isDimensionless) return '1';
    final positives = <String>[];
    final negatives = <String>[];
    for (var i = 0; i < exponents.length; i++) {
      final e = exponents[i];
      if (e == 0) continue;
      final symbol = SiBase.values[i].symbol;
      final magnitude = e.abs();
      final label = magnitude == 1 ? symbol : '$symbol^$magnitude';
      (e > 0 ? positives : negatives).add(label);
    }
    final pos = positives.join('·');
    final neg = negatives.join('·');
    if (pos.isEmpty) return '1/$neg';
    if (neg.isEmpty) return pos;
    return '$pos/$neg';
  }

  @override
  String toString() => siLabel;
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
