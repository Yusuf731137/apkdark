import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Future<Database>? _dbFuture;

  static Future<Database> get instance {
    _dbFuture ??= _open();
    return _dbFuture!;
  }

  static Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'midad'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final path = p.join(folder.path, 'cards.db');

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await _migrateV1(db);
        await _migrateV2(db);
        await _migrateV3(db);
        await _seedDefaultDeck(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) await _migrateV2(db);
        if (oldV < 3) await _migrateV3(db);
      },
    );
  }

  // ===== V1 =====
  static Future<void> _migrateV1(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schema_version(version INTEGER NOT NULL)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS decks(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        description TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cards(
        id INTEGER PRIMARY KEY,
        deck_id INTEGER NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        state INTEGER NOT NULL DEFAULT 1,
        step INTEGER NOT NULL DEFAULT 0,
        stability REAL,
        difficulty REAL,
        due TEXT NOT NULL,
        last_review TEXT,
        reps INTEGER NOT NULL DEFAULT 0,
        lapses INTEGER NOT NULL DEFAULT 0,
        learning_steps INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS cards_due_idx ON cards(deck_id, due)');
  }

  // ===== V2 =====
  static Future<void> _migrateV2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS folders(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        parent_id INTEGER REFERENCES folders(id) ON DELETE SET NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Add folder_id to decks (if missing)
    final deckCols = await db.rawQuery('PRAGMA table_info(decks)');
    final deckNames = deckCols.map((c) => c['name'] as String).toSet();
    if (!deckNames.contains('folder_id')) {
      await db.execute(
          'ALTER TABLE decks ADD COLUMN folder_id INTEGER REFERENCES folders(id) ON DELETE SET NULL');
    }
    if (!deckNames.contains('modified_at')) {
      await db.execute('ALTER TABLE decks ADD COLUMN modified_at TEXT');
    }

    // Add modified_at to cards (if missing)
    final cardCols = await db.rawQuery('PRAGMA table_info(cards)');
    final cardNames = cardCols.map((c) => c['name'] as String).toSet();
    if (!cardNames.contains('modified_at')) {
      await db.execute('ALTER TABLE cards ADD COLUMN modified_at TEXT');
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fields(
        id INTEGER PRIMARY KEY,
        deck_id INTEGER NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'TEXT',
        side TEXT NOT NULL DEFAULT 'FRONT',
        language TEXT NOT NULL DEFAULT '',
        font_size INTEGER NOT NULL DEFAULT 16,
        tts_provider TEXT,
        tts_voice TEXT,
        tts_rate REAL DEFAULT 1.0,
        source TEXT NOT NULL DEFAULT 'MANUAL',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        modified_at TEXT,
        UNIQUE(deck_id, name)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS card_field_values(
        card_id INTEGER NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
        field_id INTEGER NOT NULL REFERENCES fields(id) ON DELETE RESTRICT,
        value TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL,
        PRIMARY KEY(card_id, field_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS review_logs(
        id INTEGER PRIMARY KEY,
        card_id INTEGER NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
        session_id INTEGER,
        ts TEXT NOT NULL,
        rating TEXT NOT NULL,
        prev_state INTEGER,
        new_state INTEGER,
        prev_due TEXT,
        new_due TEXT,
        duration_ms INTEGER,
        mode TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_review_logs_card ON review_logs(card_id, ts)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_review_logs_ts ON review_logs(ts)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS review_sessions(
        id INTEGER PRIMARY KEY,
        deck_id INTEGER REFERENCES decks(id) ON DELETE SET NULL,
        mode TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        card_count INTEGER NOT NULL DEFAULT 0,
        is_cram INTEGER NOT NULL DEFAULT 0,
        ratings_json TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS temporary_session_reviews(
        id INTEGER PRIMARY KEY,
        session_id INTEGER NOT NULL REFERENCES review_sessions(id) ON DELETE CASCADE,
        card_id INTEGER NOT NULL,
        rating TEXT NOT NULL,
        ts TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audio_cache(
        key TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        text TEXT NOT NULL,
        lang TEXT,
        provider TEXT,
        voice TEXT,
        params_json TEXT,
        size_bytes INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ===== V3 =====
  static Future<void> _migrateV3(Database db) async {
    // Add was_new to review_logs
    final rlCols = await db.rawQuery('PRAGMA table_info(review_logs)');
    final rlNames = rlCols.map((c) => c['name'] as String).toSet();
    if (!rlNames.contains('was_new')) {
      await db.execute(
          'ALTER TABLE review_logs ADD COLUMN was_new INTEGER NOT NULL DEFAULT 0');
    }

    // Add suspended to cards
    final cardCols = await db.rawQuery('PRAGMA table_info(cards)');
    final cardNames = cardCols.map((c) => c['name'] as String).toSet();
    if (!cardNames.contains('suspended')) {
      await db.execute(
          'ALTER TABLE cards ADD COLUMN suspended INTEGER NOT NULL DEFAULT 0');
    }

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_review_logs_was_new_ts ON review_logs(was_new, ts)');
  }

  // ===== Seed =====
  static Future<void> _seedDefaultDeck(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM decks'),
        ) ??
        0;
    if (count > 0) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final deckId = await db.insert('decks', {
      'name': 'عام',
      'description': 'مجموعة البطاقات الافتراضية',
      'created_at': now,
      'modified_at': now,
    });

    // Default fields
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
  }

  static Future<void> close() async {
    if (_dbFuture == null) return;
    final db = await _dbFuture!;
    await db.close();
    _dbFuture = null;
  }
}