import '../core/design_brief.dart';
import 'brief_repository.dart';

/// A brief repository that keeps state in memory.
///
/// Used by widget tests and by web builds where native SQLite is unavailable.
class InMemoryBriefRepository implements BriefRepository {
  InMemoryBriefRepository([DesignBrief? initial])
    : _brief = initial ?? DesignBrief.empty();

  DesignBrief _brief;

  @override
  Future<DesignBrief> loadBrief() async => _brief;

  @override
  Future<void> saveBrief(DesignBrief brief) async {
    _brief = brief;
  }

  @override
  Future<void> close() async {}
}
