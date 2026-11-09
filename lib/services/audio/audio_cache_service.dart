import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/audio_cache_repository.dart';
import '../tts/tts_provider.dart';

class AudioCacheService {
  final AudioCacheRepository _repo;
  AudioCacheService([AudioCacheRepository? repo])
      : _repo = repo ?? AudioCacheRepository();

  Future<Directory> _cacheDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'midad', 'audio_cache'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String makeKey({
    required String text,
    required String lang,
    required String provider,
    required String voice,
    required double rate,
  }) {
    final normalized =
        '${text.trim()}|${lang.toLowerCase()}|$provider|$voice|${rate.toStringAsFixed(2)}';
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  Future<File> getOrCreate({
    required String text,
    required String lang,
    required TtsProvider provider,
    String? voiceId,
    double rate = 1.0,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) throw ArgumentError('Empty text');
    final key = makeKey(
      text: clean,
      lang: lang,
      provider: provider.name,
      voice: voiceId ?? '',
      rate: rate,
    );

    final existing = await _repo.get(key);
    if (existing != null) {
      final f = File(existing['file_path'] as String);
      if (await f.exists()) return f;
      await _repo.remove(key);
    }

    final dir = await _cacheDir();
    final file = await provider.synthesize(
      text: clean,
      language: lang,
      voiceId: voiceId,
      rate: rate,
      outputDir: dir,
    );

    await _repo.put(
      key: key,
      filePath: file.path,
      text: clean,
      lang: lang,
      provider: provider.name,
      voice: voiceId ?? '',
      paramsJson: jsonEncode({'rate': rate}),
      sizeBytes: await file.length(),
    );
    return file;
  }

  Future<int> totalSize() => _repo.totalSize();

  Future<void> clear() async {
    await _repo.clear();
    final dir = await _cacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}