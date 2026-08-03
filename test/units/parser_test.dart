import 'package:engineering_design_assistant/src/units/quantity_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = QuantityParser();

  Quantity parse(String text) {
    final result = parser.parse(text);
    if (result.quantity == null) {
      fail('Expected "$text" to parse but got: ${result.error}');
    }
    return result.quantity!;
  }

  group('QuantityParser', () {
    test('parses simple SI quantities', () {
      final q = parse('100 mm');
      expect(q.value, 100);
      expect(q.unit, 'mm');
      expect(q.siValue, closeTo(0.1, 1e-12));
      expect(q.dimension.siLabel, 'm');
    });

    test('parses centi, kilo, and micro prefixes', () {
      expect(parse('2.5 cm').siValue, closeTo(0.025, 1e-12));
      expect(parse('2 kN').siValue, closeTo(2000, 1e-9));
      expect(parse('500 µm').siValue, closeTo(0.0005, 1e-12));
      expect(parse('500 um').siValue, closeTo(0.0005, 1e-12));
    });

    test('parses compound units with division', () {
      final speed = parse('60 mm/s');
      expect(speed.dimension.siLabel, 'm/s');
      expect(speed.siValue, closeTo(0.06, 1e-12));

      final kmh = parse('60 km/h');
      expect(kmh.siValue, closeTo(16.6666667, 1e-6));
    });

    test('parses exponents', () {
      final volume = parse('100 cm3');
      expect(volume.dimension.siLabel, 'm^3');
      expect(volume.siValue, closeTo(1e-4, 1e-12));

      final pressure = parse('2.5 kN/m²');
      expect(pressure.dimension.siLabel, 'kg/(m·s^2)');
      expect(pressure.siValue, closeTo(2500, 1e-9));
    });

    test('parses temperature scales as affine', () {
      final celsius = parse('50 °C');
      expect(celsius.isAffine, isTrue);
      expect(celsius.siValue, closeTo(323.15, 1e-9));

      final fahrenheit = parse('98 °F');
      expect(fahrenheit.siValue, closeTo(309.8166667, 1e-6));
    });

    test('parses imperial and other units', () {
      expect(parse('12 in').siValue, closeTo(0.3048, 1e-12));
      expect(parse('1 lb').siValue, closeTo(0.45359237, 1e-12));
      expect(parse('1 gal').siValue, closeTo(0.003785411784, 1e-12));
      expect(parse('3 lbf').siValue, closeTo(13.344664846, 1e-9));
      expect(parse('45 rpm').siValue, closeTo(0.75, 1e-9));
      expect(parse('30 %').siValue, closeTo(0.3, 1e-12));
      expect(parse('1.5 kg').siValue, closeTo(1.5, 1e-12));
    });

    test('rejects missing values and missing units', () {
      expect(parser.parse('').error, isNotNull);
      expect(parser.parse('mm').error, isNotNull);
      expect(parser.parse('100').error, isNotNull);
    });

    test('rejects unknown units', () {
      expect(parser.parse('62 dB(A)').error, isNotNull);
      expect(parser.parse('100 widgets').error, isNotNull);
    });

    test('rejects affine units in compound expressions', () {
      expect(parser.parse('5 °C/s').error, isNotNull);
    });

    test('rejects trailing garbage', () {
      expect(parser.parse('100 mm xyz').error, isNotNull);
    });

    test('handles negative and exponent notation values', () {
      expect(parse('-10 °C').siValue, closeTo(263.15, 1e-9));
      expect(parse('1e3 mm').siValue, closeTo(1.0, 1e-9));
    });
  });
}
