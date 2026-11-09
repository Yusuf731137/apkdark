import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/card.dart';
import '../../domain/deck.dart';
import '../../domain/field.dart';
import '../../domain/field_type.dart';

class CardEditorScreen extends StatefulWidget {
  final Deck deck;
  final AppStrings strings;
  final Card? card;
  const CardEditorScreen({
    super.key,
    required this.deck,
    required this.strings,
    this.card,
  });

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _cardRepo = CardRepository();
  final _fieldRepo = FieldRepository();
  final Map<int, TextEditingController> _controllers = {};
  List<FieldDef> _fields = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fields = await _fieldRepo.forDeck(widget.deck.id);
      Map<int, String> values = {};
      if (widget.card != null) {
        values = await _fieldRepo.valuesForCard(widget.card!.id);
        if (values.isEmpty) {
          // Legacy fallback
          for (final f in fields) {
            if (f.side == FieldSide.front && values.isEmpty) {
              values[f.id] = widget.card!.front;
            } else if (f.side == FieldSide.back) {
              values[f.id] = widget.card!.back;
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _fields = fields;
        _controllers.clear();
        for (final f in fields) {
          _controllers[f.id] = TextEditingController(text: values[f.id] ?? '');
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final s = widget.strings;
    final values = <int, String>{};
    for (final e in _controllers.entries) {
      final text = e.value.text.trim();
      if (text.isNotEmpty) values[e.key] = text;
    }
    if (values.isEmpty) {
      _showError(s.frontBackRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.card == null) {
        await _cardRepo.createWithValues(deckId: widget.deck.id, values: values);
      } else {
        await _cardRepo.updateValues(widget.card!.id, values);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final title = widget.card == null ? s.newCard : s.editCard;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final f in _fields) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          f.name,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f.side.value,
                            style: const TextStyle(color: AppColors.muted, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _controllers[f.id],
                    maxLines: 3,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: f.fontSize.toDouble(),
                    ),
                    decoration: InputDecoration(
                      hintText: f.language.isNotEmpty ? f.language : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}