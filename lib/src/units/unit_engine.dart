import 'quantity_parser.dart';

/// The result of converting a quantity to another unit.
class ConvertResult {
  final double? value;
  final String? error;

  const ConvertResult._(this.value, this.error);

  bool get isSuccess => value != null;

  factory ConvertResult.ok(double value) => ConvertResult._(value, null);

  factory ConvertResult.fail(String message) => ConvertResult._(null, message);
}

/// High-level helpers for parsing, comparing, and converting quantities.
class UnitEngine {
  const UnitEngine();

  static const QuantityParser parser = QuantityParser();

  /// Parses a quantity expression like `2.5 kN` or `60 km/h`.
  QuantityResult parse(String text) => parser.parse(text);

  /// Parses a bare unit expression like `N` or `kN/m²`.
  QuantityResult parseUnit(String text) => parser.parseUnit(text);

  /// True when both quantities share the same physical dimension.
  bool areCompatible(Quantity a, Quantity b) => a.dimension == b.dimension;

  /// The value of [quantity] expressed in SI base units.
  double toSi(Quantity quantity) => quantity.siValue;

  /// Converts [quantity] into the given [targetUnit] expression.
  ///
  /// The dimensions must match. Affine scales such as `°C` convert correctly
  /// as single targets.
  ConvertResult convert(Quantity quantity, String targetUnit) {
    final targetResult = parser.parseUnit(targetUnit);
    if (targetResult.quantity == null) {
      return ConvertResult.fail(targetResult.error!);
    }
    final target = targetResult.quantity!;
    if (quantity.dimension != target.dimension) {
      return ConvertResult.fail(
        'Incompatible dimensions: ${quantity.unit} is '
        '${quantity.dimension.siLabel} but $targetUnit is '
        '${target.dimension.siLabel}.',
      );
    }
    final si = quantity.siValue;
    return ConvertResult.ok((si - target.offsetToSi) / target.factorToSi);
  }

  /// Formats [value] with up to [fractionDigits] decimal places.
  static String format(double value, {int fractionDigits = 4}) {
    final rounded = double.parse(value.toStringAsFixed(fractionDigits));
    return rounded == rounded.roundToDouble() && fractionDigits > 0
        ? rounded.toInt().toString()
        : rounded.toString();
  }

  /// Formats a parsed value, dropping a trailing `.0`.
  static String formatValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  /// Builds a short human description, for example `2 kN (2000 N)`.
  String describe(Quantity quantity) {
    final si = quantity.siValue;
    final value = formatValue(quantity.value);
    if (quantity.dimension.isDimensionless) {
      return '$value ${quantity.unit}';
    }
    return '$value ${quantity.unit} (${format(si)} ${quantity.dimension.siLabel})';
  }
}
