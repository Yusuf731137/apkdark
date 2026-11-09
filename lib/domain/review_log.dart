import 'rating.dart';

class ReviewLog {
  final int id;
  final int cardId;
  final int? sessionId;
  final DateTime ts;
  final Rating rating;
  final int? prevState;
  final int? newState;
  final DateTime? prevDue;
  final DateTime? newDue;
  final int? durationMs;
  final String? mode;
  final bool wasNew;

  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.sessionId,
    required this.ts,
    required this.rating,
    required this.prevState,
    required this.newState,
    required this.prevDue,
    required this.newDue,
    required this.durationMs,
    required this.mode,
    required this.wasNew,
  });

  factory ReviewLog.fromMap(Map<String, dynamic> m) => ReviewLog(
        id: m['id'] as int,
        cardId: m['card_id'] as int,
        sessionId: m['session_id'] as int?,
        ts: DateTime.parse(m['ts'] as String).toLocal(),
        rating: RatingLabel.fromDb(m['rating'] as String),
        prevState: m['prev_state'] as int?,
        newState: m['new_state'] as int?,
        prevDue: m['prev_due'] != null
            ? DateTime.parse(m['prev_due'] as String).toLocal()
            : null,
        newDue: m['new_due'] != null
            ? DateTime.parse(m['new_due'] as String).toLocal()
            : null,
        durationMs: m['duration_ms'] as int?,
        mode: m['mode'] as String?,
        wasNew: ((m['was_new'] as int?) ?? 0) == 1,
      );
}