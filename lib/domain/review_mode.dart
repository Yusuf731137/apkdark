enum ReviewMode {
  fsrs('FSRS'),
  random('RANDOM'),
  created('CREATED');

  final String value;
  const ReviewMode(this.value);

  static ReviewMode fromString(String s) {
    switch (s) {
      case 'RANDOM': return ReviewMode.random;
      case 'CREATED': return ReviewMode.created;
      default: return ReviewMode.fsrs;
    }
  }
}