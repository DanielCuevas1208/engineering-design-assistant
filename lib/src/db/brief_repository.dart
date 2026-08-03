import '../core/design_brief.dart';

/// Stores and restores the design brief.
///
/// Implementations back this interface with SQLite or an in-memory store.
/// Tests and the web build use the in-memory variant.
abstract interface class BriefRepository {
  /// Loads the current design brief, or an empty one when none exists.
  Future<DesignBrief> loadBrief();

  /// Replaces the stored brief in one atomic operation.
  Future<void> saveBrief(DesignBrief brief);

  /// Releases any underlying resources.
  Future<void> close();
}
