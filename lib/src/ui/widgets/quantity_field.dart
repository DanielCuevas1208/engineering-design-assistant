import 'package:flutter/material.dart';

import '../../units/unit_engine.dart';

/// A text field for a value with a unit.
///
/// Shows live feedback about the parsed quantity. The parent reads the raw
/// text through [controller].
class QuantityField extends StatefulWidget {
  const QuantityField({
    super.key,
    required this.controller,
    this.label = 'Quantity',
    this.hintText,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  State<QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<QuantityField> {
  static const _engine = UnitEngine();
  String? _error;
  String? _help;

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      _error = null;
      _help = 'Example: 100 mm, 2.5 kN, 60 mm/s, 50 °C';
    } else {
      final result = _engine.parse(text);
      if (result.quantity == null) {
        _error = result.error;
        _help = null;
      } else {
        _error = null;
        _help = _engine.describe(result.quantity!);
      }
    }

    return TextFormField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        errorText: _error,
        helperText: _help,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (value) {
        setState(() {});
        widget.onChanged?.call(value);
      },
    );
  }
}
