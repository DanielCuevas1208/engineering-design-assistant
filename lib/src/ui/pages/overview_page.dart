import 'package:flutter/material.dart';

import '../../core/validation.dart';
import '../../store/brief_store.dart';
import '../widgets/common_widgets.dart';

/// The landing page with counts and quick actions.
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.store});

  final BriefStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final report = store.validation;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Overview',
                subtitle:
                    'Project ${store.brief.projectName} '
                    'v${store.brief.projectVersion}.',
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      store.runValidation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Validation ran.')),
                      );
                    },
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Run validation'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  StatCard(
                    label: 'Requirements',
                    value: '${store.requirementCount}',
                    icon: Icons.checklist_outlined,
                  ),
                  StatCard(
                    label: 'Constraints',
                    value: '${store.constraintCount}',
                    icon: Icons.straighten_outlined,
                  ),
                  StatCard(
                    label: 'Assumptions',
                    value: '${store.assumptionCount}',
                    icon: Icons.help_outline,
                  ),
                  StatCard(
                    label: 'Open assumptions',
                    value: '${store.openAssumptionCount}',
                    icon: Icons.lightbulb_outline,
                    accent: Colors.orange.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ValidationSummary(report: report),
              const SizedBox(height: 24),
              Text(
                'Quick actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  _QuickAction(
                    icon: Icons.add,
                    label: 'New requirement',
                    onPressed: () => _goto(context, 1),
                  ),
                  _QuickAction(
                    icon: Icons.add,
                    label: 'New constraint',
                    onPressed: () => _goto(context, 2),
                  ),
                  _QuickAction(
                    icon: Icons.add,
                    label: 'New assumption',
                    onPressed: () => _goto(context, 3),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _goto(BuildContext context, int index) {
    // Pages are owned by the shell. This page only advertises where to go.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Use the navigation rail to open the page.')),
    );
  }
}

class _ValidationSummary extends StatelessWidget {
  const _ValidationSummary({required this.report});

  final ValidationReport? report;

  @override
  Widget build(BuildContext context) {
    final report = this.report;
    final scheme = Theme.of(context).colorScheme;
    final Widget leading;
    final String title;
    final String detail;
    if (report == null) {
      leading = Icon(Icons.pending_outlined, color: scheme.outline);
      title = 'Not validated yet';
      detail = 'Run the constraint and unit checks to see a summary here.';
    } else if (report.passes) {
      leading = Icon(Icons.check_circle_outline, color: Colors.green.shade700);
      title = 'Validation passed';
      detail =
          '${report.requirementCount} requirements, ${report.constraintCount} '
          'constraints, ${report.infoCount} notes.';
    } else {
      leading = Icon(Icons.error_outline, color: scheme.error);
      title = 'Validation found ${report.errorCount} errors';
      detail =
          '${report.warningCount} warnings and ${report.infoCount} notes '
          'also remain. Open the Validation page for details.';
    }
    return Card(
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: Text(detail),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
