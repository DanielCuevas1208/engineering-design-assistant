import 'package:engineering_design_assistant/src/units/quantity_parser.dart';
import 'package:engineering_design_assistant/src/units/unit_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = UnitEngine();

  Quantity parse(String text) {
    final result = engine.parse(text);
    if (result.quantity == null) {
      fail('Expected "$text" to parse but got: ${result.error}');
    }
    return result.quantity!;
  }

  group('UnitEngine', () {
    test('converts within the same dimension', () {
      final result = engine.convert(parse('2.5 kN'), 'N');
      expect(result.value, closeTo(2500, 1e-9));

      final millimetres = engine.convert(parse('100 mm'), 'cm');
      expect(millimetres.value, closeTo(10, 1e-12));

      final speed = engine.convert(parse('60 km/h'), 'm/s');
      expect(speed.value, closeTo(16.6666667, 1e-6));
    });

    test('converts between affine temperature scales', () {
      final result = engine.convert(parse('98 °F'), '°C');
      expect(result.value, closeTo(36.6667, 1e-3));

      final kelvin = engine.convert(parse('50 °C'), 'K');
      expect(kelvin.value, closeTo(323.15, 1e-9));
    });

    test('rejects incompatible dimensions', () {
      final result = engine.convert(parse('2 kN'), 'mm');
      expect(result.error, contains('Incompatible dimensions'));
    });

    test('rejects a bad target unit', () {
      final result = engine.convert(parse('2 kN'), 'widgets');
      expect(result.error, isNotNull);
    });

    test('reports dimension compatibility', () {
      expect(engine.areCompatible(parse('60 mm/s'), parse('30 km/h')), isTrue);
      expect(engine.areCompatible(parse('2 kN'), parse('100 mm')), isFalse);
      expect(engine.areCompatible(parse('50 °C'), parse('298 K')), isTrue);
    });

    test('describes quantities with their SI value', () {
      expect(engine.describe(parse('2 kN')), '2 kN (2000 N)');
    });
  });
}
