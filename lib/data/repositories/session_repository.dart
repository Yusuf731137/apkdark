import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../../domain/rating.dart';

class SessionRepository {
  Future<Database> get _db => AppDatabase.instance;

  Future<int> create({
    required int? deckId,
    required String mode,
    required int cardCount,
    required bool isCram,
  }) async {
    final db = await _db;
    return db.insert('review_sessions', {
      'deck_id': deckId,
      'mode': mode,
      'started_at': DateTime.now().toUtc().toIso8601String(),
      'card_count': cardCount,
      'is_cram': isCram ? 1 : 0,
    });
  }

  Future<void> finish(int sessionId, Map<String, int> ratings) async {
    final db = await _db;
    final json = '{'
        '"FAIL":${ratings['FAIL'] ?? 0},'
        '"HARD":${ratings['HARD'] ?? 0},'
        '"GOOD":${ratings['GOOD'] ?? 0},'
        '"EASY":${ratings['EASY'] ?? 0}'
        '}';
    await db.update(
      'review_sessions',
      {
        'ended_at': DateTime.now().toUtc().toIso8601String(),
        'ratings_json': json,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> addTempReview({
    required int sessionId,
    required int cardId,
    required Rating rating,
  }) async {
    final db = await _db;
    await db.insert('temporary_session_reviews', {
      'session_id': sessionId,
      'card_id': cardId,
      'rating': rating.dbValue,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
  }
}