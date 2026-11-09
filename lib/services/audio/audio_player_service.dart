import 'dart:io';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  double _volume = 0.9;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
  }

  Future<void> setFile(File file, {double rate = 1.0}) async {
    try {
      await _player.stop();
      await _player.setFilePath(file.path);
      await _player.setSpeed(rate.clamp(0.5, 2.0));
      await _player.setVolume(_volume);
    } catch (e) {
      throw StateError('Cannot load audio: $e');
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
    } catch (_) {}
  }

  Future<void> pause() async => _player.pause();

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (_) {}
  }

  Future<void> setSpeed(double rate) async {
    try {
      await _player.setSpeed(rate.clamp(0.5, 2.0));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}