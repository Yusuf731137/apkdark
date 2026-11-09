import 'package:fsrs/fsrs.dart' as fsrs;
import '../domain/card.dart';
import '../domain/rating.dart';

class SchedulerService {
  final fsrs.Scheduler _scheduler;

  SchedulerService({double desiredRetention = 0.9, int maxInterval = 3650})
      : _scheduler = fsrs.Scheduler(
          desiredRetention: desiredRetention,
          maximumInterval: maxInterval,
        );

  /// Returns the new card state values to persist.
  Map<String, dynamic> review(Card card, Rating rating,
      {DateTime? now}) {
    final reviewDate = (now ?? DateTime.now()).toUtc();

    final fsrsCard = fsrs.Card(
      cardId: card.id,
      state: _stateOf(card.state),
      step: card.step,
      stability: card.stability,
      difficulty: card.difficulty,
      due: card.due.toUtc(),
      lastReview: card.lastReview?.toUtc(),
    );

    final (updated, _) = _scheduler.reviewCard(
      fsrsCard,
      _ratingOf(rating),
      reviewDateTime: reviewDate,
    );

    final wasLearning = card.state == 1 || card.state == 3;
    final isFail = rating == Rating.fail;
    final wasReview = card.state == 2;

    return {
      'state': _stateToInt(updated.state),
      'step': updated.step,
      'stability': updated.stability,
      'difficulty': updated.difficulty,
      'due': updated.due.toUtc(),
      'last_review': updated.lastReview?.toUtc() ?? reviewDate,
      'reps': card.reps + 1,
      'lapses': card.lapses + (isFail && wasReview ? 1 : 0),
      'learning_steps': card.learningSteps + (wasLearning ? 1 : 0),
    };
  }

  /// Preview intervals for the 4 rating buttons.
  /// Returns a map: {Rating: "3 أيام", ...}
  Map<Rating, String> previewIntervals(Card card, {DateTime? now}) {
    final base = (now ?? DateTime.now()).toUtc();
    final result = <Rating, String>{};
    for (final r in Rating.values) {
      try {
        final values = review(card, r, now: base);
        final due = values['due'] as DateTime;
        final secs = due.difference(base).inSeconds;
        result[r] = _formatInterval(secs);
      } catch (_) {
        result[r] = '—';
      }
    }
    return result;
  }

  static String _formatInterval(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    if (s < 3600) return '${(s ~/ 60).clamp(1, 999)} د';
    if (s < 86400) return '${(s ~/ 3600).clamp(1, 23)} س';
    return '${(s ~/ 86400).clamp(1, 9999)} ي';
  }

  fsrs.State _stateOf(int s) {
    switch (s) {
      case 2:
        return fsrs.State.review;
      case 3:
        return fsrs.State.relearning;
      default:
        return fsrs.State.learning;
    }
  }

  int _stateToInt(fsrs.State s) {
    if (s == fsrs.State.review) return 2;
    if (s == fsrs.State.relearning) return 3;
    return 1;
  }

  fsrs.Rating _ratingOf(Rating r) {
    switch (r) {
      case Rating.fail:
        return fsrs.Rating.again;
      case Rating.hard:
        return fsrs.Rating.hard;
      case Rating.good:
        return fsrs.Rating.good;
      case Rating.easy:
        return fsrs.Rating.easy;
    }
  }
}