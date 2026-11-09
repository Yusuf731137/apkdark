import 'field_type.dart';

class FieldDef {
  final int id;
  final int deckId;
  final String name;
  final FieldType type;
  final FieldSide side;
  final String language;
  final int fontSize;
  final String? ttsProvider;
  final String? ttsVoice;
  final double ttsRate;
  final FieldSource source;
  final int sortOrder;

  const FieldDef({
    required this.id,
    required this.deckId,
    required this.name,
    required this.type,
    required this.side,
    required this.language,
    required this.fontSize,
    required this.ttsProvider,
    required this.ttsVoice,
    required this.ttsRate,
    required this.source,
    required this.sortOrder,
  });

  factory FieldDef.fromMap(Map<String, dynamic> m) => FieldDef(
        id: m['id'] as int,
        deckId: m['deck_id'] as int,
        name: m['name'] as String,
        type: FieldTypeValue.fromString(m['type'] as String),
        side: FieldSideValue.fromString(m['side'] as String),
        language: (m['language'] as String?) ?? '',
        fontSize: (m['font_size'] as int?) ?? 16,
        ttsProvider: m['tts_provider'] as String?,
        ttsVoice: m['tts_voice'] as String?,
        ttsRate: (m['tts_rate'] as num?)?.toDouble() ?? 1.0,
        source: FieldSourceValue.fromString(m['source'] as String),
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );

  Map<String, dynamic> toUpdateMap() => {
        'name': name,
        'type': type.value,
        'side': side.value,
        'language': language,
        'font_size': fontSize,
        'tts_provider': ttsProvider,
        'tts_voice': ttsVoice,
        'tts_rate': ttsRate,
        'source': source.value,
        'sort_order': sortOrder,
        'modified_at': DateTime.now().toUtc().toIso8601String(),
      };

  FieldDef copyWith({
    String? name,
    FieldType? type,
    FieldSide? side,
    String? language,
    int? fontSize,
    String? ttsProvider,
    String? ttsVoice,
    double? ttsRate,
    FieldSource? source,
    int? sortOrder,
  }) => FieldDef(
        id: id,
        deckId: deckId,
        name: name ?? this.name,
        type: type ?? this.type,
        side: side ?? this.side,
        language: language ?? this.language,
        fontSize: fontSize ?? this.fontSize,
        ttsProvider: ttsProvider ?? this.ttsProvider,
        ttsVoice: ttsVoice ?? this.ttsVoice,
        ttsRate: ttsRate ?? this.ttsRate,
        source: source ?? this.source,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}