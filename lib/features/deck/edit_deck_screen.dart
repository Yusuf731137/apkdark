import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/deck.dart';
import '../../domain/field.dart';
import '../field/field_editor_screen.dart';

class EditDeckScreen extends StatefulWidget {
  final Deck deck;
  final AppStrings strings;
  const EditDeckScreen({super.key, required this.deck, required this.strings});

  @override
  State<EditDeckScreen> createState() => _EditDeckScreenState();
}

class _EditDeckScreenState extends State<EditDeckScreen> {
  final _deckRepo = DeckRepository();
  final _fieldRepo = FieldRepository();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  List<FieldDef> _fields = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.deck.name);
    _desc = TextEditingController(text: widget.deck.description);
    _load();
  }

  Future<void> _load() async {
    try {
      final fields = await _fieldRepo.forDeck(widget.deck.id);
      if (!mounted) return;
      setState(() {
        _fields = fields;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = widget.strings;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _showError(s.deckNameRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await _deckRepo.update(
        widget.deck.id,
        name: name,
        description: _desc.text.trim(),
        folderId: widget.deck.folderId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e.toString());
    }
  }

  Future<void> _addField() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FieldEditorScreen(
          deckId: widget.deck.id,
          strings: widget.strings,
          sortOrder: _fields.length,
        ),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _editField(FieldDef f) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FieldEditorScreen(
          deckId: widget.deck.id,
          strings: widget.strings,
          field: f,
        ),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _deleteField(FieldDef f) async {
    final s = widget.strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteField),
        content: Text('${s.delete} "${f.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _fieldRepo.delete(f.id);
      _load();
    } catch (_) {
      _showError(s.fieldInUse);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.editDeck),
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
                TextField(
                  controller: _name,
                  decoration: InputDecoration(labelText: s.deckName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _desc,
                  decoration: InputDecoration(labelText: s.deckDescription),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      s.fields,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addField,
                      icon: const Icon(Icons.add),
                      label: Text(s.addField),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._fields.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          title: Text(f.name, style: const TextStyle(color: AppColors.text)),
                          subtitle: Text(
                            '${f.type.value} · ${f.side.value}'
                            '${f.language.isNotEmpty ? ' · ${f.language}' : ''}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _editField(f),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () => _deleteField(f),
                              ),
                            ],
                          ),
                          onTap: () => _editField(f),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}