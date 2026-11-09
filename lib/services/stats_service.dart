import '../data/repositories/stats_repository.dart';

class StatsService {
  final StatsRepository _repo;
  StatsService([StatsRepository? repo]) : _repo = repo ?? StatsRepository();

  Future<Map<String, int>> overview({int? deckId}) =>
      _repo.overview(deckId: deckId);

  Future<Map<String, int>> ratingCounts({int? deckId}) =>
      _repo.ratingCounts(deckId: deckId);

  Future<List<(String, int)>> reviewsByDay({
    required int days,
    int? deckId,
  }) =>
      _repo.reviewsByDay(days: days, deckId: deckId);

  Future<int> reviewedToday({int? deckId}) =>
      _repo.reviewedToday(deckId: deckId);

  Future<double> averageDurationMs({int? deckId}) =>
      _repo.averageDurationMs(deckId: deckId);

  Future<Map<String, int>> gradeDistribution({int? deckId}) =>
      _repo.gradeDistribution(deckId: deckId);
}