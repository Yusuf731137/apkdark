import '../domain/card.dart';
import '../domain/rating.dart';

class SchedulerService {
  /// SM-2 inspired scheduler using existing schema fields:
  /// - stability = interval in days (after review state)
  /// - difficulty = 0.0..1.0 (0 = easy, 1 = very hard)
  /// - state: 1=learning, 2=review, 3=relearning
  Map<String, dynamic> review(
    Card card,
    Rating rating, {
    DateTime? now,
  }) {
    final at = (now ?? DateTime.now()).toUtc();
    var state = card.state;
    var step = card.step;
    var stability = card.stability ?? 1.0;
    var difficulty = card.difficulty ?? 0.5;
    var reps = card.reps;
    var lapses = card.lapses;
    var learningSteps = card.learningSteps;

    Duration interval;
    switch (rating) {
      case Rating.fail:
        if (state == 2) lapses += 1;
        state = 3;
        step = 0;
        stability = 1.0;
        difficulty = (difficulty + 0.15).clamp(0.3, 1.0);
        interval = const Duration(minutes: 10);
        learningSteps += 1;
        break;

      case Rating.hard:
        if (state == 1 || state == 3) {
          interval = const Duration(minutes: 30);
          state = 1;
          step += 1;
        } else {
          final days = (stability * 1.2).round().clamp(1, 3650);
          stability = days.toDouble();
          interval = Duration(days: days);
        }
        difficulty = (difficulty + 0.05).clamp(0.3, 1.0);
        learningSteps += 1;
        break;

      case Rating.good:
        if (state == 1 || state == 3) {
          interval = const Duration(hours: 6);
          state = 2;
          step = 0;
          stability = 1.0;
        } else {
          final days = (stability * 2.5).round().clamp(1, 3650);
          stability = days.toDouble();
          interval = Duration(days: days);
        }
        learningSteps += 1;
        break;

      case Rating.easy:
        if (state == 1 || state == 3) {
          interval = const Duration(days: 4);
          state = 2;
          step = 0;
          stability = 4.0;
        } else {
          final days = (stability * 3.5).round().clamp(4, 3650);
          stability = days.toDouble();
          interval = Duration(days: days);
        }
        difficulty = (difficulty - 0.05).clamp(0.3, 1.0);
        learningSteps += 1;
        break;
    }

    reps += 1;

    return {
      'state': state,
      'step': step,
      'stability': stability,
      'difficulty': difficulty,
      'due': at.add(interval),
      'last_review': at,
      'reps': reps,
      'lapses': lapses,
      'learning_steps': learningSteps,
    };
  }

  Map<Rating, String> previewIntervals(Card card, {DateTime? now}) {
    final base = (now ?? DateTime.now()).toUtc();
    final out = <Rating, String>{};
    for (final r in Rating.values) {
      try {
        final values = review(card, r, now: base);
        final due = values['due'] as DateTime;
        final secs = due.difference(base).inSeconds;
        out[r] = _fmt(secs);
      } catch (_) {
        out[r] = '—';
      }
    }
    return out;
  }

  static String _fmt(int s) {
    final sec = s < 0 ? 0 : s;
    if (sec < 3600) return '${(sec ~/ 60).clamp(1, 999)} د';
    if (sec < 86400) return '${(sec ~/ 3600).clamp(1, 23)} س';
    return '${(sec ~/ 86400).clamp(1, 9999)} ي';
  }
}
