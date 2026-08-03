import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../core/quantity_text.dart';
import '../../core/requirement.dart';
import '../widgets/quantity_field.dart';

/// Form data collected by the requirement dialog.
class RequirementDraft {
  const RequirementDraft({
    required this.statement,
    required this.category,
    required this.priority,
    required this.status,
    required this.owner,
    required this.rationale,
    required this.quantity,
  });

  final String statement;
  final RequirementCategory category;
  final Priority priority;
  final RequirementStatus status;
  final String owner;
  final String rationale;
  final QuantityText quantity;
}

/// A dialog that captures or edits a requirement.
class RequirementDialog extends StatefulWidget {
  const RequirementDialog({super.key, this.existing});

  final Requirement? existing;

  @override
  State<RequirementDialog> createState() => _RequirementDialogState();
}

class _RequirementDialogState extends State<RequirementDialog> {
  late final TextEditingController _statement;
  late final TextEditingController _owner;
  late final TextEditingController _rationale;
  late final TextEditingController _quantity;
  late RequirementCategory _category;
  late Priority _priority;
  late RequirementStatus _status;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _statement = TextEditingController(text: existing?.statement ?? '');
    _owner = TextEditingController(text: existing?.owner ?? '');
    _rationale = TextEditingController(text: existing?.rationale ?? '');
    _quantity = TextEditingController(text: existing?.quantity.raw ?? '');
    _category = existing?.category ?? RequirementCategory.functional;
    _priority = existing?.priority ?? Priority.must;
    _status = existing?.status ?? RequirementStatus.draft;
  }

  @override
  void dispose() {
    _statement.dispose();
    _owner.dispose();
    _rationale.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit ${widget.existing!.id}' : 'New requirement'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _statement,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Statement',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter the requirement text.'
                      : null,
                ),
                const SizedBox(height: 12),
                QuantityField(controller: _quantity),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<RequirementCategory>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final value in RequirementCategory.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<Priority>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final value in Priority.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _priority = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<RequirementStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final value in RequirementStatus.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _owner,
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rationale,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Rationale',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
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
    final quantityText = _quantity.text.trim();
    Navigator.of(context).pop(
      RequirementDraft(
        statement: _statement.text.trim(),
        category: _category,
        priority: _priority,
        status: _status,
        owner: _owner.text.trim(),
        rationale: _rationale.text.trim(),
        quantity: quantityText.isEmpty
            ? QuantityText.empty
            : QuantityText(quantityText),
      ),
    );
  }
}

/// Shows the dialog and returns the draft, or null when cancelled.
Future<RequirementDraft?> showRequirementDialog(
  BuildContext context, {
  Requirement? existing,
}) {
  return showDialog<RequirementDraft>(
    context: context,
    builder: (context) => RequirementDialog(existing: existing),
  );
}
