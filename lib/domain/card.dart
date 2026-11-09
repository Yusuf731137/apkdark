class Card {
  final int id;
  final int deckId;
  final String front;
  final String back;
  final int state;
  final int step;
  final double? stability;
  final double? difficulty;
  final DateTime due;
  final DateTime? lastReview;
  final int reps;
  final int lapses;
  final int learningSteps;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool suspended;

  const Card({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.state,
    required this.step,
    required this.stability,
    required this.difficulty,
    required this.due,
    required this.lastReview,
    required this.reps,
    required this.lapses,
    required this.learningSteps,
    required this.createdAt,
    required this.modifiedAt,
    required this.suspended,
  });

  bool get isNew => reps == 0;
  bool get isLearning => state == 1 || state == 3;
  bool get isReview => state == 2 && reps > 0;

  factory Card.fromMap(Map<String, dynamic> m) => Card(
        id: m['id'] as int,
        deckId: m['deck_id'] as int,
        front: m['front'] as String,
        back: m['back'] as String,
        state: (m['state'] as int?) ?? 1,
        step: (m['step'] as int?) ?? 0,
        stability: (m['stability'] as num?)?.toDouble(),
        difficulty: (m['difficulty'] as num?)?.toDouble(),
        due: DateTime.parse(m['due'] as String).toLocal(),
        lastReview: m['last_review'] != null
            ? DateTime.parse(m['last_review'] as String).toLocal()
            : null,
        reps: (m['reps'] as int?) ?? 0,
        lapses: (m['lapses'] as int?) ?? 0,
        learningSteps: (m['learning_steps'] as int?) ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        modifiedAt: DateTime.parse(
          (m['modified_at'] as String?) ?? (m['created_at'] as String),
        ).toLocal(),
        suspended: ((m['suspended'] as int?) ?? 0) == 1,
      );

  /// Grade used for the deck dashboard chart.
  /// NEW: reps == 0
  /// F: state in (Learning, Relearning) OR stability < 0.5
  /// E: 0.5 <= stability < 1
  /// D: 1 <= stability < 3
  /// C: 3 <= stability < 7
  /// B: 7 <= stability < 21
  /// A: stability >= 21
  String get grade {
    if (reps == 0) return 'NEW';
    if (state == 1 || state == 3 || (lapses > 0 && (stability ?? 0) < 0.5)) {
      return 'F';
    }
    final s = stability ?? 0;
    if (s < 1) return 'E';
    if (s < 3) return 'D';
    if (s < 7) return 'C';
    if (s < 21) return 'B';
    return 'A';
  }
}