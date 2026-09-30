import '../../core/result.dart';
import '../../core/use_case.dart';
import '../entities/memory.dart';
import '../repositories/memory_repository.dart';

class OnThisDayQuery {
  final DateTime referenceLocal;
  final int limit;

  const OnThisDayQuery({
    required this.referenceLocal,
    this.limit = 100,
  });
}

class GetOnThisDayMemories extends UseCase<List<Memory>, OnThisDayQuery> {
  final MemoryRepository _memories;

  const GetOnThisDayMemories(this._memories);

  @override
  Future<Result<List<Memory>>> execute(OnThisDayQuery input) async {
    final result = await _memories.findByCalendarDay(
      month: input.referenceLocal.month,
      day: input.referenceLocal.day,
    );
    return result.map((memories) {
      final currentYear = input.referenceLocal.year;
      final historical =
          memories.where((m) => m.moment.localYear < currentYear).toList()
            ..sort((a, b) => b.moment.compareTo(a.moment));
      return historical.take(input.limit).toList();
    });
  }
}
