import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_brief.dart';
import '../../sample/sample_brief.dart';
import '../dialogs/project_dialog.dart';
import '../export_actions.dart';
import '../../store/brief_store.dart';
import '../widgets/common_widgets.dart';

/// Reviews the project, edits metadata, and exports the typed handoff.
class BriefPage extends StatelessWidget {
  const BriefPage({super.key, required this.store});

  final BriefStore store;

  Future<void> _editProject(BuildContext context) async {
    final draft = await showProjectDialog(
      context,
      name: store.brief.projectName,
      version: store.brief.projectVersion,
      purpose: store.brief.purpose,
    );
    if (draft == null) return;
    await store.updateProject(
      name: draft.name,
      version: draft.version,
      purpose: draft.purpose,
    );
  }

  Future<void> _export(BuildContext context) async {
    final file = await writeBriefExport(store);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Wrote handoff to ${file.path}')));
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Brief JSON copied to the clipboard.')),
    );
  }

  Future<void> _loadSample(BuildContext context) async {
    await store.replaceWith(SampleBrief.build());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loaded the sample linear actuator brief.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final brief = store.brief;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Design brief',
                subtitle: 'The typed handoff for EngineerKit tools.',
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => _loadSample(context),
                    icon: const Icon(Icons.science_outlined, size: 18),
                    label: const Text('Load sample'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _editProject(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit project'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              brief.projectName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Version ${brief.projectVersion} · schema '
                              '$designBriefSchemaId',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (brief.purpose.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(brief.purpose),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.tonalIcon(
                        onPressed: () => _copy(context),
                        icon: const Icon(Icons.copy_all_outlined, size: 18),
                        label: const Text('Copy JSON'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _export(context),
                        icon: const Icon(Icons.save_alt_outlined, size: 18),
                        label: const Text('Export to file'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Export path: ${defaultExportPath(brief)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    store.exportJson(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
