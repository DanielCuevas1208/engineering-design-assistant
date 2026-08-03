import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/assumption.dart';
import '../core/constraint.dart';
import '../core/design_brief.dart';
import '../core/enums.dart';
import '../core/quantity_text.dart';
import '../core/requirement.dart';
import 'brief_repository.dart';
import 'database_path.dart';

/// A brief repository backed by a SQLite database.
class SqliteBriefRepository implements BriefRepository {
  SqliteBriefRepository(this._db);

  final Database _db;

  /// Initializes the FFI database factory.
  ///
  /// Safe to call more than once.
  static void ensureSqlite() => sqfliteFfiInit();

  /// Opens the repository, creating the schema when needed.
  static Future<SqliteBriefRepository> open({String? path}) async {
    ensureSqlite();
    final resolved = path ?? defaultDatabasePath();
    final database = await databaseFactoryFfi.openDatabase(resolved);
    await _createSchema(database);
    return SqliteBriefRepository(database);
  }

  /// Opens an in-memory repository for tests.
  static Future<SqliteBriefRepository> openInMemory() async {
    ensureSqlite();
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    await _createSchema(database);
    return SqliteBriefRepository(database);
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS project (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        version TEXT NOT NULL,
        purpose TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS requirements (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL REFERENCES project(id),
        statement TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        owner TEXT NOT NULL,
        rationale TEXT NOT NULL,
        quantity TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS constraints (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL REFERENCES project(id),
        requirement_id TEXT NOT NULL,
        description TEXT NOT NULL,
        kind TEXT NOT NULL,
        severity TEXT NOT NULL,
        value_bound TEXT NOT NULL,
        min_bound TEXT NOT NULL,
        max_bound TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assumptions (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL REFERENCES project(id),
        statement TEXT NOT NULL,
        owner TEXT NOT NULL,
        status TEXT NOT NULL,
        requirement_id TEXT,
        rationale TEXT NOT NULL
      )
    ''');
  }

  static const _projectId = 'default';

  @override
  Future<DesignBrief> loadBrief() async {
    final project = await _db.query(
      'project',
      where: 'id = ?',
      whereArgs: [_projectId],
    );
    if (project.isEmpty) {
      return DesignBrief.empty();
    }
    final row = project.single;

    final requirementRows = await _db.query(
      'requirements',
      where: 'project_id = ?',
      whereArgs: [_projectId],
      orderBy: 'id',
    );
    final constraintRows = await _db.query(
      'constraints',
      where: 'project_id = ?',
      whereArgs: [_projectId],
      orderBy: 'id',
    );
    final assumptionRows = await _db.query(
      'assumptions',
      where: 'project_id = ?',
      whereArgs: [_projectId],
      orderBy: 'id',
    );

    return DesignBrief(
      projectName: row['name'] as String,
      projectVersion: row['version'] as String,
      purpose: row['purpose'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      requirements: [for (final r in requirementRows) _requirementFromRow(r)],
      constraints: [for (final c in constraintRows) _constraintFromRow(c)],
      assumptions: [for (final a in assumptionRows) _assumptionFromRow(a)],
    );
  }

  @override
  Future<void> saveBrief(DesignBrief brief) async {
    await _db.transaction((txn) async {
      await txn.delete(
        'assumptions',
        where: 'project_id = ?',
        whereArgs: [_projectId],
      );
      await txn.delete(
        'constraints',
        where: 'project_id = ?',
        whereArgs: [_projectId],
      );
      await txn.delete(
        'requirements',
        where: 'project_id = ?',
        whereArgs: [_projectId],
      );
      await txn.delete('project', where: 'id = ?', whereArgs: [_projectId]);

      await txn.insert('project', {
        'id': _projectId,
        'name': brief.projectName,
        'version': brief.projectVersion,
        'purpose': brief.purpose,
        'created_at': brief.createdAt.toIso8601String(),
        'updated_at': brief.updatedAt.toIso8601String(),
      });
      for (final requirement in brief.requirements) {
        await txn.insert('requirements', {
          'id': requirement.id,
          'project_id': _projectId,
          'statement': requirement.statement,
          'category': requirement.category.wire,
          'priority': requirement.priority.wire,
          'status': requirement.status.wire,
          'owner': requirement.owner,
          'rationale': requirement.rationale,
          'quantity': requirement.quantity.raw,
        });
      }
      for (final constraint in brief.constraints) {
        await txn.insert('constraints', {
          'id': constraint.id,
          'project_id': _projectId,
          'requirement_id': constraint.requirementId,
          'description': constraint.description,
          'kind': constraint.kind.wire,
          'severity': constraint.severity.wire,
          'value_bound': constraint.value.raw,
          'min_bound': constraint.min.raw,
          'max_bound': constraint.max.raw,
        });
      }
      for (final assumption in brief.assumptions) {
        await txn.insert('assumptions', {
          'id': assumption.id,
          'project_id': _projectId,
          'statement': assumption.statement,
          'owner': assumption.owner,
          'status': assumption.status.wire,
          'requirement_id': assumption.requirementId,
          'rationale': assumption.rationale,
        });
      }
    });
  }

  @override
  Future<void> close() => _db.close();

  Requirement _requirementFromRow(Map<String, Object?> row) {
    final quantity = row['quantity'] as String;
    return Requirement(
      id: row['id'] as String,
      statement: row['statement'] as String,
      category: RequirementCategory.fromWire(row['category'] as String?),
      priority: Priority.fromWire(row['priority'] as String?),
      status: RequirementStatus.fromWire(row['status'] as String?),
      owner: row['owner'] as String? ?? '',
      rationale: row['rationale'] as String? ?? '',
      quantity: quantity.trim().isEmpty
          ? QuantityText.empty
          : QuantityText(quantity),
    );
  }

  Constraint _constraintFromRow(Map<String, Object?> row) {
    String text(String key) => row[key] as String? ?? '';
    final valueText = text('value_bound');
    final minText = text('min_bound');
    final maxText = text('max_bound');
    return Constraint(
      id: row['id'] as String,
      requirementId: row['requirement_id'] as String,
      description: row['description'] as String? ?? '',
      kind: ConstraintKind.fromWire(row['kind'] as String?),
      severity: Severity.fromWire(row['severity'] as String?),
      value: valueText.trim().isEmpty
          ? QuantityText.empty
          : QuantityText(valueText),
      min: minText.trim().isEmpty ? QuantityText.empty : QuantityText(minText),
      max: maxText.trim().isEmpty ? QuantityText.empty : QuantityText(maxText),
    );
  }

  Assumption _assumptionFromRow(Map<String, Object?> row) {
    return Assumption(
      id: row['id'] as String,
      statement: row['statement'] as String,
      owner: row['owner'] as String? ?? '',
      status: AssumptionStatus.fromWire(row['status'] as String?),
      requirementId: row['requirement_id'] as String?,
      rationale: row['rationale'] as String? ?? '',
    );
  }
}
