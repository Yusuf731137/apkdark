import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/field.dart';
import '../../domain/field_type.dart';

class FieldEditorScreen extends StatefulWidget {
  final int deckId;
  final AppStrings strings;
  final FieldDef? field;
  final int sortOrder;
  const FieldEditorScreen({
    super.key,
    required this.deckId,
    required this.strings,
    this.field,
    this.sortOrder = 0,
  });

  @override
  State<FieldEditorScreen> createState() => _FieldEditorScreenState();
}

class _FieldEditorScreenState extends State<FieldEditorScreen> {
  final _repo = FieldRepository();
  late final TextEditingController _name;
  late final TextEditingController _language;
  late final TextEditingController _provider;
  late final TextEditingController _voice;
  FieldType _type = FieldType.text;
  FieldSide _side = FieldSide.front;
  int _fontSize = 16;
  double _ttsRate = 1.0;
  FieldSource _source = FieldSource.manual;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _name = TextEditingController(text: f?.name ?? '');
    _language = TextEditingController(text: f?.language ?? '');
    _provider = TextEditingController(text: f?.ttsProvider ?? '');
    _voice = TextEditingController(text: f?.ttsVoice ?? '');
    if (f != null) {
      _type = f.type;
      _side = f.side;
      _fontSize = f.fontSize;
      _ttsRate = f.ttsRate;
      _source = f.source;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _language.dispose();
    _provider.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = widget.strings;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _showError(s.fieldName);
      return;
    }
    setState(() => _saving = true);
    try {
      final provider = _provider.text.trim();
      final voice = _voice.text.trim();
      if (widget.field == null) {
        await _repo.create(
          deckId: widget.deckId,
          name: name,
          type: _type,
          side: _side,
          language: _language.text.trim(),
          fontSize: _fontSize,
          ttsProvider: provider.isEmpty ? null : provider,
          ttsVoice: voice.isEmpty ? null : voice,
          ttsRate: _ttsRate,
          source: _source,
          sortOrder: widget.sortOrder,
        );
      } else {
        await _repo.update(
          widget.field!.copyWith(
            name: name,
            type: _type,
            side: _side,
            language: _language.text.trim(),
            fontSize: _fontSize,
            ttsProvider: provider.isEmpty ? null : provider,
            ttsVoice: voice.isEmpty ? null : voice,
            ttsRate: _ttsRate,
            source: _source,
          ),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.field == null ? s.addField : s.editField),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: s.fieldName),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<FieldType>(
            value: _type,
            decoration: InputDecoration(labelText: s.fieldType),
            dropdownColor: AppColors.surface,
            items: [
              DropdownMenuItem(value: FieldType.text, child: Text(s.typeText)),
              DropdownMenuItem(value: FieldType.tts, child: Text(s.typeTts)),
              DropdownMenuItem(value: FieldType.audio, child: Text(s.typeAudio)),
              DropdownMenuItem(value: FieldType.image, child: Text(s.typeImage)),
              DropdownMenuItem(value: FieldType.html, child: Text(s.typeHtml)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<FieldSide>(
            value: _side,
            decoration: InputDecoration(labelText: s.fieldSide),
            dropdownColor: AppColors.surface,
            items: [
              DropdownMenuItem(value: FieldSide.front, child: Text(s.sideFront)),
              DropdownMenuItem(value: FieldSide.back, child: Text(s.sideBack)),
              DropdownMenuItem(value: FieldSide.both, child: Text(s.sideBoth)),
            ],
            onChanged: (v) => setState(() => _side = v ?? _side),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _language,
            decoration: InputDecoration(
              labelText: s.fieldLanguage,
              hintText: 'ar-SA, en-US',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${s.fontSize}: $_fontSize',
                  style: const TextStyle(color: AppColors.text),
                ),
              ),
              Expanded(
                flex: 2,
                child: Slider(
                  value: _fontSize.toDouble(),
                  min: 8,
                  max: 72,
                  divisions: 64,
                  onChanged: (v) => setState(() => _fontSize = v.round()),
                ),
              ),
            ],
          ),
          if (_type == FieldType.tts) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              s.typeTts,
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _provider,
              decoration: InputDecoration(labelText: s.ttsProvider, hintText: 'system'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _voice,
              decoration: InputDecoration(labelText: s.ttsVoice),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              value: _ttsRate,
              decoration: InputDecoration(labelText: s.ttsRate),
              dropdownColor: AppColors.surface,
              items: const [
                DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                DropdownMenuItem(value: 2.0, child: Text('2.0x')),
              ],
              onChanged: (v) => setState(() => _ttsRate = v ?? 1.0),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<FieldSource>(
            value: _source,
            decoration: InputDecoration(labelText: s.source),
            dropdownColor: AppColors.surface,
            items: const [
              DropdownMenuItem(value: FieldSource.manual, child: Text('MANUAL')),
              DropdownMenuItem(value: FieldSource.ai, child: Text('AI')),
              DropdownMenuItem(value: FieldSource.imported, child: Text('IMPORTED')),
            ],
            onChanged: (v) => setState(() => _source = v ?? _source),
          ),
        ],
      ),
    );
  }
}