import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/deck.dart';
import '../../domain/review_mode.dart';
import 'review_screen.dart';

class ReviewSetupScreen extends StatefulWidget {
  final AppStrings strings;
  final int? preselectedDeckId;
  const ReviewSetupScreen({
    super.key,
    required this.strings,
    this.preselectedDeckId,
  });

  @override
  State<ReviewSetupScreen> createState() => _ReviewSetupScreenState();
}

class _ReviewSetupScreenState extends State<ReviewSetupScreen> {
  final _decks = DeckRepository();
  final _settings = SettingsRepository();

  List<Deck> _all = [];
  int? _deckId;
  ReviewMode _mode = ReviewMode.fsrs;
  bool _cram = false;
  int _limit = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _deckId = widget.preselectedDeckId;
    _load();
  }

  Future<void> _load() async {
    final decks = await _decks.list();
    final modeStr = await _settings.get('review.mode') ?? 'FSRS';
    final limit = await _settings.getInt('review.new_per_day');
    if (!mounted) return;
    setState(() {
      _all = decks;
      _mode = ReviewMode.fromString(modeStr);
      _limit = limit > 0 ? limit : 0;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final s = widget.strings;
    final dailyNew = await _settings.getInt('review.new_per_day');
    final dailyReview = await _settings.getInt('review.review_per_day');
    final dn = dailyNew < 0 ? null : dailyNew;
    final dr = dailyReview < 0 ? null : dailyReview;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          strings: s,
          deckId: _deckId,
          mode: _mode,
          isCram: _cram,
          limit: _limit > 0 ? _limit : null,
          dailyNew: dn,
          dailyReview: dr,
        ),
      ),
    ).then((_) {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.reviewTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  s.selectDeck,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: _deckId,
                  decoration: const InputDecoration(),
                  dropdownColor: AppColors.surface,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(s.allDecks),
                    ),
                    ..._all.map((d) => DropdownMenuItem<int?>(
                          value: d.id,
                          child: Text(d.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _deckId = v),
                ),
                const SizedBox(height: 16),
                Text(
                  s.reviewMode,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ReviewMode>(
                  segments: [
                    ButtonSegment(
                      value: ReviewMode.fsrs,
                      label: Text(s.modeFsrs),
                    ),
                    ButtonSegment(
                      value: ReviewMode.random,
                      label: Text(s.modeRandom),
                    ),
                    ButtonSegment(
                      value: ReviewMode.created,
                      label: Text(s.modeCreated),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (v) =>
                      setState(() => _mode = v.first),
                ),
                const SizedBox(height: 16),
                Text(
                  '${s.limitOptional} (${_limit == 0 ? s.noLimit : _limit})',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Slider(
                  value: _limit.toDouble().clamp(0, 100),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) => setState(() => _limit = v.round()),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _cram,
                  onChanged: (v) => setState(() => _cram = v),
                  title: Text(
                    s.cramSession,
                    style: const TextStyle(color: AppColors.text),
                  ),
                  subtitle: Text(
                    s.cramHint,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _start,
                    child: Text(
                      s.startSession,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}