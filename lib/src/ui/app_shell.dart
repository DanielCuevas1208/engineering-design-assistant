import 'package:flutter/material.dart';

import '../store/brief_store.dart';
import 'pages/assumptions_page.dart';
import 'pages/brief_page.dart';
import 'pages/constraints_page.dart';
import 'pages/overview_page.dart';
import 'pages/requirements_page.dart';
import 'pages/validation_page.dart';

/// The desktop shell with navigation and the shared app bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final BriefStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final brief = widget.store.brief;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(brief.projectName),
                Text(
                  'v${brief.projectVersion}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            actions: [
              _ValidationChip(store: widget.store),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => widget.store.runValidation(),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Validate'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (value) {
                  setState(() => _index = value);
                },
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Overview'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.checklist_outlined),
                    selectedIcon: Icon(Icons.checklist),
                    label: Text('Requirements'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.straighten_outlined),
                    selectedIcon: Icon(Icons.straighten),
                    label: Text('Constraints'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.help_outline),
                    selectedIcon: Icon(Icons.help),
                    label: Text('Assumptions'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.fact_check_outlined),
                    selectedIcon: Icon(Icons.fact_check),
                    label: Text('Validation'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.description_outlined),
                    selectedIcon: Icon(Icons.description),
                    label: Text('Brief'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: [
                    OverviewPage(store: widget.store),
                    RequirementsPage(store: widget.store),
                    ConstraintsPage(store: widget.store),
                    AssumptionsPage(store: widget.store),
                    ValidationPage(store: widget.store),
                    BriefPage(store: widget.store),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ValidationChip extends StatelessWidget {
  const _ValidationChip({required this.store});

  final BriefStore store;

  @override
  Widget build(BuildContext context) {
    final report = store.validation;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color;
    final String label;
    if (report == null) {
      color = scheme.outline;
      label = 'Not validated';
    } else if (report.passes) {
      color = Colors.green.shade700;
      label = 'Pass';
    } else {
      color = scheme.error;
      label = '${report.errorCount} error${report.errorCount == 1 ? '' : 's'}';
    }
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium,
      visualDensity: VisualDensity.compact,
    );
  }
}
