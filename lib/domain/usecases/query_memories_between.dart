import '../../core/result.dart';
import '../../core/use_case.dart';
import '../entities/memory.dart';
import '../repositories/memory_repository.dart';

class WindowQuery {
  final DateTime startUtcInclusive;
  final DateTime endUtcExclusive;

  const WindowQuery({
    required this.startUtcInclusive,
    required this.endUtcExclusive,
  });

  WindowQuery singleDay(DateTime localDay) {
    final start = DateTime(localDay.year, localDay.month, localDay.day);
    return WindowQuery(
      startUtcInclusive: start.toUtc(),
      endUtcExclusive: start.add(const Duration(days: 1)).toUtc(),
    );
  }
}

class QueryMemoriesBetween extends UseCase<List<Memory>, WindowQuery> {
  final MemoryRepository _memories;

  const QueryMemoriesBetween(this._memories);

  @override
  Future<Result<List<Memory>>> execute(WindowQuery input) =>
      _memories.findByDateRange(
        input.startUtcInclusive,
        input.endUtcExclusive,
      );
}
