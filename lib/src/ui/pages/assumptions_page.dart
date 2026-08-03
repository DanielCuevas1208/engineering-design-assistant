import 'package:flutter/material.dart';

import '../../core/assumption.dart';
import '../../core/enums.dart';
import '../dialogs/assumption_dialog.dart';
import '../../store/brief_store.dart';
import '../widgets/common_widgets.dart';

/// Lists, adds, edits, and resolves assumptions.
class AssumptionsPage extends StatelessWidget {
  const AssumptionsPage({super.key, required this.store});

  final BriefStore store;

  Future<void> _add(BuildContext context) async {
    final draft = await showAssumptionDialog(
      context,
      requirements: [for (final r in store.brief.requirements) r.id],
    );
    if (draft == null) return;
    await store.addAssumption(
      statement: draft.statement,
      owner: draft.owner,
      requirementId: draft.requirementId,
      rationale: draft.rationale,
    );
  }

  Future<void> _edit(BuildContext context, Assumption assumption) async {
    final draft = await showAssumptionDialog(
      context,
      requirements: [for (final r in store.brief.requirements) r.id],
      existing: assumption,
    );
    if (draft == null) return;
    await store.updateAssumption(
      assumption.copyWith(
        statement: draft.statement,
        owner: draft.owner,
        requirementId: draft.requirementId,
        rationale: draft.rationale,
      ),
    );
  }

  Future<void> _cycleStatus(BuildContext context, Assumption assumption) async {
    final statuses = AssumptionStatus.values;
    final index = statuses.indexOf(assumption.status);
    final next = statuses[(index + 1) % statuses.length];
    await store.updateAssumption(assumption.copyWith(status: next));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final assumptions = store.brief.assumptions;
        final open = assumptions
            .where((a) => a.status == AssumptionStatus.open)
            .length;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Assumptions',
                subtitle:
                    '$open of ${assumptions.length} still open. '
                    'Expose them before the handoff.',
                actions: [
                  FilledButton.icon(
                    onPressed: () => _add(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New assumption'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: assumptions.isEmpty
                    ? const EmptyState(
                        icon: Icons.help_outline,
                        title: 'No assumptions yet',
                        message:
                            'Record anything that must hold but is not '
                            'yet proven.',
                      )
                    : ListView.separated(
                        itemCount: assumptions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _AssumptionCard(
                          assumption: assumptions[index],
                          onCycleStatus: () =>
                              _cycleStatus(context, assumptions[index]),
                          onEdit: () => _edit(context, assumptions[index]),
                          onDelete: () => _remove(context, assumptions[index]),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _remove(BuildContext context, Assumption assumption) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${assumption.id}?'),
        content: Text(assumption.statement),
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
      await store.removeAssumption(assumption.id);
    }
  }
}

class _AssumptionCard extends StatelessWidget {
  const _AssumptionCard({
    required this.assumption,
    required this.onCycleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final Assumption assumption;
  final VoidCallback onCycleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color statusColor = switch (assumption.status) {
      AssumptionStatus.open => Colors.orange.shade700,
      AssumptionStatus.validated => Colors.green.shade700,
      AssumptionStatus.superseded => scheme.outline,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, color: statusColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assumption.statement,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Tag(label: assumption.id),
                      Tag(label: assumption.status.label, color: statusColor),
                      if (assumption.requirementId != null)
                        Tag(
                          label: assumption.requirementId!,
                          color: scheme.primaryContainer,
                        ),
                    ],
                  ),
                  if (assumption.owner.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Owner: ${assumption.owner}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (assumption.rationale.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      assumption.rationale,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Advance status',
              onPressed: onCycleStatus,
              icon: const Icon(Icons.done_outline),
            ),
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
