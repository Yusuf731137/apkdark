import 'dart:io';

class TtsVoice {
  final String id;
  final String name;
  final String language;
  const TtsVoice({
    required this.id,
    required this.name,
    required this.language,
  });
}

abstract class TtsProvider {
  String get name;
  Future<bool> isAvailable();
  Future<List<TtsVoice>> availableVoices();
  Future<File> synthesize({
    required String text,
    required String language,
    String? voiceId,
    double rate,
    required Directory outputDir,
  });
  Future<void> stop();
}