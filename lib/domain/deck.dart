class Deck {
  final int id;
  final String name;
  final String description;
  final int? folderId;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.folderId,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory Deck.fromMap(Map<String, dynamic> m) => Deck(
        id: m['id'] as int,
        name: m['name'] as String,
        description: (m['description'] as String?) ?? '',
        folderId: m['folder_id'] as int?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        modifiedAt: DateTime.parse(
          (m['modified_at'] as String?) ?? (m['created_at'] as String),
        ).toLocal(),
      );
}