import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:midad/data/repositories/card_repository.dart';
import 'package:midad/data/repositories/deck_repository.dart';
import 'package:midad/data/repositories/field_repository.dart';
import 'package:midad/domain/field_type.dart';
import 'package:midad/domain/rating.dart';
import 'package:midad/domain/review_mode.dart';
import 'package:midad/services/review_engine.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('cram session does not modify card schedule', () async {
    final decks = DeckRepository();
    final cards = CardRepository();
    final fields = FieldRepository();
    final engine = ReviewEngine();

    final deck = await decks.create(name: 'Test ${DateTime.now().microsecondsSinceEpoch}');
    final fieldList = await fields.forDeck(deck.id);
    final cardId = await cards.createWithValues(
      deckId: deck.id,
      values: {
        fieldList.first.id: 'q1',
        fieldList.last.id: 'a1',
      },
    );

    final before = await cards.get(cardId);
    expect(before, isNotNull);

    final state = await engine.start(
      deckId: deck.id,
      mode: ReviewMode.fsrs,
      isCram: true,
    );
    expect(state.queue, contains(cardId));

    final card = await cards.get(cardId);
    await engine.rate(
      state: state,
      card: card!,
      rating: Rating.good,
      durationMs: 1000,
    );

    final after = await cards.get(cardId);
    expect(after!.reps, before!.reps);
    expect(after.due, before.due);
  });

  test('fsrs session updates card reps and due', () async {
    final decks = DeckRepository();
    final cards = CardRepository();
    final fields = FieldRepository();
    final engine = ReviewEngine();

    final deck = await decks.create(name: 'Test2 ${DateTime.now().microsecondsSinceEpoch}');
    final fieldList = await fields.forDeck(deck.id);
    final cardId = await cards.createWithValues(
      deckId: deck.id,
      values: {
        fieldList.first.id: 'q2',
        fieldList.last.id: 'a2',
      },
    );

    final before = await cards.get(cardId);
    final state = await engine.start(
      deckId: deck.id,
      mode: ReviewMode.fsrs,
      isCram: false,
    );

    final card = await cards.get(cardId);
    await engine.rate(
      state: state,
      card: card!,
      rating: Rating.good,
      durationMs: 500,
    );

    final after = await cards.get(cardId);
    expect(after!.reps, before!.reps + 1);
    expect(after.due.isAfter(before.due), isTrue);
  });
}