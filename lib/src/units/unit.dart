import 'dimension.dart';

/// A base or derived unit with a factor to SI.
///
/// SI value = (value + [offset]) * [factor].
/// Only temperature units use a non-zero [offset].
class UnitDef {
  final String symbol;
  final String name;
  final Dimension dimension;
  final double factor;
  final double offset;

  const UnitDef(
    this.symbol,
    this.name,
    this.dimension,
    this.factor, [
    this.offset = 0,
  ]);

  /// True for affine scales such as Celsius and Fahrenheit.
  bool get isAffine => offset != 0;
}

/// The catalog of SI prefixes and recognized units.
class UnitTable {
  UnitTable._();

  /// SI prefixes mapped to their decimal factors.
  static const Map<String, double> prefixes = {
    'y': 1e-24,
    'z': 1e-21,
    'a': 1e-18,
    'f': 1e-15,
    'p': 1e-12,
    'n': 1e-9,
    'µ': 1e-6,
    'u': 1e-6,
    'm': 1e-3,
    'c': 1e-2,
    'd': 1e-1,
    'da': 1e1,
    'h': 1e2,
    'k': 1e3,
    'M': 1e6,
    'G': 1e9,
    'T': 1e12,
    'P': 1e15,
    'E': 1e18,
    'Z': 1e21,
    'Y': 1e24,
  };

  /// Recognized unit symbols.
  static const Map<String, UnitDef> units = {
    // SI base units.
    'm': UnitDef('m', 'metre', Dimension.length, 1),
    'kg': UnitDef('kg', 'kilogram', Dimension.mass, 1),
    'g': UnitDef('g', 'gram', Dimension.mass, 0.001),
    's': UnitDef('s', 'second', Dimension.time, 1),
    'A': UnitDef('A', 'ampere', Dimension.current, 1),
    'K': UnitDef('K', 'kelvin', Dimension.temperature, 1),
    'mol': UnitDef('mol', 'mole', Dimension.amount, 1),
    'cd': UnitDef('cd', 'candela', Dimension.luminousIntensity, 1),
    // Time.
    'min': UnitDef('min', 'minute', Dimension.time, 60),
    'h': UnitDef('h', 'hour', Dimension.time, 3600),
    'day': UnitDef('day', 'day', Dimension.time, 86400),
    // Frequency and rotation.
    'Hz': UnitDef('Hz', 'hertz', Dimension.frequency, 1),
    'rpm': UnitDef(
      'rpm',
      'revolutions per minute',
      Dimension.frequency,
      1 / 60,
    ),
    // Mechanics.
    'N': UnitDef('N', 'newton', Dimension.force, 1),
    'lbf': UnitDef('lbf', 'pound-force', Dimension.force, 4.4482216152605),
    'J': UnitDef('J', 'joule', Dimension.energy, 1),
    'W': UnitDef('W', 'watt', Dimension.power, 1),
    'Pa': UnitDef('Pa', 'pascal', Dimension.pressure, 1),
    'bar': UnitDef('bar', 'bar', Dimension.pressure, 1e5),
    'psi': UnitDef(
      'psi',
      'pound per square inch',
      Dimension.pressure,
      6894.757293168,
    ),
    // Length.
    'in': UnitDef('in', 'inch', Dimension.length, 0.0254),
    'ft': UnitDef('ft', 'foot', Dimension.length, 0.3048),
    'yd': UnitDef('yd', 'yard', Dimension.length, 0.9144),
    'mi': UnitDef('mi', 'mile', Dimension.length, 1609.344),
    'nmi': UnitDef('nmi', 'nautical mile', Dimension.length, 1852),
    // Mass.
    'lb': UnitDef('lb', 'pound', Dimension.mass, 0.45359237),
    'oz': UnitDef('oz', 'ounce', Dimension.mass, 0.028349523125),
    't': UnitDef('t', 'tonne', Dimension.mass, 1000),
    // Volume.
    'L': UnitDef('L', 'litre', Dimension.volume, 0.001),
    'gal': UnitDef('gal', 'US gallon', Dimension.volume, 0.003785411784),
    // Velocity.
    'kn': UnitDef('kn', 'knot', Dimension.velocity, 0.514444444444),
    // Plane angle, treated as dimensionless.
    'rad': UnitDef('rad', 'radian', Dimension.dimensionless, 1),
    '°': UnitDef('°', 'degree', Dimension.dimensionless, 0.017453292519943295),
    'rev': UnitDef(
      'rev',
      'revolution',
      Dimension.dimensionless,
      6.283185307179586,
    ),
    '%': UnitDef('%', 'percent', Dimension.dimensionless, 0.01),
    // Temperature, with affine offsets.
    '°C': UnitDef('°C', 'degree Celsius', Dimension.temperature, 1, 273.15),
    '°F': UnitDef(
      '°F',
      'degree Fahrenheit',
      Dimension.temperature,
      5 / 9,
      255.3722222222222,
    ),
  };

  /// Symbols sorted longest-first for greedy matching.
  static final List<String> sortedSymbols = () {
    final symbols = units.keys.toList();
    symbols.sort((a, b) => b.length.compareTo(a.length));
    return symbols;
  }();

  /// Prefixes sorted longest-first for greedy matching.
  static final List<String> sortedPrefixes = () {
    final list = prefixes.keys.toList();
    list.sort((a, b) => b.length.compareTo(a.length));
    return list;
  }();
}
