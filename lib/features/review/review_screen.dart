import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/field_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/card.dart';
import '../../domain/field.dart';
import '../../domain/field_type.dart';
import '../../domain/rating.dart';
import '../../domain/review_mode.dart';
import '../../services/audio/audio_cache_service.dart';
import '../../services/review_engine.dart';
import '../../services/tts/tts_registry.dart';
import 'widgets/audio_player_widget.dart';

class ReviewScreen extends StatefulWidget {
  final AppStrings strings;
  final int? deckId;
  final ReviewMode mode;
  final bool isCram;
  final int? limit;
  final int? dailyNew;
  final int? dailyReview;

  const ReviewScreen({
    super.key,
    required this.strings,
    required this.deckId,
    required this.mode,
    required this.isCram,
    this.limit,
    this.dailyNew,
    this.dailyReview,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _fields = FieldRepository();
  final _cards = CardRepository();
  final _settings = SettingsRepository();
  final _engine = ReviewEngine();
  final _tts = TtsRegistry();
  final _cache = AudioCacheService();

  SessionState? _state;
  Card? _card;
  List<FieldDef> _fieldDefs = [];
  Map<int, String> _values = {};
  bool _revealed = false;
  bool _busy = false;
  bool _loading = true;
  Map<Rating, String> _previews = {};
  int _speakToken = 0;
  DateTime? _cardStartedAt;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    setState(() => _loading = true);
    try {
      final state = await _engine.start(
        deckId: widget.deckId,
        mode: widget.mode,
        isCram: widget.isCram,
        limit: widget.limit,
        dailyNew: widget.dailyNew,
        dailyReview: widget.dailyReview,
      );
      if (!mounted) return;
      setState(() {
        _state = state;
        _loading = false;
      });
      await _loadCurrent();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCurrent() async {
    _speakToken++;
    if (_state == null) return;
    final card = await _engine.current(_state!);
    if (!mounted) return;
    if (card == null) {
      setState(() {
        _card = null;
        _revealed = false;
      });
      await _finish();
      return;
    }

    final fields = await _fields.forDeck(card.deckId);
    final values = await _fields.valuesForCard(card.id);
    if (values.isEmpty) {
      // Legacy fallback
      final front = fields
          .where((f) =>
              f.side == FieldSide.front || f.side == FieldSide.both)
          .toList();
      final back = fields
          .where((f) => f.side == FieldSide.back || f.side == FieldSide.both)
          .toList();
      if (front.isNotEmpty) values[front.first.id] = card.front;
      if (back.isNotEmpty) values[back.first.id] = card.back;
    }

    if (!mounted) return;
    setState(() {
      _card = card;
      _fieldDefs = fields;
      _values = values;
      _revealed = false;
      _previews = {};
      _cardStartedAt = DateTime.now();
    });

    _maybeAutoSpeak(true);
  }

  Future<void> _finish() async {
    if (_state == null) return;
    await _engine.finish(_state!);
  }

  void _reveal() {
    if (_card == null || _revealed) return;
    final previews = _engine.previewIntervals(_card!);
    setState(() {
      _revealed = true;
      _previews = previews;
    });
    _maybeAutoSpeak(false);
  }

  Future<void> _rate(Rating rating) async {
    if (_card == null || !_revealed || _busy) return;
    setState(() => _busy = true);
    final durationMs = _cardStartedAt != null
        ? DateTime.now().difference(_cardStartedAt!).inMilliseconds
        : 0;
    try {
      await _engine.rate(
        state: _state!,
        card: _card!,
        rating: rating,
        durationMs: durationMs,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await _loadCurrent();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.strings.error}: $e')),
      );
    }
  }

  List<FieldDef> _fieldsForSide(bool front) {
    final side = front ? FieldSide.front : FieldSide.back;
    final list = _fieldDefs
        .where((f) => f.side == side || f.side == FieldSide.both)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  FieldDef? _ttsFieldFor(bool front) {
    for (final f in _fieldsForSide(front)) {
      if (f.type == FieldType.tts) return f;
    }
    return null;
  }

  Future<void> _maybeAutoSpeak(bool front) async {
    final token = ++_speakToken;
    final key = front
        ? 'review.auto_pronounce_front'
        : 'review.auto_pronounce_back';
    final enabled = await _settings.getBool(key);
    if (!enabled) return;
    final delay = await _settings.getInt('review.auto_pronounce_delay_ms');
    await Future.delayed(Duration(milliseconds: delay));
    if (token != _speakToken) return;
    if (!mounted) return;
    if (front != !_revealed) return; // state mismatch
    await _speakCurrent(front);
  }

  Future<File?> _prepareAudio(bool front) async {
    final field = _ttsFieldFor(front);
    String text;
    String lang;
    String? voice;
    double rate;
    String providerName;

    if (field != null) {
      text = _values[field.id] ?? '';
      lang = field.language.isNotEmpty ? field.language : '';
      voice = field.ttsVoice;
      rate = field.ttsRate;
      providerName = field.ttsProvider ?? 'system';
    } else {
      text = front ? (_card?.front ?? '') : (_card?.back ?? '');
      lang = '';
      voice = null;
      rate = await _settings.getDouble('audio.speed');
      if (rate == 0) rate = 1.0;
      providerName = 'system';
    }

    if (text.trim().isEmpty) return null;

    final provider = _tts.get(providerName);
    try {
      return await _cache.getOrCreate(
        text: text,
        lang: lang,
        provider: provider,
        voiceId: voice,
        rate: rate,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _speakCurrent(bool front) async {
    final file = await _prepareAudio(front);
    if (file == null || !mounted) return;
    // Playback handled by AudioPlayerWidget via file system
    // For auto-pronounce, use a separate player to avoid interfering
    try {
      final player = TtsRegistry();
      await player.system.stop();
    } catch (_) {}
    // Use simple playback through the audio widget's onPrepare
    // We'll trigger a rebuild with the file via state
    setState(() => _pendingAutoFile = file);
  }

  File? _pendingAutoFile;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(s.reviewTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_state == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.reviewTitle)),
        body: Center(child: Text(s.error, style: const TextStyle(color: AppColors.muted))),
      );
    }
    if (_card == null) {
      return _completionView();
    }
    return _cardView();
  }

  Widget _cardView() {
    final s = widget.strings;
    final remaining = _state!.queue.length - _state!.index;
    final front = !_revealed;
    final displayFields = _fieldsForSide(front);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.reviewTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                '$remaining',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _reveal,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 280),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        front ? s.question : s.answer,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._renderSide(displayFields),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AudioPlayerWidget(
              key: ValueKey(
                  '${_card!.id}_$_revealed'),
              strings: s,
              onPrepare: () => _prepareAudio(!_revealed ? true : false),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _revealed
                ? _ratingRow()
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _reveal,
                      child: Text(
                        s.flip,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _renderSide(List<FieldDef> fields) {
    final widgets = <Widget>[];
    for (final f in fields) {
      final text = _values[f.id] ?? '';
      if (text.trim().isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: f.fontSize.toDouble().clamp(14, 48),
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ));
    }
    if (widgets.isEmpty) {
      widgets.add(const Text(
        '—',
        style: TextStyle(color: AppColors.muted, fontSize: 20),
      ));
    }
    return widgets;
  }

  Widget _ratingRow() {
    return Row(
      children: [
        _ratingBtn(widget.strings.ratingFail, AppColors.fail, Rating.fail),
        const SizedBox(width: 6),
        _ratingBtn(widget.strings.ratingHard, AppColors.hard, Rating.hard),
        const SizedBox(width: 6),
        _ratingBtn(widget.strings.ratingGood, AppColors.good, Rating.good),
        const SizedBox(width: 6),
        _ratingBtn(widget.strings.ratingEasy, AppColors.easy, Rating.easy),
      ],
    );
  }

  Widget _ratingBtn(String label, Color color, Rating r) {
    final preview = _previews[r];
    return Expanded(
      child: SizedBox(
        height: 68,
        child: ElevatedButton(
          onPressed: _busy ? null : () => _rate(r),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (preview != null) ...[
                const SizedBox(height: 2),
                Text(preview, style: const TextStyle(fontSize: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _completionView() {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.sessionComplete)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration,
                size: 72, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              s.sessionComplete,
              style: const TextStyle(fontSize: 24, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              '${_state!.queue.length} ${s.reviewedCount}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            _summaryChips(),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.back),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChips() {
    final r = _state!.ratings;
    final items = [
      ('FAIL', r['FAIL'] ?? 0, AppColors.fail),
      ('HARD', r['HARD'] ?? 0, AppColors.hard),
      ('GOOD', r['GOOD'] ?? 0, AppColors.good),
      ('EASY', r['EASY'] ?? 0, AppColors.easy),
    ];
    return Wrap(
      spacing: 8,
      children: items
          .map((e) => Chip(
                label: Text('${e.$1}: ${e.$2}'),
                backgroundColor: e.$3.withOpacity(0.2),
                labelStyle: TextStyle(color: e.$3),
              ))
          .toList(),
    );
  }
}