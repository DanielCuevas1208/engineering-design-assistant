import 'package:flutter/material.dart';

/// Form data collected by the project dialog.
class ProjectDraft {
  const ProjectDraft({
    required this.name,
    required this.version,
    required this.purpose,
  });

  final String name;
  final String version;
  final String purpose;
}

/// A dialog that edits project metadata.
class ProjectDialog extends StatefulWidget {
  const ProjectDialog({
    super.key,
    required this.initialName,
    required this.initialVersion,
    required this.initialPurpose,
  });

  final String initialName;
  final String initialVersion;
  final String initialPurpose;

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  late final TextEditingController _name;
  late final TextEditingController _version;
  late final TextEditingController _purpose;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _version = TextEditingController(text: widget.initialVersion);
    _purpose = TextEditingController(text: widget.initialPurpose);
  }

  @override
  void dispose() {
    _name.dispose();
    _version.dispose();
    _purpose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Project details'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Project name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a project name.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _version,
                decoration: const InputDecoration(
                  labelText: 'Version',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purpose,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Purpose',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
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
      ProjectDraft(
        name: _name.text.trim(),
        version: _version.text.trim(),
        purpose: _purpose.text.trim(),
      ),
    );
  }
}

/// Shows the dialog and returns the draft, or null when cancelled.
Future<ProjectDraft?> showProjectDialog(
  BuildContext context, {
  required String name,
  required String version,
  required String purpose,
}) {
  return showDialog<ProjectDraft>(
    context: context,
    builder: (context) => ProjectDialog(
      initialName: name,
      initialVersion: version,
      initialPurpose: purpose,
    ),
  );
}
