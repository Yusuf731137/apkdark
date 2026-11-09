import 'dart:math';
import '../data/repositories/card_repository.dart';
import '../data/repositories/review_repository.dart';
import '../data/repositories/session_repository.dart';
import '../domain/card.dart';
import '../domain/rating.dart';
import '../domain/review_mode.dart';
import 'scheduler_service.dart';

class SessionState {
  final int sessionId;
  final ReviewMode mode;
  final int? deckId;
  final bool isCram;
  final List<int> queue;
  int index;
  final Map<String, int> ratings;
  final DateTime startedAt;

  SessionState({
    required this.sessionId,
    required this.mode,
    required this.deckId,
    required this.isCram,
    required this.queue,
    this.index = 0,
    Map<String, int>? ratings,
    DateTime? startedAt,
  })  : ratings = ratings ?? {'FAIL': 0, 'HARD': 0, 'GOOD': 0, 'EASY': 0},
        startedAt = startedAt ?? DateTime.now();
}

class ReviewEngine {
  final CardRepository cards;
  final ReviewRepository reviews;
  final SessionRepository sessions;
  final SchedulerService scheduler;

  ReviewEngine({
    CardRepository? cards,
    ReviewRepository? reviews,
    SessionRepository? sessions,
    SchedulerService? scheduler,
  })  : cards = cards ?? CardRepository(),
        reviews = reviews ?? ReviewRepository(),
        sessions = sessions ?? SessionRepository(),
        scheduler = scheduler ?? SchedulerService();

  Future<List<int>> buildQueue({
    required int? deckId,
    required ReviewMode mode,
    int? limit,
    int? dailyNew,
    int? dailyReview,
  }) async {
    List<Card> pool;
    switch (mode) {
      case ReviewMode.random:
        pool = await cards.allOrdered(deckId: deckId, byCreated: false);
        pool.shuffle(Random());
        break;
      case ReviewMode.created:
        pool = await cards.allOrdered(deckId: deckId, byCreated: true);
        break;
      case ReviewMode.fsrs:
      default:
        pool = await cards.due(deckId: deckId);
        break;
    }

    if (dailyNew != null || dailyReview != null) {
      final counts = await reviews.todayCounts();
      int? newLeft = dailyNew == null
          ? null
          : (dailyNew - (counts['new'] ?? 0)).clamp(0, 999999);
      int? revLeft = dailyReview == null
          ? null
          : (dailyReview - (counts['review'] ?? 0)).clamp(0, 999999);

      final filtered = <Card>[];
      for (final c in pool) {
        if (c.suspended) continue;
        if (c.reps == 0) {
          if (newLeft == null || newLeft > 0) {
            filtered.add(c);
            if (newLeft != null) newLeft--;
          }
        } else {
          if (revLeft == null || revLeft > 0) {
            filtered.add(c);
            if (revLeft != null) revLeft--;
          }
        }
      }
      pool = filtered;
    }

    if (limit != null && limit > 0 && pool.length > limit) {
      pool = pool.sublist(0, limit);
    }

    return pool.map((c) => c.id).toList();
  }

  Future<SessionState> start({
    required int? deckId,
    required ReviewMode mode,
    required bool isCram,
    int? limit,
    int? dailyNew,
    int? dailyReview,
  }) async {
    // Cram sessions bypass daily limits
    final dn = isCram ? null : dailyNew;
    final dr = isCram ? null : dailyReview;

    final queue = await buildQueue(
      deckId: deckId,
      mode: mode,
      limit: limit,
      dailyNew: dn,
      dailyReview: dr,
    );

    final sid = await sessions.create(
      deckId: deckId,
      mode: mode.value,
      cardCount: queue.length,
      isCram: isCram,
    );

    return SessionState(
      sessionId: sid,
      mode: mode,
      deckId: deckId,
      isCram: isCram,
      queue: queue,
    );
  }

  Future<Card?> current(SessionState state) async {
    if (state.index >= state.queue.length) return null;
    return cards.get(state.queue[state.index]);
  }

  Future<DateTime?> rate({
    required SessionState state,
    required Card card,
    required Rating rating,
    int? durationMs,
  }) async {
    final wasNew = card.reps == 0;
    DateTime? nextDue;

    if (state.isCram) {
      await sessions.addTempReview(
        sessionId: state.sessionId,
        cardId: card.id,
        rating: rating,
      );
    } else {
      final values = scheduler.review(card, rating);
      await cards.saveSchedule(card.id, values);
      nextDue = values['due'] as DateTime;
      await reviews.log(
        cardId: card.id,
        sessionId: state.sessionId,
        rating: rating,
        prevState: card.state,
        newState: values['state'] as int,
        prevDue: card.due,
        newDue: nextDue,
        durationMs: durationMs,
        mode: state.mode.value,
        wasNew: wasNew,
      );
    }

    state.ratings[rating.dbValue] =
        (state.ratings[rating.dbValue] ?? 0) + 1;
    state.index++;
    return nextDue;
  }

  Future<void> finish(SessionState state) async {
    await sessions.finish(state.sessionId, state.ratings);
  }

  Map<Rating, String> previewIntervals(Card card) {
    return scheduler.previewIntervals(card);
  }
}