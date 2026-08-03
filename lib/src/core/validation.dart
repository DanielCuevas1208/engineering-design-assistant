import 'enums.dart';

/// One finding produced by a validation run.
class ValidationIssue {
  final IssueSeverity severity;
  final String code;
  final String message;

  /// The requirement, constraint, or assumption this issue refers to.
  final String? entityId;

  /// Optional context, for example a measured value.
  final String? detail;

  const ValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.entityId,
    this.detail,
  });

  Map<String, Object?> toJson() {
    return {
      'severity': severity.wire,
      'code': code,
      'message': message,
      if (entityId != null) 'entityId': entityId,
      if (detail != null) 'detail': detail,
    };
  }

  factory ValidationIssue.fromJson(Map<String, Object?> json) {
    return ValidationIssue(
      severity: IssueSeverity.fromWire(json['severity'] as String?),
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? '',
      entityId: json['entityId'] as String?,
      detail: json['detail'] as String?,
    );
  }
}

/// The outcome of checking a design brief.
class ValidationReport {
  final DateTime generatedAt;
  final int requirementCount;
  final int constraintCount;
  final int assumptionCount;
  final int openAssumptionCount;
  final List<ValidationIssue> issues;

  const ValidationReport({
    required this.generatedAt,
    required this.requirementCount,
    required this.constraintCount,
    required this.assumptionCount,
    required this.openAssumptionCount,
    required this.issues,
  });

  bool get passes => !issues.any((i) => i.severity == IssueSeverity.error);

  int get errorCount => _count(IssueSeverity.error);
  int get warningCount => _count(IssueSeverity.warning);
  int get infoCount => _count(IssueSeverity.info);

  int _count(IssueSeverity severity) =>
      issues.where((i) => i.severity == severity).length;

  List<ValidationIssue> bySeverity(IssueSeverity severity) =>
      issues.where((i) => i.severity == severity).toList();

  Map<String, Object?> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'counts': {
        'requirements': requirementCount,
        'constraints': constraintCount,
        'assumptions': assumptionCount,
        'openAssumptions': openAssumptionCount,
      },
      'passes': passes,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'infoCount': infoCount,
      'issues': [for (final issue in issues) issue.toJson()],
    };
  }

  factory ValidationReport.fromJson(Map<String, Object?> json) {
    final issues = (json['issues'] as List? ?? const [])
        .map(
          (e) => ValidationIssue.fromJson((e as Map).cast<String, Object?>()),
        )
        .toList();
    final counts = (json['counts'] as Map? ?? const {}).cast<String, Object?>();
    return ValidationReport(
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      requirementCount: counts['requirements'] as int? ?? 0,
      constraintCount: counts['constraints'] as int? ?? 0,
      assumptionCount: counts['assumptions'] as int? ?? 0,
      openAssumptionCount: counts['openAssumptions'] as int? ?? 0,
      issues: issues,
    );
  }
}
