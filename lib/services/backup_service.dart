import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupInfo {
  final File file;
  final DateTime createdAt;
  final int size;
  const BackupInfo({
    required this.file,
    required this.createdAt,
    required this.size,
  });
}

class BackupService {
  Future<Directory> _backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'midad', 'backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _dbFile() async {
    final docs = await getApplicationDocumentsDirectory();
    return File(p.join(docs.path, 'midad', 'cards.db'));
  }

  Future<List<BackupInfo>> list() async {
    final dir = await _backupDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();
    final out = <BackupInfo>[];
    for (final f in files) {
      final stat = await f.stat();
      out.add(BackupInfo(
        file: f,
        createdAt: stat.modified,
        size: stat.size,
      ));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<File> create() async {
    final src = await _dbFile();
    if (!await src.exists()) {
      throw StateError('Database not found');
    }
    final dir = await _backupDir();
    final ts = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final dest = File(p.join(dir.path, 'backup_$ts.db'));
    await src.copy(dest.path);
    return dest;
  }

  Future<void> restore(File backup) async {
    if (!await backup.exists()) {
      throw StateError('Backup file not found');
    }
    // Validate it's a valid SQLite database (magic bytes)
    final bytes = await backup.openRead(0, 16).first;
    if (bytes.length < 16 || String.fromCharCodes(bytes.take(15)) != 'SQLite format 3') {
      throw StateError('Invalid backup file (not SQLite)');
    }
    // Create safety backup of current DB
    try {
      await create();
    } catch (_) {}
    // Overwrite live DB
    final dest = await _dbFile();
    await backup.copy(dest.path);
  }

  Future<void> share(File backup) async {
    await Share.shareXFiles([XFile(backup.path)]);
  }

  Future<void> delete(File backup) async {
    if (await backup.exists()) await backup.delete();
  }
}