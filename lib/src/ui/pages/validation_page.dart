import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../core/validation.dart';
import '../../store/brief_store.dart';
import '../widgets/common_widgets.dart';

/// Runs and presents the constraint and unit checks.
class ValidationPage extends StatelessWidget {
  const ValidationPage({super.key, required this.store});

  final BriefStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final report = store.validation;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Validation',
                subtitle: report == null
                    ? 'Run the checks to review units and constraints.'
                    : 'Last run ${report.generatedAt.toLocal()}.',
                actions: [
                  FilledButton.icon(
                    onPressed: () => store.runValidation(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Run again'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (report == null)
                const Expanded(
                  child: EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'No report yet',
                    message: 'Run the validation checks from the toolbar.',
                  ),
                )
              else ...[
                _SummaryBar(report: report),
                const SizedBox(height: 16),
                Expanded(
                  child: report.issues.isEmpty
                      ? const EmptyState(
                          icon: Icons.check_circle_outline,
                          title: 'No issues found',
                          message:
                              'Every unit is recognized and every '
                              'constraint is satisfied.',
                        )
                      : _IssueList(issues: report.issues),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.report});

  final ValidationReport report;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        StatCard(
          label: 'Result',
          value: report.passes ? 'PASS' : 'FAIL',
          icon: report.passes
              ? Icons.check_circle_outline
              : Icons.error_outline,
          accent: report.passes ? Colors.green.shade700 : null,
        ),
        StatCard(
          label: 'Errors',
          value: '${report.errorCount}',
          icon: Icons.cancel_outlined,
          accent: Colors.red.shade700,
        ),
        StatCard(
          label: 'Warnings',
          value: '${report.warningCount}',
          icon: Icons.warning_amber_outlined,
          accent: Colors.orange.shade700,
        ),
        StatCard(
          label: 'Notes',
          value: '${report.infoCount}',
          icon: Icons.info_outline,
        ),
      ],
    );
  }
}

class _IssueList extends StatelessWidget {
  const _IssueList({required this.issues});

  final List<ValidationIssue> issues;

  @override
  Widget build(BuildContext context) {
    final order = {
      IssueSeverity.error: 0,
      IssueSeverity.warning: 1,
      IssueSeverity.info: 2,
    };
    final sorted = [...issues]
      ..sort((a, b) => order[a.severity]!.compareTo(order[b.severity]!));
    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _IssueCard(issue: sorted[index]),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final ValidationIssue issue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color) = switch (issue.severity) {
      IssueSeverity.error => (Icons.error_outline, scheme.error),
      IssueSeverity.warning => (
        Icons.warning_amber_outlined,
        Colors.orange.shade700,
      ),
      IssueSeverity.info => (Icons.info_outline, scheme.primary),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        issue.severity.wire.toUpperCase(),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: color),
                      ),
                      Text(
                        issue.code,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (issue.entityId != null) Tag(label: issue.entityId!),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(issue.message),
                  if (issue.detail != null && issue.detail!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      issue.detail!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
