import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../services/audio/waveform_service.dart';
import 'waveform_widget.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Future<File?> Function() onPrepare;
  final AppStrings strings;
  final VoidCallback? onStopped;
  const AudioPlayerWidget({
    super.key,
    required this.onPrepare,
    required this.strings,
    this.onStopped,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _player = AudioPlayerService();
  List<double> _peaks = [];
  bool _loading = false;
  bool _prepared = false;
  String? _error;
  double _speed = 1.0;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _posSub = _player.positionStream.listen((p) {
      if (mounted) setState(() => _pos = p);
    });
    _durSub = _player.durationStream.listen((d) {
      if (mounted) setState(() => _dur = d ?? Duration.zero);
    });
    _stateSub = _player.playerStateStream.listen((s) {
      if (!mounted) return;
      final playing = s.playing &&
          s.processingState != ProcessingState.completed;
      setState(() {
        _isPlaying = playing;
        if (s.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    if (_loading || _prepared) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await widget.onPrepare();
      if (file == null) {
        setState(() {
          _loading = false;
          _error = widget.strings.audioUnavailable;
        });
        return;
      }
      await _player.setFile(file, rate: _speed);
      final peaks = await WaveformService.extractPeaks(file);
      if (!mounted) return;
      setState(() {
        _peaks = peaks ?? [];
        _prepared = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _togglePlay() async {
    if (!_prepared) {
      await _prepare();
      if (!_prepared) return;
    }
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void _seek(double fraction) {
    if (_dur.inMilliseconds <= 0) return;
    final target =
        Duration(milliseconds: (_dur.inMilliseconds * fraction).round());
    _player.seek(target);
  }

  Future<void> _changeSpeed(double v) async {
    setState(() => _speed = v);
    if (_prepared) await _player.setSpeed(v);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Material(
                  color: AppColors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _loading ? null : _togglePlay,
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error != null
                      ? _error!
                      : '${_fmt(_pos)} / ${_fmt(_dur)}',
                  style: TextStyle(
                    color: _error != null ? AppColors.fail : AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              DropdownButton<double>(
                value: _speed,
                dropdownColor: AppColors.surface,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                  DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                  DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                  DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                  DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                  DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                ],
                onChanged: (v) {
                  if (v != null) _changeSpeed(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          WaveformWidget(
            peaks: _peaks,
            progress: _dur.inMilliseconds == 0
                ? 0.0
                : (_pos.inMilliseconds / _dur.inMilliseconds)
                    .clamp(0.0, 1.0),
            onSeek: () {},
            height: 50,
          ),
          if (!_prepared && _error == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: _prepare,
                child: Text(s.preparingAudio),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}