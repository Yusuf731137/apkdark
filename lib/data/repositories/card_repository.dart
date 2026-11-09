import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../../domain/card.dart';

class CardRepository {
  Future<Database> get _db => AppDatabase.instance;

  Future<List<Card>> list({
    int? deckId,
    String? status, // new | learning | review | due | suspended
    String? sortBy, // created | alpha | last_review | due | difficulty | stability
    bool descending = false,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (deckId != null) {
      where.add('deck_id = ?');
      args.add(deckId);
    }
    switch (status) {
      case 'new':
        where.add('reps = 0 AND suspended = 0');
        break;
      case 'learning':
        where.add('state IN (1, 3) AND suspended = 0');
        break;
      case 'review':
        where.add('state = 2 AND reps > 0 AND suspended = 0');
        break;
      case 'due':
        where.add('due <= ? AND suspended = 0');
        args.add(DateTime.now().toUtc().toIso8601String());
        break;
      case 'suspended':
        where.add('suspended = 1');
        break;
    }

    final dir = descending ? 'DESC' : 'ASC';
    String order;
    switch (sortBy) {
      case 'alpha':
        order = 'front $dir, id $dir';
        break;
      case 'last_review':
        order = '(last_review IS NULL), last_review $dir, id $dir';
        break;
      case 'due':
        order = 'due $dir, id $dir';
        break;
      case 'difficulty':
        order = 'difficulty $dir, id $dir';
        break;
      case 'stability':
        order = 'stability $dir, id $dir';
        break;
      default:
        order = 'created_at $dir, id $dir';
    }

    final rows = await db.query(
      'cards',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: order,
    );
    return rows.map(Card.fromMap).toList();
  }

  Future<Card?> get(int id) async {
    final db = await _db;
    final rows = await db.query('cards', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Card.fromMap(rows.first);
  }

  Future<List<Card>> due({int? deckId}) async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await db.query(
      'cards',
      where: deckId != null
          ? 'due <= ? AND suspended = 0 AND deck_id = ?'
          : 'due <= ? AND suspended = 0',
      whereArgs: deckId != null ? [now, deckId] : [now],
      orderBy: 'state ASC, due ASC, id ASC',
    );
    return rows.map(Card.fromMap).toList();
  }

  Future<List<Card>> allOrdered({int? deckId, required bool byCreated}) async {
    final db = await _db;
    final rows = await db.query(
      'cards',
      where: deckId != null
          ? 'deck_id = ? AND suspended = 0'
          : 'suspended = 0',
      whereArgs: deckId != null ? [deckId] : null,
      orderBy: byCreated ? 'created_at ASC, id ASC' : 'id ASC',
    );
    return rows.map(Card.fromMap).toList();
  }

  Future<int> create({
    required int deckId,
    required String front,
    required String back,
  }) async {
    final f = front.trim();
    final b = back.trim();
    if (f.isEmpty || b.isEmpty) throw ArgumentError('Both sides required');
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    return db.insert('cards', {
      'deck_id': deckId,
      'front': f,
      'back': b,
      'due': now,
      'created_at': now,
      'modified_at': now,
    });
  }

  /// ➕ الدالة المضافة حديثاً مع الحماية عبر الـ Transaction
  Future<int> createWithValues({
    required int deckId,
    required Map<int, String> values,
  }) async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    int cardId = 0;

    // استخدام الـ Transaction لضمان نجاح العملية بالكامل أو إلغائها فوراً في حال حدوث خطأ
    await db.transaction((txn) async {
      cardId = await txn.insert('cards', {
        'deck_id': deckId,
        'front': '',
        'back': '',
        'due': now,
        'created_at': now,
        'modified_at': now,
      });

      // حفظ القيم داخل نفس الـ Transaction
      for (final e in values.entries) {
        await txn.rawInsert(
          '''INSERT INTO card_field_values(card_id, field_id, value, updated_at)
             VALUES (?, ?, ?, ?)
             ON CONFLICT(card_id, field_id) DO UPDATE SET
               value = excluded.value,
               updated_at = excluded.updated_at''',
          [cardId, e.key, e.value, now],
        );
      }

      // مزامنة حقول front/back بناءً على حقول الـ Deck المحددة
      final rows = await txn.rawQuery('''
        SELECT f.side, f.sort_order, cfv.value
        FROM fields f
        LEFT JOIN card_field_values cfv
          ON cfv.field_id = f.id AND cfv.card_id = ?
        WHERE f.deck_id = ?
        ORDER BY f.sort_order
      ''', [cardId, deckId]);

      String front = '';
      String back = '';
      for (final r in rows) {
        final side = r['side'] as String;
        final value = (r['value'] as String?) ?? '';
        if (value.isEmpty) continue;
        if ((side == 'FRONT' || side == 'BOTH') && front.isEmpty) front = value;
        if ((side == 'BACK' || side == 'BOTH') && back.isEmpty) back = value;
      }

      // تحديث بيانات الكارت الأساسية بالقيم المزامنة
      await txn.update(
        'cards',
        {'front': front, 'back': back, 'modified_at': now},
        where: 'id = ?',
        whereArgs: [cardId],
      );
    });

    return cardId;
  }

  Future<void> updateValues(int cardId, Map<int, String> values) async {
    // Values are field_id -> value
    // Also update the denormalized front/back
    final db = await _db;
    final card = await get(cardId);
    if (card == null) throw StateError('Card not found');

    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      for (final e in values.entries) {
        await txn.rawInsert(
          '''INSERT INTO card_field_values(card_id, field_id, value, updated_at)
             VALUES (?, ?, ?, ?)
             ON CONFLICT(card_id, field_id) DO UPDATE SET
               value = excluded.value,
               updated_at = excluded.updated_at''',
          [cardId, e.key, e.value, now],
        );
      }
      // Sync front/back from the primary FRONT/BACK fields
      final rows = await txn.rawQuery('''
        SELECT f.side, f.sort_order, cfv.value
        FROM fields f
        LEFT JOIN card_field_values cfv
          ON cfv.field_id = f.id AND cfv.card_id = ?
        WHERE f.deck_id = ?
        ORDER BY f.sort_order
      ''', [cardId, card.deckId]);

      String front = '';
      String back = '';
      for (final r in rows) {
        final side = r['side'] as String;
        final value = (r['value'] as String?) ?? '';
        if (value.isEmpty) continue;
        if ((side == 'FRONT' || side == 'BOTH') && front.isEmpty) front = value;
        if ((side == 'BACK' || side == 'BOTH') && back.isEmpty) back = value;
      }
      await txn.update(
        'cards',
        {'front': front, 'back': back, 'modified_at': now},
        where: 'id = ?',
        whereArgs: [cardId],
      );
    });
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setSuspended(int id, bool suspended) async {
    final db = await _db;
    await db.update(
      'cards',
      {'suspended': suspended ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveSchedule(int cardId, Map<String, dynamic> values) async {
    final db = await _db;
    await db.update(
      'cards',
      {
        'state': values['state'],
        'step': values['step'],
        'stability': values['stability'],
        'difficulty': values['difficulty'],
        'due': (values['due'] as DateTime).toUtc().toIso8601String(),
        'last_review':
            (values['last_review'] as DateTime?)?.toUtc().toIso8601String(),
        'reps': values['reps'],
        'lapses': values['lapses'],
        'learning_steps': values['learning_steps'],
        'modified_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}
