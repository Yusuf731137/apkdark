import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../domain/deck.dart';
import '../../shared/widgets/stat_card.dart';
import '../deck/deck_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppStrings strings;
  const DashboardScreen({super.key, required this.strings});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _decks = DeckRepository();
  final _cards = CardRepository();
  List<Deck> _deckList = [];
  int _totalCards = 0;
  int _dueCount = 0;
  int _newCount = 0;
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
      final all = await _cards.list();
      final due = await _cards.due();
      if (!mounted) return;
      setState(() {
        _deckList = decks;
        _totalCards = all.length;
        _newCount = all.where((c) => c.reps == 0).length;
        _dueCount = due.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appName),
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
                  Text(
                    s.dashboardTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(label: s.statTotalCards, value: '$_totalCards'),
                      StatCard(label: s.statDue, value: '$_dueCount', accent: AppColors.fail),
                      StatCard(label: s.statNew, value: '$_newCount', accent: AppColors.good),
                      StatCard(label: s.statDecks, value: '${_deckList.length}'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.navDecks,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._deckList.map((d) => Padding(
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
                              d.description.isEmpty ? '—' : d.description,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            trailing: const Icon(Icons.chevron_left, color: AppColors.muted),
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
                      )),
                ],
              ),
            ),
    );
  }
}