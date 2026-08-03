import 'package:flutter/material.dart';

import '../../core/assumption.dart';

/// Form data collected by the assumption dialog.
class AssumptionDraft {
  const AssumptionDraft({
    required this.statement,
    required this.owner,
    required this.requirementId,
    required this.rationale,
  });

  final String statement;
  final String owner;
  final String? requirementId;
  final String rationale;
}

/// A dialog that captures or edits an assumption.
class AssumptionDialog extends StatefulWidget {
  const AssumptionDialog({
    super.key,
    required this.requirements,
    this.existing,
  });

  final List<String> requirements;
  final Assumption? existing;

  @override
  State<AssumptionDialog> createState() => _AssumptionDialogState();
}

class _AssumptionDialogState extends State<AssumptionDialog> {
  late final TextEditingController _statement;
  late final TextEditingController _owner;
  late final TextEditingController _rationale;
  String? _requirementId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _statement = TextEditingController(text: existing?.statement ?? '');
    _owner = TextEditingController(text: existing?.owner ?? '');
    _rationale = TextEditingController(text: existing?.rationale ?? '');
    _requirementId = existing?.requirementId;
  }

  @override
  void dispose() {
    _statement.dispose();
    _owner.dispose();
    _rationale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'New assumption'
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
                TextFormField(
                  controller: _statement,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Assumption',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'State the assumption.'
                      : null,
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
                DropdownButtonFormField<String?>(
                  initialValue: _requirementId,
                  decoration: const InputDecoration(
                    labelText: 'Affects requirement (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None'),
                    ),
                    for (final id in widget.requirements)
                      DropdownMenuItem<String?>(value: id, child: Text(id)),
                  ],
                  onChanged: (value) {
                    setState(() => _requirementId = value);
                  },
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
    Navigator.of(context).pop(
      AssumptionDraft(
        statement: _statement.text.trim(),
        owner: _owner.text.trim(),
        requirementId: _requirementId,
        rationale: _rationale.text.trim(),
      ),
    );
  }
}

/// Shows the dialog and returns the draft, or null when cancelled.
Future<AssumptionDraft?> showAssumptionDialog(
  BuildContext context, {
  required List<String> requirements,
  Assumption? existing,
}) {
  return showDialog<AssumptionDraft>(
    context: context,
    builder: (context) =>
        AssumptionDialog(requirements: requirements, existing: existing),
  );
}
