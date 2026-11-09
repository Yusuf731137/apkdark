import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../../domain/field.dart';
import '../../domain/field_type.dart';

class FieldRepository {
  Future<Database> get _db => AppDatabase.instance;

  Future<List<FieldDef>> forDeck(int deckId) async {
    final db = await _db;
    final rows = await db.query(
      'fields',
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(FieldDef.fromMap).toList();
  }

  Future<FieldDef?> get(int id) async {
    final db = await _db;
    final rows = await db.query('fields', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : FieldDef.fromMap(rows.first);
  }

  Future<FieldDef> create({
    required int deckId,
    required String name,
    required FieldType type,
    required FieldSide side,
    String language = '',
    int fontSize = 16,
    String? ttsProvider,
    String? ttsVoice,
    double ttsRate = 1.0,
    FieldSource source = FieldSource.manual,
    int sortOrder = 0,
  }) async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    final id = await db.insert('fields', {
      'deck_id': deckId,
      'name': name.trim(),
      'type': type.value,
      'side': side.value,
      'language': language,
      'font_size': fontSize,
      'tts_provider': ttsProvider,
      'tts_voice': ttsVoice,
      'tts_rate': ttsRate,
      'source': source.value,
      'sort_order': sortOrder,
      'created_at': now,
      'modified_at': now,
    });
    return (await get(id))!;
  }

  Future<void> update(FieldDef field) async {
    final db = await _db;
    await db.update(
      'fields',
      field.toUpdateMap(),
      where: 'id = ?',
      whereArgs: [field.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    final used = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM card_field_values WHERE field_id = ?',
            [id],
          ),
        ) ??
        0;
    if (used > 0) {
      throw StateError('Cannot delete a field with values');
    }
    await db.delete('fields', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(int deckId, List<int> orderedIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'fields',
          {'sort_order': i},
          where: 'id = ? AND deck_id = ?',
          whereArgs: [orderedIds[i], deckId],
        );
      }
    });
  }

  Future<Map<int, String>> valuesForCard(int cardId) async {
    final db = await _db;
    final rows = await db.query(
      'card_field_values',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
    return {for (final r in rows) r['field_id'] as int: r['value'] as String};
  }
}