import 'package:flutter/material.dart' hide Card;
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/card_repository.dart';
import '../../domain/card.dart';
import '../../domain/deck.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/stat_card.dart';
import '../card/card_editor_screen.dart';
import '../review/review_setup_screen.dart';
import 'edit_deck_screen.dart';
import 'widgets/grade_chart.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;
  final AppStrings strings;
  const DeckDetailScreen({super.key, required this.deck, required this.strings});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final _cards = CardRepository();
  List<Card> _list = <Card>[];
  List<Card> _due = <Card>[];
  Map<String, int> _grades = <String, int>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _cards.list(deckId: widget.deck.id);
      final due = await _cards.due(deckId: widget.deck.id);
      final grades = <String, int>{};
      for (final Card c in list) {
        grades[c.grade] = (grades[c.grade] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _list = list;
        _due = due;
        _grades = grades;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addCard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardEditorScreen(deck: widget.deck, strings: widget.strings),
      ),
    );
    _load();
  }

  Future<void> _editCard(Card c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardEditorScreen(deck: widget.deck, strings: widget.strings, card: c),
      ),
    );
    _load();
  }

  Future<void> _editDeck() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditDeckScreen(deck: widget.deck, strings: widget.strings),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _startReview() async {
    if (_due.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewSetupScreen(
          strings: widget.strings,
          preselectedDeckId: widget.deck.id,
        ),
      ),
    );
    _load();
  }

  int _newCount() => _list.where((Card c) => c.reps == 0).length;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editDeck),
          IconButton(icon: const Icon(Icons.add), onPressed: _addCard),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.1,
                    children: [
                      StatCard(label: s.cards, value: '${_list.length}'),
                      StatCard(
                          label: s.due,
                          value: '${_due.length}',
                          accent: AppColors.fail),
                      StatCard(
                          label: s.statNew,
                          value: '${_newCount()}',
                          accent: AppColors.good),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                            s.gradeDistribution,
                            style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        GradeChart(grades: _grades),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(s.cards,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${_list.length}',
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_list.isEmpty)
                    EmptyState(
                      icon: Icons.credit_card,
                      title: s.noCardsYet,
                      action: FilledButton(
                          onPressed: _addCard, child: Text(s.newCard)),
                    )
                  else
                    ..._list.map((Card c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              title: Text(c.front,
                                  style:
                                      const TextStyle(color: AppColors.text)),
                              subtitle: Text(c.back,
                                  style: const TextStyle(
                                      color: AppColors.muted)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(c.grade,
                                    style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11)),
                              ),
                              onTap: () => _editCard(c),
                            ),
                          ),
                        )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: _due.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _startReview,
              icon: const Icon(Icons.play_arrow),
              label: Text('${s.review} (${_due.length})'),
            ),
    );
  }
}
