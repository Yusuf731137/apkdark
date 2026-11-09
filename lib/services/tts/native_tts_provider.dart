import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'tts_provider.dart';

class NativeTtsProvider implements TtsProvider {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  @override
  String get name => 'system';

  Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      await _tts.setSharedInstance(true);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
    _initialized = true;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      await _ensureInit();
      final engines = await _tts.getEngines;
      final languages = await _tts.getLanguages;
      return (engines is List && engines.isNotEmpty) ||
          (languages is List && languages.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<TtsVoice>> availableVoices() async {
    try {
      await _ensureInit();
      final raw = await _tts.getVoices;
      if (raw is! List) return [];
      return raw.map((v) {
        final map = (v as Map).cast<String, dynamic>();
        return TtsVoice(
          id: (map['name'] ?? '').toString(),
          name: (map['name'] ?? '').toString(),
          language: (map['locale'] ?? map['language'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<File> synthesize({
    required String text,
    required String language,
    String? voiceId,
    double rate = 1.0,
    required Directory outputDir,
  }) async {
    await _ensureInit();
    final clean = text.trim();
    if (clean.isEmpty) {
      throw ArgumentError('Cannot synthesize empty text');
    }

    // Normalize language: 'ar' -> 'ar-SA', 'en' -> 'en-US'
    final lang = _normalizeLanguage(language);

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    final fileName =
        'tts_${DateTime.now().microsecondsSinceEpoch}.wav';
    final path = p.join(outputDir.path, fileName);

    try {
      if (voiceId != null && voiceId.isNotEmpty) {
        await _tts.setVoice({'name': voiceId, 'locale': lang});
      }
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(_mapRate(rate));
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      // synthesizeToFile on Android produces WAV
      final ok = await _tts.synthesizeToFile(clean, path, true);
      if (ok != 1 && !await File(path).exists()) {
        throw StateError('TTS synthesizeToFile failed');
      }
    } catch (e) {
      throw StateError('TTS error: $e');
    }

    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      throw StateError('TTS produced empty file');
    }
    return file;
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static String _normalizeLanguage(String lang) {
    final l = lang.trim().toLowerCase();
    if (l.isEmpty) return 'en-US';
    if (l == 'ar') return 'ar-SA';
    if (l == 'en') return 'en-US';
    return lang.trim();
  }

  static double _mapRate(double rate) {
    // flutter_tts: 0.5 = half speed, 1.0 = normal, 2.0 = double
    final r = rate.clamp(0.5, 2.0);
    return r;
  }
}