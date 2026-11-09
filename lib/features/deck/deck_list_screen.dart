import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../domain/deck.dart';
import '../../shared/widgets/empty_state.dart';
import 'deck_detail_screen.dart';

class DeckListScreen extends StatefulWidget {
  final AppStrings strings;
  const DeckListScreen({super.key, required this.strings});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  final _decks = DeckRepository();
  final _cards = CardRepository();
  List<Deck> _list = [];
  Map<int, int> _counts = {};
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
      final counts = <int, int>{};
      for (final d in decks) {
        final cards = await _cards.list(deckId: d.id);
        counts[d.id] = cards.length;
      }
      if (!mounted) return;
      setState(() {
        _list = decks;
        _counts = counts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final s = widget.strings;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.newDeck),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: s.deckName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.save)),
        ],
      ),
    );
    if (ok != true) return;
    final name = controller.text.trim();
    if (name.isEmpty) {
      if (mounted) _showError(s.deckNameRequired);
      return;
    }
    try {
      await _decks.create(name: name);
      await _load();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _delete(Deck d) async {
    final s = widget.strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteDeck),
        content: Text('${s.delete} "${d.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _decks.delete(d.id);
      await _load();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.decksTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? EmptyState(
                  icon: Icons.style,
                  title: s.noDecksYet,
                  action: FilledButton(onPressed: _create, child: Text(s.newDeck)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _list.length,
                    itemBuilder: (ctx, i) {
                      final d = _list[i];
                      final count = _counts[d.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            title: Text(d.name, style: const TextStyle(color: AppColors.text)),
                            subtitle: Text(
                              '$count ${s.cards}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppColors.muted),
                              onSelected: (v) {
                                if (v == 'delete') _delete(d);
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'delete', child: Text(s.delete)),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeckDetailScreen(deck: d, strings: s),
                                ),
                              );
                              _load();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
    );
  }
}