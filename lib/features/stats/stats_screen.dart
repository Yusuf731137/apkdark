import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/deck_repository.dart';
import '../../domain/deck.dart';
import '../../services/stats_service.dart';
import '../../shared/widgets/stat_card.dart';
import '../deck/widgets/grade_chart.dart';

class StatsScreen extends StatefulWidget {
  final AppStrings strings;
  const StatsScreen({super.key, required this.strings});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _service = StatsService();
  final _decks = DeckRepository();

  List<Deck> _all = [];
  int? _deckId;
  int _range = 7; // 7, 30, 90, 0 (all)
  Map<String, int> _overview = {};
  Map<String, int> _ratings = {};
  Map<String, int> _grades = {};
  List<(String, int)> _trend = [];
  int _today = 0;
  double _avgMs = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await _decks.list();
      await _refresh();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final overview = await _service.overview(deckId: _deckId);
      final ratings = await _service.ratingCounts(deckId: _deckId);
      final grades = await _service.gradeDistribution(deckId: _deckId);
      final trend = await _service.reviewsByDay(
        days: _range == 0 ? 365 : _range,
        deckId: _deckId,
      );
      final today = await _service.reviewedToday(deckId: _deckId);
      final avg = await _service.averageDurationMs(deckId: _deckId);
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _ratings = ratings;
        _grades = grades;
        _trend = trend;
        _today = today;
        _avgMs = avg;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.statsTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<int?>(
                    value: _deckId,
                    decoration: InputDecoration(labelText: s.navDecks),
                    dropdownColor: AppColors.surface,
                    items: [
                      DropdownMenuItem<int?>(
                          value: null, child: Text(s.allDecks)),
                      ..._all.map((d) => DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text(d.name),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _deckId = v);
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [
                      _rangeChip(s.last7Days, 7),
                      _rangeChip(s.last30Days, 30),
                      _rangeChip(s.last90Days, 90),
                      _rangeChip(s.allTime, 0),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        label: s.totalCardsLabel,
                        value: '${_overview['total'] ?? 0}',
                      ),
                      StatCard(
                        label: s.newCardsLabel,
                        value: '${_overview['new'] ?? 0}',
                        accent: AppColors.good,
                      ),
                      StatCard(
                        label: s.dueCardsLabel,
                        value: '${_overview['due'] ?? 0}',
                        accent: AppColors.fail,
                      ),
                      StatCard(
                        label: s.reviewedToday,
                        value: '$_today',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _card(
                    title: s.reviewsTrend,
                    child: _trendBarChart(),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: s.ratingDistribution,
                    child: _ratingBars(),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: s.gradeDistribution,
                    child: GradeChart(grades: _grades),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: s.avgDuration,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${(_avgMs / 1000).toStringAsFixed(1)} ${s.seconds}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _rangeChip(String label, int v) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _range == v,
      onSelected: (_) {
        setState(() => _range = v);
        _refresh();
      },
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child,
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _trendBarChart() {
    if (_trend.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('—', style: TextStyle(color: AppColors.muted)),
      );
    }
    final maxV = _trend.fold<int>(1, (a, b) => b.$2 > a ? b.$2 : a);
    return SizedBox(
      height: 140,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _trend.map((e) {
            final h = (e.$2 / maxV) * 90;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${e.$2}',
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.$1.substring(5),
                      style: const TextStyle(
                          fontSize: 8, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _ratingBars() {
    final items = [
      ('FAIL', _ratings['FAIL'] ?? 0, AppColors.fail),
      ('HARD', _ratings['HARD'] ?? 0, AppColors.hard),
      ('GOOD', _ratings['GOOD'] ?? 0, AppColors.good),
      ('EASY', _ratings['EASY'] ?? 0, AppColors.easy),
    ];
    final maxV = items.fold<int>(1, (a, b) => b.$2 > a ? b.$2 : a);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items.map((e) {
          final frac = e.$2 / maxV;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    e.$1,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation(e.$3),
                      minHeight: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${e.$2}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}