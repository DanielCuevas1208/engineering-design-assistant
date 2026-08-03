import 'package:flutter/material.dart';

import '../../core/requirement.dart';
import '../dialogs/requirement_dialog.dart';
import '../../store/brief_store.dart';
import '../widgets/common_widgets.dart';

/// Lists, adds, edits, and removes requirements.
class RequirementsPage extends StatelessWidget {
  const RequirementsPage({super.key, required this.store});

  final BriefStore store;

  Future<void> _add(BuildContext context) async {
    final draft = await showRequirementDialog(context);
    if (draft == null) return;
    await store.addRequirement(
      statement: draft.statement,
      category: draft.category,
      priority: draft.priority,
      status: draft.status,
      owner: draft.owner,
      rationale: draft.rationale,
      quantity: draft.quantity,
    );
  }

  Future<void> _edit(BuildContext context, Requirement requirement) async {
    final draft = await showRequirementDialog(context, existing: requirement);
    if (draft == null) return;
    await store.updateRequirement(
      requirement.copyWith(
        statement: draft.statement,
        category: draft.category,
        priority: draft.priority,
        status: draft.status,
        owner: draft.owner,
        rationale: draft.rationale,
        quantity: draft.quantity,
      ),
    );
  }

  Future<void> _remove(BuildContext context, Requirement requirement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${requirement.id}?'),
        content: Text(requirement.statement),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await store.removeRequirement(requirement.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final requirements = store.brief.requirements;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Requirements',
                subtitle:
                    '${requirements.length} captured. Each requirement can '
                    'carry a measurable value with a unit.',
                actions: [
                  FilledButton.icon(
                    onPressed: () => _add(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New requirement'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: requirements.isEmpty
                    ? const EmptyState(
                        icon: Icons.checklist_outlined,
                        title: 'No requirements yet',
                        message:
                            'Capture the first requirement for this '
                            'project.',
                      )
                    : ListView.separated(
                        itemCount: requirements.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _RequirementCard(
                          requirement: requirements[index],
                          onEdit: () => _edit(context, requirements[index]),
                          onDelete: () => _remove(context, requirements[index]),
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

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({
    required this.requirement,
    required this.onEdit,
    required this.onDelete,
  });

  final Requirement requirement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 76,
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                requirement.id,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requirement.statement,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Tag(label: requirement.category.label),
                      Tag(label: requirement.priority.label),
                      Tag(label: requirement.status.label),
                      if (!requirement.quantity.isEmpty)
                        Tag(
                          label: requirement.quantity.raw,
                          color: scheme.tertiaryContainer,
                        ),
                    ],
                  ),
                  if (requirement.owner.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Owner: ${requirement.owner}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (requirement.rationale.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      requirement.rationale,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
