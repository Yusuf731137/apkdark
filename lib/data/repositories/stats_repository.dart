import 'package:sqflite/sqflite.dart';
import '../database.dart';

class StatsRepository {
  Future<Database> get _db => AppDatabase.instance;

  Future<Map<String, int>> overview({int? deckId}) async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();

    String where = deckId != null ? ' WHERE deck_id = ?' : '';
    List<Object?> args = deckId != null ? [deckId] : [];

    final total = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM cards$where',
          args,
        )) ??
        0;

    final newCount = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM cards${where.isEmpty ? '' : '$where AND'} reps = 0',
          args,
        )) ??
        0;

    final dueWhere = deckId != null
        ? 'WHERE deck_id = ? AND due <= ? AND suspended = 0'
        : 'WHERE due <= ? AND suspended = 0';
    final dueArgs = deckId != null ? [deckId, now] : [now];
    final dueCount = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM cards $dueWhere',
          dueArgs,
        )) ??
        0;

    return {'total': total, 'new': newCount, 'due': dueCount};
  }

  Future<Map<String, int>> ratingCounts({int? deckId}) async {
    final db = await _db;
    final where = deckId != null
        ? 'WHERE rl.card_id IN (SELECT id FROM cards WHERE deck_id = ?)'
        : '';
    final args = deckId != null ? [deckId] : [];
    final rows = await db.rawQuery(
      'SELECT rating, COUNT(*) as n FROM review_logs rl $where GROUP BY rating',
      args,
    );
    final result = {'FAIL': 0, 'HARD': 0, 'GOOD': 0, 'EASY': 0};
    for (final r in rows) {
      final k = r['rating'] as String;
      if (result.containsKey(k)) result[k] = r['n'] as int;
    }
    return result;
  }

  Future<List<(String, int)>> reviewsByDay({
    required int days,
    int? deckId,
  }) async {
    final db = await _db;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toUtc()
        .toIso8601String();

    final where = deckId != null
        ? 'WHERE ts >= ? AND card_id IN (SELECT id FROM cards WHERE deck_id = ?)'
        : 'WHERE ts >= ?';
    final args = deckId != null ? [since, deckId] : [since];

    final rows = await db.rawQuery(
      '''SELECT substr(ts,1,10) as d, COUNT(*) as n
         FROM review_logs $where GROUP BY d ORDER BY d ASC''',
      args,
    );
    return rows
        .map((r) => (r['d'] as String, r['n'] as int))
        .toList();
  }

  Future<int> reviewedToday({int? deckId}) async {
    final db = await _db;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .toUtc()
        .toIso8601String();
    final where = deckId != null
        ? 'WHERE ts >= ? AND card_id IN (SELECT id FROM cards WHERE deck_id = ?)'
        : 'WHERE ts >= ?';
    final args = deckId != null ? [start, deckId] : [start];
    return Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM review_logs $where',
          args,
        )) ??
        0;
  }

  Future<double> averageDurationMs({int? deckId}) async {
    final db = await _db;
    final where = deckId != null
        ? 'WHERE duration_ms IS NOT NULL AND card_id IN (SELECT id FROM cards WHERE deck_id = ?)'
        : 'WHERE duration_ms IS NOT NULL';
    final args = deckId != null ? [deckId] : [];
    final rows = await db.rawQuery(
      'SELECT AVG(duration_ms) as avg FROM review_logs $where',
      args,
    );
    final v = rows.first['avg'];
    return v == null ? 0.0 : (v as num).toDouble();
  }

  Future<Map<String, int>> gradeDistribution({int? deckId}) async {
    final db = await _db;
    final where = deckId != null ? 'WHERE deck_id = ?' : '';
    final args = deckId != null ? [deckId] : [];
    final rows = await db.rawQuery(
      'SELECT state, reps, lapses, stability FROM cards $where',
      args,
    );
    final result = {'NEW': 0, 'F': 0, 'E': 0, 'D': 0, 'C': 0, 'B': 0, 'A': 0};
    for (final r in rows) {
      final reps = r['reps'] as int;
      final state = r['state'] as int;
      final lapses = r['lapses'] as int;
      final stability = (r['stability'] as num?)?.toDouble() ?? 0.0;

      if (reps == 0) {
        result['NEW'] = result['NEW']! + 1;
        continue;
      }
      if (state == 1 || state == 3 || (lapses > 0 && stability < 0.5)) {
        result['F'] = result['F']! + 1;
        continue;
      }
      if (stability < 1) {
        result['E'] = result['E']! + 1;
      } else if (stability < 3) {
        result['D'] = result['D']! + 1;
      } else if (stability < 7) {
        result['C'] = result['C']! + 1;
      } else if (stability < 21) {
        result['B'] = result['B']! + 1;
      } else {
        result['A'] = result['A']! + 1;
      }
    }
    return result;
  }
}