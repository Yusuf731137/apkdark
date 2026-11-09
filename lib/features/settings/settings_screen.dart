import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/audio/audio_cache_service.dart';
import '../../services/tts/tts_registry.dart';
import '../../domain/review_mode.dart';

class SettingsScreen extends StatefulWidget {
  final AppStrings strings;
  final ValueChanged<String> onLanguageChanged;
  const SettingsScreen({
    super.key,
    required this.strings,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = SettingsRepository();
  final _cache = AudioCacheService();
  final _tts = TtsRegistry();

  String _lang = 'ar';
  ReviewMode _mode = ReviewMode.fsrs;
  int _newPerDay = 20;
  int _reviewPerDay = 200;
  bool _autoFront = true;
  bool _autoBack = true;
  int _autoDelay = 300;
  double _audioSpeed = 1.0;
  double _volume = 0.9;
  int _cacheBytes = 0;
  double _retention = 0.9;
  int _maxInterval = 3650;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lang = await _repo.get('general.language') ?? 'ar';
    final modeStr = await _repo.get('review.mode') ?? 'FSRS';
    final newPer = await _repo.getInt('review.new_per_day');
    final revPer = await _repo.getInt('review.review_per_day');
    final af = await _repo.getBool('review.auto_pronounce_front');
    final ab = await _repo.getBool('review.auto_pronounce_back');
    final delay = await _repo.getInt('review.auto_pronounce_delay_ms');
    final speed = await _repo.getDouble('audio.speed');
    final vol = await _repo.getDouble('audio.volume');
    final ret = await _repo.getDouble('fsrs.desired_retention');
    final maxI = await _repo.getInt('fsrs.max_interval_days');
    final csize = await _cache.totalSize();

    if (!mounted) return;
    setState(() {
      _lang = lang;
      _mode = ReviewMode.fromString(modeStr);
      _newPerDay = newPer;
      _reviewPerDay = revPer;
      _autoFront = af;
      _autoBack = ab;
      _autoDelay = delay;
      _audioSpeed = speed == 0 ? 1.0 : speed;
      _volume = vol == 0 ? 0.9 : vol;
      _retention = ret == 0 ? 0.9 : ret;
      _maxInterval = maxI == 0 ? 3650 : maxI;
      _cacheBytes = csize;
      _loading = false;
    });
  }

  Future<void> _save() async {
    try {
      await _repo.set('general.language', _lang);
      await _repo.set('review.mode', _mode.value);
      await _repo.set('review.new_per_day', '$_newPerDay');
      await _repo.set('review.review_per_day', '$_reviewPerDay');
      await _repo.set('review.auto_pronounce_front', '$_autoFront');
      await _repo.set('review.auto_pronounce_back', '$_autoBack');
      await _repo.set('review.auto_pronounce_delay_ms', '$_autoDelay');
      await _repo.set('audio.speed', '$_audioSpeed');
      await _repo.set('audio.volume', '$_volume');
      await _repo.set('fsrs.desired_retention', '$_retention');
      await _repo.set('fsrs.max_interval_days', '$_maxInterval');
      widget.onLanguageChanged(_lang);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.save)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.strings.operationFailed}: $e')),
      );
    }
  }

  Future<void> _clearCache() async {
    await _cache.clear();
    final size = await _cache.totalSize();
    if (!mounted) return;
    setState(() => _cacheBytes = size);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.strings.cacheCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsTitle),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('اللغة / Language'),
                _dropdown<String>(
                  value: _lang,
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) => setState(() => _lang = v ?? 'ar'),
                  label: s.language,
                ),

                _section(s.reviewMode2),
                _dropdown<ReviewMode>(
                  value: _mode,
                  items: [
                    DropdownMenuItem(
                        value: ReviewMode.fsrs, child: Text(s.modeFsrs)),
                    DropdownMenuItem(
                        value: ReviewMode.random, child: Text(s.modeRandom)),
                    DropdownMenuItem(
                        value: ReviewMode.created, child: Text(s.modeCreated)),
                  ],
                  onChanged: (v) =>
                      setState(() => _mode = v ?? ReviewMode.fsrs),
                  label: s.reviewMode,
                ),
                _numberInput(
                  label: s.dailyNewLimit,
                  value: _newPerDay,
                  onChanged: (v) => setState(() => _newPerDay = v),
                  min: -1,
                  max: 1000,
                ),
                _numberInput(
                  label: s.dailyReviewLimit,
                  value: _reviewPerDay,
                  onChanged: (v) => setState(() => _reviewPerDay = v),
                  min: -1,
                  max: 5000,
                ),

                _section('الصوت / Audio'),
                _switch(
                  label: s.autoPronounceFront,
                  value: _autoFront,
                  onChanged: (v) => setState(() => _autoFront = v),
                ),
                _switch(
                  label: s.autoPronounceBack,
                  value: _autoBack,
                  onChanged: (v) => setState(() => _autoBack = v),
                ),
                _slider(
                  label: '${s.autoPronounceDelay}: $_autoDelay ms',
                  value: _autoDelay.toDouble().clamp(0, 2000),
                  min: 0,
                  max: 2000,
                  divisions: 40,
                  onChanged: (v) =>
                      setState(() => _autoDelay = v.round()),
                ),
                _slider(
                  label: '${s.defaultSpeed}: ${_audioSpeed.toStringAsFixed(2)}x',
                  value: _audioSpeed.clamp(0.5, 2.0),
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  onChanged: (v) => setState(() => _audioSpeed = v),
                ),
                _slider(
                  label: '${s.volumeLabel}: ${(_volume * 100).round()}%',
                  value: _volume.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (v) => setState(() => _volume = v),
                ),

                _section('TTS'),
                _infoRow(
                  s.ttsProvider,
                  _tts.names.join(', '),
                ),
                _infoRow(
                  s.cacheSize,
                  '${(_cacheBytes / 1024 / 1024).toStringAsFixed(2)} MB',
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.delete_sweep),
                    label: Text(s.clearCache),
                  ),
                ),

                _section('FSRS'),
                _slider(
                  label:
                      '${s.desiredRetentionLabel}: ${(_retention * 100).round()}%',
                  value: _retention.clamp(0.5, 0.99),
                  min: 0.5,
                  max: 0.99,
                  divisions: 49,
                  onChanged: (v) => setState(() => _retention = v),
                ),
                _numberInput(
                  label: s.maxIntervalLabel,
                  value: _maxInterval,
                  onChanged: (v) => setState(() => _maxInterval = v),
                  min: 30,
                  max: 36500,
                ),

                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(s.save),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    s.aboutText2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'v0.4.0',
                    style:
                        TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label),
        dropdownColor: AppColors.surface,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _numberInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int min,
    required int max,
  }) {
    final controller = TextEditingController(text: '$value');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: '$label (-1 = ${widget.strings.unlimited})',
        ),
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null && parsed >= min && parsed <= max) {
            onChanged(parsed);
          }
        },
      ),
    );
  }

  Widget _switch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(color: AppColors.text)),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const Spacer(),
          Text(value,
              style: const TextStyle(color: AppColors.text, fontSize: 13)),
        ],
      ),
    );
  }
}