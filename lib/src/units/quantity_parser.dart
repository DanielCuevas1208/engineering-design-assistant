import 'dart:math';

import 'dimension.dart';
import 'unit.dart';

/// A parsed quantity: a numeric value with a unit expression.
class Quantity {
  final double value;
  final String unit;
  final Dimension dimension;
  final double factorToSi;
  final double offsetToSi;

  const Quantity({
    required this.value,
    required this.unit,
    required this.dimension,
    required this.factorToSi,
    this.offsetToSi = 0,
  });

  /// The value expressed in SI base units.
  double get siValue => value * factorToSi + offsetToSi;

  /// True for affine scales such as Celsius and Fahrenheit.
  bool get isAffine => offsetToSi != 0;

  @override
  String toString() => '$value $unit';
}

/// The outcome of parsing a quantity expression.
class QuantityResult {
  final Quantity? quantity;
  final String? error;

  const QuantityResult._(this.quantity, this.error);

  bool get isSuccess => quantity != null;

  bool get isFailure => error != null;

  factory QuantityResult.ok(Quantity quantity) =>
      QuantityResult._(quantity, null);

  factory QuantityResult.fail(String message) =>
      QuantityResult._(null, message);
}

/// A unit term resolved against the unit table.
class _UnitTerm {
  final String raw;
  final UnitDef def;
  final int exponent;

  const _UnitTerm(this.raw, this.def, this.exponent);
}

/// Parses strings such as `25 mm`, `2.5 kN/m^2`, `60 km/h`, or `98 °F`.
class QuantityParser {
  const QuantityParser();

  /// Parses a full quantity expression like `100 mm` or `2.5 kN`.
  ///
  /// The value and the unit expression must both be present.
  QuantityResult parse(String input) {    final text = input.trim();
    if (text.isEmpty) {
      return QuantityResult.fail('The quantity is empty.');
    }
    final number = _readNumber(text, 0);
    if (number == null) {
      return QuantityResult.fail("Expected a number at the start of '$text'.");
    }
    final value = number.$1;
    var index = number.$2;
    while (index < text.length && text.codeUnitAt(index) == 0x20) {
      index++;
    }
    if (index >= text.length) {
      return QuantityResult.fail("Missing a unit after the value in '$text'.");
    }
    final unitResult = _parseUnitExpression(text, index);
    if (unitResult == null) {
      final fragment = text.substring(index).trim();
      return QuantityResult.fail("Unrecognized unit expression '$fragment'.");
    }
    if (unitResult.$2 < text.length) {
      final rest = text.substring(unitResult.$2).trim();
      return QuantityResult.fail("Unexpected text '$rest' after the unit.");
    }
    final expression = _UnitExpression(unitResult.$1);
    final combined = expression.combine();
    if (combined == null) {
      return QuantityResult.fail(expression.affineError!);
    }
    return QuantityResult.ok(
      Quantity(
        value: value,
        unit: expression.toString(),
        dimension: combined.dimension,
        factorToSi: combined.factor,
        offsetToSi: combined.offset,
      ),
    );
  }

