import 'package:flutter/material.dart';

import '../../core/constraint.dart';
import '../../core/enums.dart';
import '../dialogs/constraint_dialog.dart';
import '../../store/brief_store.dart';
import '../widgets/common_widgets.dart';

/// Lists, adds, edits, and removes constraints.
class ConstraintsPage extends StatelessWidget {
  const ConstraintsPage({super.key, required this.store});

  final BriefStore store;

  Future<void> _add(BuildContext context) async {
    final requirementIds = [
      for (final requirement in store.brief.requirements) requirement.id,
    ];
    if (requirementIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture a requirement first.')),
      );
      return;
    }
    final draft = await showConstraintDialog(
      context,
      requirements: requirementIds,
    );
    if (draft == null) return;
    await store.addConstraint(
      requirementId: draft.requirementId,
      description: draft.description,
      kind: draft.kind,
      severity: draft.severity,
      value: draft.value,
      min: draft.min,
      max: draft.max,
    );
  }

  Future<void> _edit(BuildContext context, Constraint constraint) async {
    final draft = await showConstraintDialog(
      context,
      requirements: [
        for (final requirement in store.brief.requirements) requirement.id,
      ],
      existing: constraint,
    );
    if (draft == null) return;
    await store.updateConstraint(
      constraint.copyWith(
        requirementId: draft.requirementId,
        description: draft.description,
        kind: draft.kind,
        severity: draft.severity,
        value: draft.value,
        min: draft.min,
        max: draft.max,
      ),
    );
  }

  Future<void> _remove(BuildContext context, Constraint constraint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${constraint.id}?'),
        content: Text(
          constraint.description.isEmpty
              ? constraint.requirementId
              : constraint.description,
        ),
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
      await store.removeConstraint(constraint.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final constraints = store.brief.constraints;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Constraints',
                subtitle:
                    'Bounds on requirement values, checked by the '
                    'validator.',
                actions: [
                  FilledButton.icon(
                    onPressed: () => _add(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New constraint'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: constraints.isEmpty
                    ? const EmptyState(
                        icon: Icons.straighten_outlined,
                        title: 'No constraints yet',
                        message:
                            'Bound a requirement value so the validator '
                            'can check it.',
                      )
                    : ListView.separated(
                        itemCount: constraints.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _ConstraintCard(
                          constraint: constraints[index],
                          onEdit: () => _edit(context, constraints[index]),
                          onDelete: () => _remove(context, constraints[index]),
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

class _ConstraintCard extends StatelessWidget {
  const _ConstraintCard({
    required this.constraint,
    required this.onEdit,
    required this.onDelete,
  });

  final Constraint constraint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bounds = constraint.bounds.entries
        .where((entry) => !entry.value.isEmpty)
        .map((entry) => '${entry.key} ${entry.value.raw}')
        .join(', ');
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
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                constraint.id,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    constraint.requirementId,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    constraint.description.isEmpty
                        ? '${constraint.kindLabel} bound'
                        : constraint.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Tag(label: constraint.kind.wire),
                      Tag(
                        label: constraint.severity.label,
                        color: constraint.severity == Severity.hard
                            ? scheme.errorContainer
                            : scheme.tertiaryContainer,
                      ),
                      if (bounds.isNotEmpty)
                        Tag(label: bounds, color: scheme.primaryContainer),
                    ],
                  ),
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
