import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:midad/domain/card.dart';
import 'package:midad/domain/rating.dart';
import 'package:midad/services/scheduler_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Card makeCard({int state = 1, int reps = 0}) => Card(
        id: 1,
        deckId: 1,
        front: 'q',
        back: 'a',
        state: state,
        step: 0,
        stability: null,
        difficulty: null,
        due: DateTime.now().toUtc(),
        lastReview: null,
        reps: reps,
        lapses: 0,
        learningSteps: 0,
        createdAt: DateTime.now().toUtc(),
        modifiedAt: DateTime.now().toUtc(),
        suspended: false,
      );

  test('review GOOD increments reps', () {
    final s = SchedulerService();
    final values = s.review(makeCard(), Rating.good);
    expect(values['reps'], 1);
    expect(values['due'], isA<DateTime>());
  });

  test('review FAIL increments lapses only when Review', () {
    final s = SchedulerService();
    final learning = s.review(makeCard(state: 1), Rating.fail);
    expect(learning['lapses'], 0);

    final reviewing = s.review(makeCard(state: 2, reps: 3), Rating.fail);
    expect(reviewing['lapses'], 1);
  });

  test('preview intervals returns all 4 ratings', () {
    final s = SchedulerService();
    final previews = s.previewIntervals(makeCard());
    expect(previews.keys.toSet(), Rating.values.toSet());
    for (final v in previews.values) {
      expect(v, isNotEmpty);
    }
  });
}