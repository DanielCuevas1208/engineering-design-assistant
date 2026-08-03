import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:stream_channel/stream_channel.dart';

import '../core/design_brief.dart';
import '../core/enums.dart';
import '../core/quantity_text.dart';
import '../store/brief_store.dart';

const String _toolName = 'engineering-design-assistant';
const String _toolVersion = '0.1.0';

/// An MCP server that exposes the Engineering Design Assistant.
///
/// EngineerKit clients spawn this server over stdio and call its tools to
/// capture requirements, check units and constraints, and receive a typed
/// design brief handoff.
base class EdaMcpServer extends MCPServer with ToolsSupport {
  EdaMcpServer({required StreamChannel<String> channel, required this.store})
    : super.fromStreamChannel(
        channel,
        implementation: Implementation(
          name: _toolName,
          version: _toolVersion,
          title: 'Engineering Design Assistant',
          description:
              'Captures engineering requirements, checks units and '
              'constraints, and hands a typed design brief to EngineerKit.',
        ),
        instructions:
            'Use add_requirement to capture a requirement. Use '
            'add_constraint to bound it. Use validate_brief to check units '
            'and constraints. Use export_brief to hand off the typed brief.',
      ) {
    _registerTools();
  }

  final BriefStore store;

  /// The last validation report in JSON, or null when none exists.
  Map<String, Object?>? get _validationJson => store.validation?.toJson();

  Map<String, Object?> _summary() {
    final brief = store.brief;
    return {
      'tool': _toolName,
      'version': _toolVersion,
      'schema': designBriefSchemaId,
      'project': {
        'name': brief.projectName,
        'version': brief.projectVersion,
        'purpose': brief.purpose,
      },
      'counts': {
        'requirements': store.requirementCount,
        'constraints': store.constraintCount,
        'assumptions': store.assumptionCount,
        'openAssumptions': store.openAssumptionCount,
      },
      if (_validationJson != null) 'lastValidation': _validationJson,
    };
  }

  void _registerTools() {
    registerTool(
      Tool(
        name: 'get_status',
        title: 'Get the store status',
        description:
            'Returns project metadata, entity counts, and the last '
            'validation summary.',
        inputSchema: Schema.object(),
        outputSchema: Schema.object(),
      ),
      (CallToolRequest request) async => _text(_summary()),
    );

    registerTool(
      Tool(
        name: 'list_requirements',
        title: 'List requirements',
        description:
            'Lists captured requirements, optionally filtered by '
            'status or category.',
        inputSchema: Schema.object(
          properties: {
            'status': Schema.string(
              description:
                  'Filter by status: draft, proposed, approved, '
                  'superseded, or rejected.',
            ),
            'category': Schema.string(
              description: 'Filter by category, for example performance.',
            ),
          },
        ),
      ),
      (CallToolRequest request) async {
        final args = request.arguments ?? const {};
        final status = args['status'] as String?;
        final category = args['category'] as String?;
        final items = [
          for (final requirement in store.brief.requirements)
            if ((status == null || requirement.status.wire == status) &&
                (category == null || requirement.category.wire == category))
              requirement.toJson(),
        ];
        return _text(items);
      },
    );

    registerTool(
      Tool(
        name: 'add_requirement',
        title: 'Add a requirement',
        description:
            'Captures a requirement with an optional measurable '
            'value, for example 100 mm.',
        inputSchema: Schema.object(
          properties: {
            'statement': Schema.string(description: 'The requirement text.'),
            'id': Schema.string(description: 'Optional explicit id.'),
            'category': Schema.string(
              description:
                  'Category: functional, performance, interface, '
                  'environmental, safety, reliability, manufacturing, '
                  'ergonomics, or other.',
            ),
            'priority': Schema.string(
              description: 'Priority: must, should, could, or wont.',
            ),
            'status': Schema.string(
              description:
                  'Status: draft, proposed, approved, superseded, '
                  'or rejected.',
            ),
            'owner': Schema.string(description: 'Owning team or person.'),
            'rationale': Schema.string(
              description:
                  'Why the requirement '
                  'exists.',
            ),
            'value': Schema.string(
              description:
                  'Measurable target with unit, for example '
                  '"100 mm".',
            ),
          },
          required: ['statement'],
        ),
      ),
      (CallToolRequest request) async {
        final args = request.arguments!;
        final requirement = await store.addRequirement(
          id: args['id'] as String?,
          statement: args['statement'] as String,
          category: _category(args['category'] as String?),
          priority: _priority(args['priority'] as String?),
          status: _status(args['status'] as String?),
          owner: args['owner'] as String? ?? '',
          rationale: args['rationale'] as String? ?? '',
          quantity: _quantity(args['value'] as String?),
        );
        return _text(requirement.toJson());
      },
    );

    registerTool(
      Tool(
        name: 'update_requirement',
        title: 'Update a requirement',
        description:
            'Updates fields of a requirement by id. Pass value as an '
            'empty string to clear its quantity.',
        inputSchema: Schema.object(
          properties: {
            'id': Schema.string(description: 'Requirement id.'),
            'statement': Schema.string(),
            'category': Schema.string(),
            'priority': Schema.string(),
            'status': Schema.string(),
            'owner': Schema.string(),
            'rationale': Schema.string(),
            'value': Schema.string(
              description: 'New measurable target, or empty to clear.',
            ),
          },
          required: ['id'],
        ),
      ),
      (CallToolRequest request) async {
        final args = request.arguments!;
        final id = args['id'] as String;
        final existing = store.brief.requirementById(id);
        if (existing == null) {
          return _error('No requirement with id $id.');
        }
        var quantity = existing.quantity;
        if (args['value'] case final value? when value is String) {
          quantity = value.trim().isEmpty
              ? QuantityText.empty
              : QuantityText(value);
        }
        await store.updateRequirement(
          existing.copyWith(
            statement: args['statement'] as String?,
            category: args['category'] is String
                ? _category(args['category'] as String?)
                : null,
            priority: args['priority'] is String
                ? _priority(args['priority'] as String?)
                : null,
            status: args['status'] is String
                ? _status(args['status'] as String?)
                : null,
            owner: args['owner'] as String?,
            rationale: args['rationale'] as String?,
            quantity: quantity,
          ),
        );
        final updated = store.brief.requirementById(id)!;
        return _text(updated.toJson());
      },
    );

    registerTool(
      Tool(
        name: 'delete_requirement',
        title: 'Delete a requirement',
        description:
            'Deletes a requirement and any constraints or '
            'assumptions that reference it.',
        inputSchema: Schema.object(
          properties: {'id': Schema.string(description: 'Requirement id.')},
          required: ['id'],
        ),
      ),
      (CallToolRequest request) async {
        final id = request.arguments!['id'] as String;
        if (store.brief.requirementById(id) == null) {
          return _error('No requirement with id $id.');
        }
        await store.removeRequirement(id);
        return _text({'deleted': id});
      },
    );

    registerTool(
      Tool(
        name: 'list_constraints',
        title: 'List constraints',
        description:
            'Lists constraints, optionally filtered by requirement id.',
        inputSchema: Schema.object(
          properties: {'requirementId': Schema.string()},
        ),
      ),
      (CallToolRequest request) async {
        final requirementId = request.arguments?['requirementId'] as String?;
        final items = [
          for (final constraint in store.brief.constraints)
            if (requirementId == null ||
                constraint.requirementId == requirementId)
              constraint.toJson(),
        ];
        return _text(items);
      },
    );

    registerTool(
      Tool(
        name: 'add_constraint',
        title: 'Add a constraint',
        description:
            'Bounds a requirement. Use kind range with min and max. '
            'Use kind min, max, or equals with value.',
        inputSchema: Schema.object(
          properties: {
            'requirementId': Schema.string(description: 'Requirement id.'),
            'kind': Schema.string(
              description: 'Constraint kind: min, max, range, or equals.',
            ),
            'severity': Schema.string(description: 'Severity: hard or soft.'),
            'description': Schema.string(),
            'value': Schema.string(
              description:
                  'Bound text for min, max, or equals, for example '
                  '"1.8 kN".',
            ),
            'min': Schema.string(description: 'Range lower bound.'),
            'max': Schema.string(description: 'Range upper bound.'),
          },
          required: ['requirementId'],
        ),
      ),
      (CallToolRequest request) async {
        final args = request.arguments!;
        final kind = _kind(args['kind'] as String?);
        final constraint = await store.addConstraint(
          requirementId: args['requirementId'] as String,
          description: args['description'] as String? ?? '',
          kind: kind,
          severity: _severity(args['severity'] as String?),
          value: _quantity(args['value'] as String?),
          min: _quantity(args['min'] as String?),
          max: _quantity(args['max'] as String?),
        );
        return _text(constraint.toJson());
      },
    );

    registerTool(
      Tool(
        name: 'update_constraint',
        title: 'Update a constraint',
        description: 'Updates fields of a constraint by id.',
        inputSchema: Schema.object(
          properties: {
            'id': Schema.string(description: 'Constraint id.'),
            'requirementId': Schema.string(),
            'kind': Schema.string(),
            'severity': Schema.string(),
            'description': Schema.string(),
            'value': Schema.string(),
            'min': Schema.string(),
            'max': Schema.string(),
          },
          required: ['id'],
        ),
      ),
      (CallToolRequest request) async {
        final args = request.arguments!;
        final id = args['id'] as String;
        final existing = store.brief.constraintById(id);
        if (existing == null) {
          return _error('No constraint with id $id.');
        }
        await store.updateConstraint(
          existing.copyWith(
            requirementId: args['requirementId'] as String?,
            description: args['description'] as String?,
            kind: args['kind'] is String
                ? _kind(args['kind'] as String?)
                : null,
            severity: args['severity'] is String
                ? _severity(args['severity'] as String?)
                : null,
            value: args['value'] is String
                ? _quantity(args['value'] as String?)
                : null,
            min: args['min'] is String
                ? _quantity(args['min'] as String?)
                : null,
            max: args['max'] is String
                ? _quantity(args['max'] as String?)
                : null,
          ),
        );
        final updated = store.brief.constraintById(id)!;
        return _text(updated.toJson());
      },
    );

    registerTool(
      Tool(
        name: 'delete_constraint',
        title: 'Delete a constraint',
        description: 'Deletes a constraint by id.',
        inputSchema: Schema.object(
          properties: {'id': Schema.string(description: 'Constraint id.')},
          required: ['id'],
        ),
      ),
      (CallToolRequest request) async {
        final id = request.arguments!['id'] as String;
        if (store.brief.constraintById(id) == null) {
          return _error('No constraint with id $id.');
        }
        await store.removeConstraint(id);
        return _text({'deleted': id});
      },
    );

    registerTool(
      Tool(
        name: 'list_assumptions',
        title: 'List assumptions',
        description: 'Lists assumptions, optionally filtered by status.',
        inputSchema: Schema.object(
          properties: {
            'status': Schema.string(
              description: 'Filter by status: open, validated, or superseded.',
            ),
          },
        ),
      ),
      (CallToolRequest request) async {
        final status = request.arguments?['status'] as String?;
        final items = [
          for (final assumption in store.brief.assumptions)
            if (status == null || assumption.status.wire == status)
              assumption.toJson(),
        ];
        return _text(items);
      },
    );

    registerTool(
      Tool(
        name: 'add_assumption',
        title: 'Add an assumption',
        description:
            'Records an assumption that must hold for the design to '
            'be valid.',
        inputSchema: Schema.object(
          properties: {
            'statement': Schema.string(description: 'The assumption text.'),
            'owner': Schema.string(),
            'requirementId': Schema.string(
              description: 'Requirement this assumption affects, when known.',
            ),
            'rationale': Schema.string(),
          },
          required: ['statement'],
        ),
      ),
      (CallToolRequest request) async {
        final args = request.arguments!;
        final assumption = await store.addAssumption(
          statement: args['statement'] as String,
          owner: args['owner'] as String? ?? '',
          requirementId: args['requirementId'] as String?,
          rationale: args['rationale'] as String? ?? '',
        );
        return _text(assumption.toJson());
      },
    );

    registerTool(
      Tool(
        name: 'update_assumption_status',
        title: 'Update an assumption status',
        description: 'Marks an assumption open, validated, or superseded.',
        inputSchema: Schema.object(
          properties: {
            'id': Schema.string(description: 'Assumption id.'),
            'status': Schema.string(
              description: 'Status: open, validated, or superseded.',
            ),
          },
          required: ['id', 'status'],
        ),
      ),
      (CallToolRequest request) async {
        final args = request.arguments!;
        final id = args['id'] as String;
        final existing = store.brief.assumptionById(id);
        if (existing == null) {
          return _error('No assumption with id $id.');
        }
        final status = _assumptionStatus(args['status'] as String);
        await store.updateAssumption(existing.copyWith(status: status));
        final updated = store.brief.assumptionById(id)!;
        return _text(updated.toJson());
      },
    );

    registerTool(
      Tool(
        name: 'delete_assumption',
        title: 'Delete an assumption',
        description: 'Deletes an assumption by id.',
        inputSchema: Schema.object(
          properties: {'id': Schema.string(description: 'Assumption id.')},
          required: ['id'],
        ),
      ),
      (CallToolRequest request) async {
        final id = request.arguments!['id'] as String;
        if (store.brief.assumptionById(id) == null) {
          return _error('No assumption with id $id.');
        }
        await store.removeAssumption(id);
        return _text({'deleted': id});
      },
    );

    registerTool(
      Tool(
        name: 'convert_quantity',
        title: 'Convert a quantity',
        description:
            'Converts a value between compatible units, for example '
            '"2.5 kN" to "N".',
        inputSchema: Schema.object(
          properties: {
            'value': Schema.string(
              description: 'Value with unit, for example "2.5 kN".',
            ),
            'to': Schema.string(description: 'Target unit, for example "N".'),
          },
          required: ['value', 'to'],
        ),
      ),
      (CallToolRequest request) async {
        final args = request.arguments!;
        final parsed = store.engine.parse(args['value'] as String);
        if (parsed.quantity == null) {
          return _error(parsed.error!);
        }
        final result = store.engine.convert(
          parsed.quantity!,
          args['to'] as String,
        );
        if (result.value == null) {
          return _error(result.error!);
        }
        return _text({
          'value': result.value,
          'unit': args['to'],
          'siValue': parsed.quantity!.siValue,
          'dimension': parsed.quantity!.dimension.siLabel,
        });
      },
    );

    registerTool(
      Tool(
        name: 'validate_brief',
        title: 'Validate the brief',
        description: 'Checks every constraint and unit, then lists all issues.',
        inputSchema: Schema.object(),
        outputSchema: Schema.object(),
      ),
      (CallToolRequest request) async {
        final report = store.runValidation();
        return _text(report.toJson());
      },
    );

    registerTool(
      Tool(
        name: 'export_brief',
        title: 'Export the design brief',
        description:
            'Returns the typed design brief as JSON for the Engineer '
            'MCP handoff.',
        inputSchema: Schema.object(
          properties: {
            'includeValidation': Schema.bool(
              description: 'Include the last validation report, if any.',
            ),
          },
        ),
        outputSchema: Schema.object(),
      ),
      (CallToolRequest request) async {
        final args = request.arguments ?? const {};
        final includeValidation = args['includeValidation'] as bool? ?? true;
        final map = store.brief.toJson();
        if (!includeValidation) {
          map.remove('validation');
        }
        return _text(map);
      },
    );
  }

  CallToolResult _text(Object value) {
    return CallToolResult(
      content: [
        TextContent(text: const JsonEncoder.withIndent('  ').convert(value)),
      ],
      structuredContent: value is Map<String, Object?> ? value : null,
    );
  }

  CallToolResult _error(String message) {
    return CallToolResult(isError: true, content: [TextContent(text: message)]);
  }

  static RequirementCategory _category(String? value) =>
      RequirementCategory.fromWire(value);

  static Priority _priority(String? value) => Priority.fromWire(value);

  static RequirementStatus _status(String? value) =>
      RequirementStatus.fromWire(value);

  static ConstraintKind _kind(String? value) => ConstraintKind.fromWire(value);

  static Severity _severity(String? value) => Severity.fromWire(value);

  static AssumptionStatus _assumptionStatus(String value) =>
      AssumptionStatus.fromWire(value);

  static QuantityText _quantity(String? value) {
    if (value == null) return QuantityText.empty;
    final trimmed = value.trim();
    return trimmed.isEmpty ? QuantityText.empty : QuantityText(trimmed);
  }
}
