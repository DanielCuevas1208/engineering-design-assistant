import 'package:flutter/material.dart';

import '../../core/constraint.dart';
import '../../core/enums.dart';
import '../../core/quantity_text.dart';
import '../widgets/quantity_field.dart';

/// Form data collected by the constraint dialog.
class ConstraintDraft {
  const ConstraintDraft({
    required this.requirementId,
    required this.description,
    required this.kind,
    required this.severity,
    required this.value,
    required this.min,
    required this.max,
  });

  final String requirementId;
  final String description;
  final ConstraintKind kind;
  final Severity severity;
  final QuantityText value;
  final QuantityText min;
  final QuantityText max;
}

/// A dialog that captures or edits a constraint.
class ConstraintDialog extends StatefulWidget {
  const ConstraintDialog({
    super.key,
    required this.requirements,
    this.existing,
  });

  final List<String> requirements;
  final Constraint? existing;

  @override
  State<ConstraintDialog> createState() => _ConstraintDialogState();
}

class _ConstraintDialogState extends State<ConstraintDialog> {
  late final TextEditingController _description;
  late final TextEditingController _value;
  late final TextEditingController _min;
  late final TextEditingController _max;
  late String _requirementId;
  late ConstraintKind _kind;
  late Severity _severity;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _description = TextEditingController(text: existing?.description ?? '');
    _value = TextEditingController(text: existing?.value.raw ?? '');
    _min = TextEditingController(text: existing?.min.raw ?? '');
    _max = TextEditingController(text: existing?.max.raw ?? '');
    _requirementId =
        existing?.requirementId ??
        (widget.requirements.isNotEmpty ? widget.requirements.first : '');
    _kind = existing?.kind ?? ConstraintKind.max;
    _severity = existing?.severity ?? Severity.hard;
  }

  @override
  void dispose() {
    _description.dispose();
    _value.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRange = _kind == ConstraintKind.range;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'New constraint'
            : 'Edit ${widget.existing!.id}',
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _requirementId,
                  decoration: const InputDecoration(
                    labelText: 'Requirement',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final id in widget.requirements)
                      DropdownMenuItem(value: id, child: Text(id)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _requirementId = value);
                    }
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Pick a requirement.'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ConstraintKind>(
                        initialValue: _kind,
                        decoration: const InputDecoration(
                          labelText: 'Kind',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final value in ConstraintKind.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.wire),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _kind = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<Severity>(
                        initialValue: _severity,
                        decoration: const InputDecoration(
                          labelText: 'Severity',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final value in Severity.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _severity = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (isRange) ...[
                  Row(
                    children: [
                      Expanded(
                        child: QuantityField(
                          controller: _min,
                          label: 'Minimum',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuantityField(
                          controller: _max,
                          label: 'Maximum',
                        ),
                      ),
                    ],
                  ),
                ] else
                  QuantityField(
                    controller: _value,
                    label: 'Bound',
                    hintText: 'Example: 1.8 kN',
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_requirementId.isEmpty) return;
    QuantityText read(TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty ? QuantityText.empty : QuantityText(text);
    }

    Navigator.of(context).pop(
      ConstraintDraft(
        requirementId: _requirementId,
        description: _description.text.trim(),
        kind: _kind,
        severity: _severity,
        value: read(_value),
        min: read(_min),
        max: read(_max),
      ),
    );
  }
}

/// Shows the dialog and returns the draft, or null when cancelled.
Future<ConstraintDraft?> showConstraintDialog(
  BuildContext context, {
  required List<String> requirements,
  Constraint? existing,
}) {
  return showDialog<ConstraintDraft>(
    context: context,
    builder: (context) =>
        ConstraintDialog(requirements: requirements, existing: existing),
  );
}
