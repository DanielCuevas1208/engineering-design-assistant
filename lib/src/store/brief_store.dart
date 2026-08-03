import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/assumption.dart';
import '../core/constraint.dart';
import '../core/design_brief.dart';
import '../core/enums.dart';
import '../core/ids.dart';
import '../core/quantity_text.dart';
import '../core/requirement.dart';
import '../core/validation.dart';
import '../db/brief_repository.dart';
import '../units/unit_engine.dart';
import '../validation/constraint_checker.dart';

/// Holds the design brief and coordinates persistence and validation.
///
/// The Flutter UI and the MCP server share this store, so both always see
/// the same data.
class BriefStore extends ChangeNotifier {
  BriefStore({
    required this.repository,
    this.engine = const UnitEngine(),
    ConstraintChecker? checker,
  }) : checker = checker ?? ConstraintChecker();

  final BriefRepository repository;
  final UnitEngine engine;
  final ConstraintChecker checker;

  DesignBrief _brief = DesignBrief.empty();
  bool _loaded = false;

  DesignBrief get brief => _brief;

  bool get loaded => _loaded;

  /// The last validation report, or null before the first run.
  ValidationReport? get validation => _brief.validation;

  int get requirementCount => _brief.requirements.length;
  int get constraintCount => _brief.constraints.length;
  int get assumptionCount => _brief.assumptions.length;
  int get openAssumptionCount => _brief.openAssumptionCount;

  /// Loads the persisted brief.
  Future<void> init() async {
    _brief = await repository.loadBrief();
    _loaded = true;
    notifyListeners();
  }

  /// Applies the state change and persists it.
  Future<void> _persist(DesignBrief next) async {
    _brief = next;
    notifyListeners();
    await repository.saveBrief(next);
  }

  DateTime get _now => DateTime.now().toUtc();

  /// Updates the project metadata.
  Future<void> updateProject({
    required String name,
    required String version,
    required String purpose,
  }) {
    return _persist(
      _brief.copyWith(
        projectName: name,
        projectVersion: version,
        purpose: purpose,
        updatedAt: _now,
        clearValidation: true,
      ),
    );
  }

  /// Adds a requirement and returns it with its generated id.
  Future<Requirement> addRequirement({
    String? id,
    required String statement,
    RequirementCategory category = RequirementCategory.functional,
    Priority priority = Priority.unassigned,
    RequirementStatus status = RequirementStatus.draft,
    String owner = '',
    String rationale = '',
    QuantityText quantity = QuantityText.empty,
  }) async {
    final nextId =
        id ?? IdGenerator.next('REQ', _brief.requirements.map((r) => r.id));
    final requirement = Requirement(
      id: nextId,
      statement: statement,
      category: category,
      priority: priority,
      status: status,
      owner: owner,
      rationale: rationale,
      quantity: quantity,
    );
    await _persist(
      _brief.copyWith(
        requirements: [..._brief.requirements, requirement],
        updatedAt: _now,
        clearValidation: true,
      ),
    );
    return requirement;
  }

  /// Replaces a requirement with the same id.
  Future<void> updateRequirement(Requirement requirement) async {
    final requirements = [
      for (final existing in _brief.requirements)
        existing.id == requirement.id ? requirement : existing,
    ];
    await _persist(
      _brief.copyWith(
        requirements: requirements,
        updatedAt: _now,
        clearValidation: true,
      ),
    );
  }

  /// Removes a requirement and anything that depends on it.
  Future<void> removeRequirement(String id) async {
    await _persist(
      _brief.copyWith(
        requirements: _brief.requirements.where((r) => r.id != id).toList(),
        constraints: _brief.constraints
            .where((c) => c.requirementId != id)
            .toList(),
        assumptions: _brief.assumptions
            .where((a) => a.requirementId != id)
            .toList(),
        updatedAt: _now,
        clearValidation: true,
      ),
    );
  }

