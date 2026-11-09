import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../../domain/deck.dart';

class DeckRepository {
  Future<Database> get _db => AppDatabase.instance;

  Future<List<Deck>> list() async {
    final db = await _db;
    final rows = await db.query('decks', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Deck.fromMap).toList();
  }

  Future<Deck> get(int id) async {
    final db = await _db;
    final rows = await db.query('decks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw StateError('Deck not found');
    return Deck.fromMap(rows.first);
  }

  Future<Deck> create({required String name, String description = ''}) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Deck name required');

    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    final deckId = await db.insert('decks', {
      'name': clean,
      'description': description.trim(),
      'created_at': now,
      'modified_at': now,
    });

    // Seed default fields Front/Back
    for (final spec in [
      {'name': 'Front', 'side': 'FRONT', 'order': 0},
      {'name': 'Back', 'side': 'BACK', 'order': 1},
    ]) {
      await db.insert('fields', {
        'deck_id': deckId,
        'name': spec['name'],
        'type': 'TEXT',
        'side': spec['side'],
        'sort_order': spec['order'],
        'created_at': now,
        'modified_at': now,
      });
    }

    return get(deckId);
  }

  Future<void> update(
    int id, {
    required String name,
    required String description,
    int? folderId,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Deck name required');
    final db = await _db;
    await db.update(
      'decks',
      {
        'name': clean,
        'description': description.trim(),
        'folder_id': folderId,
        'modified_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM decks'),
        ) ??
        0;
    if (count <= 1) throw StateError('Must keep at least one deck');
    await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }
}