  /// Parses a bare unit expression such as `mm` or `kN/m²`.
  ///
  /// The returned quantity carries a value of one.
  QuantityResult parseUnit(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return QuantityResult.fail('The unit expression is empty.');
    }
    final result = _parseUnitExpression(text, 0);
    if (result == null || result.$2 != text.length) {
      return QuantityResult.fail("Unrecognized unit expression '$text'.");
    }
    final expression = _UnitExpression(result.$1);
    final combined = expression.combine();
    if (combined == null) {
      return QuantityResult.fail(expression.affineError!);
    }
    return QuantityResult.ok(
      Quantity(
        value: 1,
        unit: expression.toString(),
        dimension: combined.dimension,
        factorToSi: combined.factor,
        offsetToSi: combined.offset,
      ),
    );
  }

  /// Reads a signed decimal number, returning its value and end index.
  (double, int)? _readNumber(String text, int start) {
    var index = start;
    if (index < text.length && text[index] == '-') {
      index++;
    }
    final digitStart = index;
    while (index < text.length && _isDigit(text[index])) {
      index++;
    }
    if (index == digitStart) return null;
    if (index < text.length && text[index] == '.') {
      index++;
      while (index < text.length && _isDigit(text[index])) {
        index++;
      }
    }
    if (index < text.length && (text[index] == 'e' || text[index] == 'E')) {
      var expIndex = index + 1;
      if (expIndex < text.length &&
          (text[expIndex] == '+' || text[expIndex] == '-')) {
        expIndex++;
      }
      final expStart = expIndex;
      while (expIndex < text.length && _isDigit(text[expIndex])) {
        expIndex++;
      }
      if (expIndex > expStart) {
        index = expIndex;
      }
    }
    final token = text.substring(start, index);
    return (double.parse(token), index);
  }

  /// Parses a unit expression, returning the terms and the end index.
  ///
  /// A term is either a parenthesized expression or a prefixed unit symbol
  /// with an optional integer exponent.
  (List<_UnitTerm>, int)? _parseUnitExpression(String text, int start) {
    final terms = <_UnitTerm>[];
    var index = start;
    var sign = 1;
    var sawTerm = false;
    while (index < text.length) {
      while (index < text.length && text.codeUnitAt(index) == 0x20) {
        index++;
      }
      if (index >= text.length) break;
      final char = text[index];
      if (char == '*' || char == '·' || char == '/') {
        if (!sawTerm) {
          return null;
        }
        sign = char == '/' ? -1 : 1;
        index++;
        continue;
      }
      if (char == '(') {
        if (sawTerm) return null;
        final closing = _findClosingParen(text, index);
        if (closing < 0) return null;
        final body = text.substring(index + 1, closing);
        final bodyResult = _parseUnitExpression(body, 0);
        if (bodyResult == null || bodyResult.$2 != body.length) return null;
        for (final term in bodyResult.$1) {
          terms.add(_UnitTerm(term.raw, term.def, sign * term.exponent));
        }
        index = closing + 1;
        sawTerm = true;
        sign = 1;
        continue;
      }
      if (char == ')') {
        if (!sawTerm) return null;
        return (terms, index + 1);
      }
      final term = _matchUnitTerm(text, index);
      if (term == null) return null;
      var exponent = sign;
      index = term.$2;
      if (index < text.length) {
        final next = text[index];
        if (next == '^') {
          final expRead = _readInteger(text, index + 1);
          if (expRead == null) return null;
          exponent = sign * expRead.$1;
          index = expRead.$2;
        } else {
          final superscript = _readSuperscript(text, index);
          if (superscript != null) {
            exponent = sign * superscript.$1;
            index = superscript.$2;
          } else {
            final trailing = _readTrailingExponent(text, index);
            if (trailing != null) {
              exponent = sign * trailing.$1;
              index = trailing.$2;
            }
          }
        }
      }
      terms.add(_UnitTerm(term.$1.raw, term.$1.def, exponent));
      sawTerm = true;
      sign = 1;
    }
    if (!sawTerm) return null;
    return (terms, index);
  }

  int _findClosingParen(String text, int open) {
    var depth = 0;
    for (var i = open; i < text.length; i++) {
      if (text[i] == '(') depth++;
      if (text[i] == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  /// Matches a prefixed unit symbol at [start].
  ///
  /// Returns the raw symbol text, the resolved definition, and the end index.
  (_UnitTerm, int)? _matchUnitTerm(String text, int start) {
    _Candidate? best;

    for (final symbol in UnitTable.sortedSymbols) {
      if (_startsWith(text, start, symbol)) {
        final def = UnitTable.units[symbol]!;
        best = _pickCandidate(
          best,
          _Candidate(symbol, def, start + symbol.length, symbol.length),
        );
        break;
      }
    }

    for (final prefix in UnitTable.sortedPrefixes) {
      if (!_startsWith(text, start, prefix)) continue;
      final baseStart = start + prefix.length;
      for (final symbol in UnitTable.sortedSymbols) {
        if (_startsWith(text, baseStart, symbol)) {
          final def = UnitTable.units[symbol]!;
          final factor = UnitTable.prefixes[prefix]!;
          final combined = UnitDef(
            '$prefix$symbol',
            def.name,
            def.dimension,
            def.factor * factor,
            def.offset,
          );
          best = _pickCandidate(
            best,
            _Candidate(
              '$prefix$symbol',
              combined,
              baseStart + symbol.length,
              prefix.length + symbol.length,
            ),
            preferSymbol: true,
          );
          break;
        }
      }
    }

    if (best == null) return null;
    return (_UnitTerm(best.raw, best.def, 1), best.end);
  }

  /// Keeps the longest candidate, preferring a pure symbol on ties.
  _Candidate _pickCandidate(
    _Candidate? current,
    _Candidate next, {
    bool preferSymbol = false,
  }) {
    if (current == null) return next;
    if (next.length > current.length) return next;
    if (next.length < current.length) return current;
    if (preferSymbol) return current;
    return next;
  }

  /// Reads `2` or `3` directly after a symbol, as in `cm3`.
  (int, int)? _readTrailingExponent(String text, int index) {
    if (index >= text.length) return null;
    final char = text[index];
    if (char == '2') return (2, index + 1);
    if (char == '3') return (3, index + 1);
    return null;
  }

  /// Reads a superscript digit, for example `²` or `³`.
  (int, int)? _readSuperscript(String text, int index) {
    if (index >= text.length) return null;
    const map = {
      '\u00b2': 2, // ²
      '\u00b3': 3, // ³
      '\u2074': 4, // ⁴
    };
    final exponent = map[text[index]];
    if (exponent == null) return null;
    return (exponent, index + 1);
  }

  (int, int)? _readInteger(String text, int start) {
    var index = start;
    if (index >= text.length) return null;
    var sign = 1;
    if (text[index] == '-') {
      sign = -1;
      index++;
    }
    final digitStart = index;
    while (index < text.length && _isDigit(text[index])) {
      index++;
    }
    if (index == digitStart) return null;
    return (sign * int.parse(text.substring(digitStart, index)), index);
  }

  static bool _isDigit(String char) =>
      char.length == 1 &&
      char.codeUnitAt(0) >= 0x30 &&
      char.codeUnitAt(0) <= 0x39;

  static bool _startsWith(String text, int start, String prefix) {
    if (start + prefix.length > text.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (text.codeUnitAt(start + i) != prefix.codeUnitAt(i)) return false;
    }
    return true;
  }
}

/// Accumulates terms into a single factor, dimension, and offset.
class _CombinedUnit {
  final Dimension dimension;
  final double factor;
  final double offset;

  const _CombinedUnit(this.dimension, this.factor, this.offset);
}

/// A parsed unit expression made of resolved terms.
class _UnitExpression {  final List<_UnitTerm> terms;

  const _UnitExpression(this.terms);

  String? get affineError =>
      'Affine temperature units such as °C or °F must stand alone.';

  /// Combines terms into one factor and dimension, or null when affine
  /// temperature units appear in a compound expression.
  _CombinedUnit? combine() {
    var factor = 1.0;
    var dimension = Dimension.dimensionless;
    var offset = 0.0;
    final affine = terms.where((t) => t.def.isAffine).toList();
    if (affine.isNotEmpty) {
      if (terms.length != 1 || affine.first.exponent != 1) return null;
      final term = terms.single;
      return _CombinedUnit(
        term.def.dimension,
        term.def.factor,
        term.def.offset,
      );
    }
    for (final term in terms) {
      factor *= pow(term.def.factor, term.exponent).toDouble();
      dimension = dimension + term.def.dimension.scale(term.exponent);
    }
    return _CombinedUnit(dimension, factor, offset);
  }

  @override
  String toString() {
    final positive = <String>[];
    final negative = <String>[];
    for (final term in terms) {
      final label = term.exponent.abs() == 1
          ? term.raw
          : '${term.raw}^${term.exponent.abs()}';
      (term.exponent >= 0 ? positive : negative).add(label);
    }
    final pos = positive.join('·');
    final neg = negative.join('·');
    if (pos.isEmpty) return '1/$neg';
    if (neg.isEmpty) return pos;
    return '$pos/$neg';
  }
}

/// A candidate unit match at one position of the input.
class _Candidate {
  final String raw;
  final UnitDef def;
  final int end;
  final int length;

  const _Candidate(this.raw, this.def, this.end, this.length);
}
