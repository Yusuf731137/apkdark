enum Rating { fail, hard, good, easy }

extension RatingLabel on Rating {
  String get dbValue {
    switch (this) {
      case Rating.fail: return 'FAIL';
      case Rating.hard: return 'HARD';
      case Rating.good: return 'GOOD';
      case Rating.easy: return 'EASY';
    }
  }

  static Rating fromDb(String s) {
    switch (s.toUpperCase()) {
      case 'FAIL': return Rating.fail;
      case 'HARD': return Rating.hard;
      case 'GOOD': return Rating.good;
      case 'EASY': return Rating.easy;
      default: return Rating.good;
    }
  }
}