  /// Adds a constraint and returns it with its generated id.
  Future<Constraint> addConstraint({
    String? id,
    required String requirementId,
    String description = '',
    ConstraintKind kind = ConstraintKind.max,
    Severity severity = Severity.hard,
    QuantityText value = QuantityText.empty,
    QuantityText min = QuantityText.empty,
    QuantityText max = QuantityText.empty,
  }) async {
    final nextId =
        id ?? IdGenerator.next('CON', _brief.constraints.map((c) => c.id));
    final constraint = Constraint(
      id: nextId,
      requirementId: requirementId,
      description: description,
      kind: kind,
      severity: severity,
      value: value,
      min: min,
      max: max,
    );
    await _persist(
      _brief.copyWith(
        constraints: [..._brief.constraints, constraint],
        updatedAt: _now,
        clearValidation: true,
      ),
    );
    return constraint;
  }

  /// Replaces a constraint with the same id.
  Future<void> updateConstraint(Constraint constraint) async {
    await _persist(
      _brief.copyWith(
        constraints: [
          for (final existing in _brief.constraints)
            existing.id == constraint.id ? constraint : existing,
        ],
        updatedAt: _now,
        clearValidation: true,
      ),
    );
  }

  /// Removes a constraint by id.
  Future<void> removeConstraint(String id) async {
    await _persist(
      _brief.copyWith(
        constraints: _brief.constraints.where((c) => c.id != id).toList(),
        updatedAt: _now,
        clearValidation: true,
      ),
    );
  }

  /// Adds an assumption and returns it with its generated id.
  Future<Assumption> addAssumption({
    String? id,
    required String statement,
    String owner = '',
    AssumptionStatus status = AssumptionStatus.open,
    String? requirementId,
    String rationale = '',
  }) async {
    final nextId =
        id ?? IdGenerator.next('ASM', _brief.assumptions.map((a) => a.id));
    final assumption = Assumption(
      id: nextId,
      statement: statement,
      owner: owner,
      status: status,
      requirementId: requirementId,
      rationale: rationale,
    );
    await _persist(
      _brief.copyWith(
        assumptions: [..._brief.assumptions, assumption],
        updatedAt: _now,
        clearValidation: true,
      ),
    );
    return assumption;
  }

  /// Replaces an assumption with the same id.
  Future<void> updateAssumption(Assumption assumption) async {
    await _persist(
      _brief.copyWith(
        assumptions: [
          for (final existing in _brief.assumptions)
            existing.id == assumption.id ? assumption : existing,
        ],
        updatedAt: _now,
        clearValidation: true,
      ),
    );
  }

  /// Removes an assumption by id.
  Future<void> removeAssumption(String id) async {
    await _persist(
      _brief.copyWith(
        assumptions: _brief.assumptions.where((a) => a.id != id).toList(),
        updatedAt: _now,
        clearValidation: true,
      ),
    );
  }

  /// Runs the constraint checker and stores the report in memory.
  ///
  /// The report is intentionally not persisted; it is cheap to recompute.
  ValidationReport runValidation() {
    final report = checker.check(_brief);
    _brief = _brief.copyWith(validation: report);
    notifyListeners();
    return report;
  }

  /// Exports the brief as a pretty-printed JSON string.
  String exportJson({bool includeValidation = true}) {
    final map = _brief.toJson();
    if (!includeValidation) {
      map.remove('validation');
    }
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Replaces the current brief with one parsed from JSON text.
  Future<DesignBrief> importJson(String json) async {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected a JSON object.');
    }
    final brief = DesignBrief.fromJson(decoded);
    await _persist(brief.copyWith(updatedAt: _now, clearValidation: true));
    return brief;
  }

  /// Replaces the current brief in one operation.
  Future<void> replaceWith(DesignBrief brief) {
    return _persist(brief.copyWith(updatedAt: _now, clearValidation: true));
  }

  /// Releases the underlying repository.
  Future<void> close() => repository.close();
}
