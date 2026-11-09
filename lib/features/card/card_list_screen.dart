import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/card.dart';
import '../../domain/deck.dart';
import '../../shared/widgets/empty_state.dart';

class CardListScreen extends StatefulWidget {
  final AppStrings strings;
  const CardListScreen({super.key, required this.strings});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  final _cards = CardRepository();
  final _decks = DeckRepository();
  final _fields = FieldRepository();

  List<Card> _list = [];
  List<Deck> _deckList = [];
  int? _deckId;
  String _status = 'all';
  String _sort = 'created';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final decks = await _decks.list();
      final cards = await _cards.list(
        deckId: _deckId,
        status: _status == 'all' ? null : _status,
        sortBy: _sort,
      );
      if (!mounted) return;
      setState(() {
        _deckList = decks;
        _list = cards;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(Card c) async {
    final s = widget.strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteCard),
        content: Text('${s.delete} "${c.front}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _cards.delete(c.id);
      _load();
    } catch (_) {}
  }

  String _statusLabel(Card c) {
    if (c.suspended) return widget.strings.suspended;
    if (c.reps == 0) return widget.strings.newCard;
    if (c.state == 1 || c.state == 3) return widget.strings.learning;
    return widget.strings.review;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.navCards)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _deckId,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    dropdownColor: AppColors.surface,
                    items: [
                      DropdownMenuItem<int?>(
                          value: null, child: Text(s.allDecks)),
                      ..._deckList.map((d) => DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text(d.name),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() => _deckId = v);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _filterChip(s.filterAll, 'all'),
                _filterChip(s.filterNew, 'new'),
                _filterChip(s.filterLearning, 'learning'),
                _filterChip(s.filterReview, 'review'),
                _filterChip(s.filterDue, 'due'),
                _filterChip(s.filterSuspended, 'suspended'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.sort, color: AppColors.muted, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sort,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    dropdownColor: AppColors.surface,
                    items: [
                      DropdownMenuItem(
                          value: 'created', child: Text(s.sortCreated)),
                      DropdownMenuItem(
                          value: 'alpha', child: Text(s.sortAlpha)),
                      DropdownMenuItem(
                          value: 'last_review', child: Text(s.sortLastReview)),
                      DropdownMenuItem(value: 'due', child: Text(s.sortDue)),
                      DropdownMenuItem(
                          value: 'difficulty',
                          child: Text(s.sortDifficulty)),
                      DropdownMenuItem(
                          value: 'stability', child: Text(s.sortStability)),
                    ],
                    onChanged: (v) {
                      setState(() => _sort = v ?? 'created');
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_list.length} ${s.cards}',
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                    ? EmptyState(
                        icon: Icons.credit_card,
                        title: s.noCardsYet,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _list.length,
                          itemBuilder: (ctx, i) {
                            final c = _list[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListTile(
                                  title: Text(c.front,
                                      style: const TextStyle(
                                          color: AppColors.text)),
                                  subtitle: Text(c.back,
                                      style: const TextStyle(
                                          color: AppColors.muted)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _statusLabel(c),
                                          style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 10),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 18),
                                        onPressed: () => _delete(c),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: _status == value,
      onSelected: (_) {
        setState(() => _status = value);
        _load();
      },
    );
  }
}