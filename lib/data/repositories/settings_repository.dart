import 'package:sqflite/sqflite.dart';
import '../database.dart';

class SettingsRepository {
  static const Map<String, String> defaults = {
    'general.language': 'ar',
    'general.theme': 'dark',
    'review.mode': 'FSRS',
    'review.new_per_day': '20',
    'review.review_per_day': '200',
    'review.auto_pronounce_front': 'true',
    'review.auto_pronounce_back': 'true',
    'review.auto_pronounce_delay_ms': '300',
    'review.flip_duration_ms': '300',
    'audio.volume': '0.9',
    'audio.speed': '1.0',
    'tts.provider': 'system',
    'tts.en_voice': '',
    'tts.ar_voice': '',
    'fsrs.desired_retention': '0.9',
    'fsrs.max_interval_days': '3650',
  };

  Future<Database> get _db => AppDatabase.instance;

  Future<String?> get(String key) async {
    final db = await _db;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return defaults[key];
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final db = await _db;
    await db.rawInsert(
      'INSERT INTO app_settings(key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }

  Future<Map<String, String>> all() async {
    final db = await _db;
    final rows = await db.query('app_settings');
    final result = Map<String, String>.from(defaults);
    for (final r in rows) {
      result[r['key'] as String] = r['value'] as String;
    }
    return result;
  }

  Future<int> getInt(String key) async =>
      int.tryParse(await get(key) ?? '0') ?? 0;

  Future<double> getDouble(String key) async =>
      double.tryParse(await get(key) ?? '0') ?? 0;

  Future<bool> getBool(String key) async {
    final v = (await get(key) ?? 'false').toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }
}