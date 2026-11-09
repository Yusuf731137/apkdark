import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../../domain/rating.dart';
import '../../domain/review_log.dart';

class ReviewRepository {
  Future<Database> get _db => AppDatabase.instance;

  Future<void> log({
    required int cardId,
    int? sessionId,
    required Rating rating,
    required int prevState,
    required int newState,
    required DateTime prevDue,
    required DateTime newDue,
    int? durationMs,
    String? mode,
    bool wasNew = false,
  }) async {
    final db = await _db;
    final dur = durationMs == null ? null : (durationMs < 0 ? 0 : (durationMs > 3600000 ? 3600000 : durationMs));
    await db.insert('review_logs', {
      'card_id': cardId,
      'session_id': sessionId,
      'ts': DateTime.now().toUtc().toIso8601String(),
      'rating': rating.dbValue,
      'prev_state': prevState,
      'new_state': newState,
      'prev_due': prevDue.toUtc().toIso8601String(),
      'new_due': newDue.toUtc().toIso8601String(),
      'duration_ms': dur,
      'mode': mode,
      'was_new': wasNew ? 1 : 0,
    });
  }

  Future<Map<String, int>> todayCounts() async {
    final localNow = DateTime.now();
    final localStart = DateTime(localNow.year, localNow.month, localNow.day);
    final iso = localStart.toUtc().toIso8601String();

    final db = await _db;
    final newCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM review_logs WHERE ts >= ? AND was_new = 1',
            [iso],
          ),
        ) ??
        0;
    final reviewCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM review_logs WHERE ts >= ? AND was_new = 0',
            [iso],
          ),
        ) ??
        0;
    return {'new': newCount, 'review': reviewCount};
  }

  Future<List<ReviewLog>> recent({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query('review_logs',
        orderBy: 'ts DESC', limit: limit);
    return rows.map(ReviewLog.fromMap).toList();
  }
}