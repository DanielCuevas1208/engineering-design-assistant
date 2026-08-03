import 'assumption.dart';
import 'constraint.dart';
import 'enums.dart';
import 'requirement.dart';
import 'validation.dart';

/// Schema identifier used by the typed handoff document.
const String designBriefSchemaId =
    'engineering-design-assistant/design-brief/1.0';

/// The complete state of a design project.
///
/// A brief holds the captured requirements, the constraints that bound them,
/// and the assumptions that must hold for the design to be valid.
class DesignBrief {
  final String projectName;
  final String projectVersion;
  final String purpose;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Requirement> requirements;
  final List<Constraint> constraints;
  final List<Assumption> assumptions;

  /// A snapshot of the last validation run, when one exists.
  final ValidationReport? validation;

  const DesignBrief({
    this.projectName = 'Untitled project',
    this.projectVersion = '0.1.0',
    this.purpose = '',
    required this.createdAt,
    required this.updatedAt,
    this.requirements = const [],
    this.constraints = const [],
    this.assumptions = const [],
    this.validation,
  });

  DesignBrief copyWith({
    String? projectName,
    String? projectVersion,
    String? purpose,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Requirement>? requirements,
    List<Constraint>? constraints,
    List<Assumption>? assumptions,
    ValidationReport? validation,
    bool clearValidation = false,
  }) {
    return DesignBrief(
      projectName: projectName ?? this.projectName,
      projectVersion: projectVersion ?? this.projectVersion,
      purpose: purpose ?? this.purpose,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requirements: requirements ?? this.requirements,
      constraints: constraints ?? this.constraints,
      assumptions: assumptions ?? this.assumptions,
      validation: clearValidation ? null : (validation ?? this.validation),
    );
  }

  Requirement? requirementById(String id) {
    for (final requirement in requirements) {
      if (requirement.id == id) return requirement;
    }
    return null;
  }

  Constraint? constraintById(String id) {
    for (final constraint in constraints) {
      if (constraint.id == id) return constraint;
    }
    return null;
  }

  Assumption? assumptionById(String id) {
    for (final assumption in assumptions) {
      if (assumption.id == id) return assumption;
    }
    return null;
  }

  int get openAssumptionCount =>
      assumptions.where((a) => a.status == AssumptionStatus.open).length;

  Map<String, Object?> toJson() {
    return {
      'schema': designBriefSchemaId,
      'project': {
        'name': projectName,
        'version': projectVersion,
        'purpose': purpose,
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'requirements': [for (final r in requirements) r.toJson()],
      'constraints': [for (final c in constraints) c.toJson()],
      'assumptions': [for (final a in assumptions) a.toJson()],
      if (validation != null) 'validation': validation!.toJson(),
    };
  }

  factory DesignBrief.fromJson(Map<String, Object?> json) {
    final schema = json['schema'] as String?;
    if (schema != designBriefSchemaId) {
      throw FormatException(
        'Unsupported design brief schema "$schema". Expected '
        '$designBriefSchemaId.',
      );
    }
    final project = (json['project'] as Map? ?? const {})
        .cast<String, Object?>();
    final requirements = (json['requirements'] as List? ?? const [])
        .map((e) => Requirement.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    final constraints = (json['constraints'] as List? ?? const [])
        .map((e) => Constraint.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    final assumptions = (json['assumptions'] as List? ?? const [])
        .map((e) => Assumption.fromJson((e as Map).cast<String, Object?>()))
        .toList();
    return DesignBrief(
      projectName: project['name'] as String? ?? 'Untitled project',
      projectVersion: project['version'] as String? ?? '0.1.0',
      purpose: project['purpose'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      requirements: requirements,
      constraints: constraints,
      assumptions: assumptions,
      validation: json['validation'] is Map
          ? ValidationReport.fromJson(
              (json['validation'] as Map).cast<String, Object?>(),
            )
          : null,
    );
  }

  /// An empty brief with no entities and the current time.
  factory DesignBrief.empty({DateTime? now}) {
    final timestamp = now ?? DateTime.now().toUtc();
    return DesignBrief(createdAt: timestamp, updatedAt: timestamp);
  }
}
