import 'package:sqflite/sqflite.dart';
import '../database.dart';

class AudioCacheRepository {
  Future<Database> get _db => AppDatabase.instance;

  Future<Map<String, dynamic>?> get(String key) async {
    final db = await _db;
    final rows = await db.query(
      'audio_cache',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> put({
    required String key,
    required String filePath,
    required String text,
    required String lang,
    required String provider,
    required String voice,
    required String paramsJson,
    required int sizeBytes,
  }) async {
    final db = await _db;
    await db.rawInsert(
      '''INSERT OR REPLACE INTO audio_cache
         (key, file_path, text, lang, provider, voice, params_json, size_bytes, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        key,
        filePath,
        text,
        lang,
        provider,
        voice,
        paramsJson,
        sizeBytes,
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Future<void> remove(String key) async {
    final db = await _db;
    await db.delete('audio_cache', where: 'key = ?', whereArgs: [key]);
  }

  Future<int> totalSize() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT SUM(size_bytes) AS total FROM audio_cache',
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<void> clear() async {
    final db = await _db;
    await db.delete('audio_cache');
  }
}