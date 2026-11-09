import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/field_repository.dart';
import '../../domain/field.dart';
import '../../domain/field_type.dart';

class ImportScreen extends StatefulWidget {
  final AppStrings strings;
  const ImportScreen({super.key, required this.strings});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _decks = DeckRepository();
  final _cards = CardRepository();
  final _fields = FieldRepository();

  File? _file;
  String _defaultDeck = 'مستوردة';
  bool _busy = false;
  String? _error;
  int _imported = 0;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _file = File(result.files.single.path!);
      _error = null;
      _imported = 0;
    });
  }

  Future<void> _import() async {
    if (_file == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final content = await _file!.readAsString();
      final imported = await _doImport(content);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _imported = imported;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<int> _doImport(String content) async {
    final delimiter = _sniffDelimiter(content);
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(content, fieldDelimiter: delimiter);

    if (rows.isEmpty) throw StateError('Empty CSV');

    final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final frontIdx = _findIndex(header, ['front', 'question', 'السؤال']);
    final backIdx = _findIndex(header, ['back', 'answer', 'الإجابة', 'الاجابة']);
    final deckIdx = _findIndex(header, ['deck', 'group', 'المجموعة']);

    if (frontIdx < 0 || backIdx < 0) {
      throw StateError('CSV must have front/back or السؤال/الإجابة headers');
    }

    final deckCache = <String, int>{};
    int count = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= frontIdx || row.length <= backIdx) continue;
      final front = row[frontIdx].toString().trim();
      final back = row[backIdx].toString().trim();
      if (front.isEmpty || back.isEmpty) continue;

      final deckName = deckIdx >= 0 && row.length > deckIdx
          ? row[deckIdx].toString().trim()
          : _defaultDeck.trim();

      final resolvedDeckName =
          deckName.isEmpty ? _defaultDeck.trim() : deckName;

      int deckId;
      if (deckCache.containsKey(resolvedDeckName)) {
        deckId = deckCache[resolvedDeckName]!;
      } else {
        final existing =
            (await _decks.list()).where((d) => d.name == resolvedDeckName);
        deckId = existing.isNotEmpty
            ? existing.first.id
            : (await _decks.create(name: resolvedDeckName)).id;
        deckCache[resolvedDeckName] = deckId;
      }

      final fields = await _fields.forDeck(deckId);
      FieldDef? frontField;
      FieldDef? backField;
      for (final f in fields) {
        if (frontField == null &&
            (f.side == FieldSide.front || f.side == FieldSide.both)) {
          frontField = f;
        }
        if (backField == null &&
            (f.side == FieldSide.back || f.side == FieldSide.both)) {
          backField = f;
        }
      }

      final values = <int, String>{};
      if (frontField != null) values[frontField.id] = front;
      if (backField != null) values[backField.id] = back;

      await _cards.createWithValues(deckId: deckId, values: values);
      count++;
    }

    if (count == 0) throw StateError('No rows imported');
    return count;
  }

  int _findIndex(List<String> header, List<String> names) {
    for (var i = 0; i < header.length; i++) {
      if (names.contains(header[i])) return i;
    }
    return -1;
  }

  String _sniffDelimiter(String content) {
    final sample = content.length > 4096 ? content.substring(0, 4096) : content;
    if (sample.contains(';')) return ';';
    if (sample.contains('\t')) return '\t';
    return ',';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.importCsvTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.importHint,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _file?.path.split(Platform.pathSeparator).last ?? '—',
                    style: const TextStyle(color: AppColors.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _pick,
                  child: Text(s.chooseCsv),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: _defaultDeck),
            decoration: InputDecoration(labelText: s.importDefaultDeck),
            onChanged: (v) => _defaultDeck = v,
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.fail)),
            ),
          if (_imported > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${s.imported}: $_imported',
                style: const TextStyle(color: AppColors.good),
              ),
            ),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _busy || _file == null ? null : _import,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(s.importButton),
            ),
          ),
        ],
      ),
    );
  }
}