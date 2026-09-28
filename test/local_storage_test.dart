import 'package:fawateery/core/storage/app_settings.dart';
import 'package:fawateery/core/storage/solved_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    AppSettings.debugReset();
    SolvedStore.debugReset();
    SharedPreferences.setMockInitialValues({});

    // Boot them exactly like main() does.
    await AppSettings.init();
    await SolvedStore.init();
  });

  group('AppSettings', () {
    test('ships empty: every student brings their own key', () {
      expect(AppSettings.instance.hasGroqApiKey, isFalse);
      expect(AppSettings.instance.groqApiKey, isEmpty);
      expect(AppSettings.instance.groqModel, AppSettings.defaultGroqModel);
      expect(AppSettings.instance.hasCodeforcesHandle, isFalse);
    });

    test('stores the key, model and handle on the device', () async {
      final settings = AppSettings.instance;
      await settings.setGroqApiKey('  gsk_abc123  ');
      await settings.setGroqModel('llama-3.3-70b-versatile');
      await settings.setCodeforcesHandle('  Karam  ');

      expect(settings.groqApiKey, 'gsk_abc123');
      expect(settings.hasGroqApiKey, isTrue);
      expect(settings.groqModel, 'llama-3.3-70b-versatile');
      expect(settings.codeforcesHandle, 'Karam');

      // Still there after a restart.
      AppSettings.debugReset();
      await AppSettings.init();

      expect(AppSettings.instance.groqApiKey, 'gsk_abc123');
      expect(AppSettings.instance.groqModel, 'llama-3.3-70b-versatile');
      expect(AppSettings.instance.codeforcesHandle, 'Karam');
    });

    test('falls back to an empty key when the student clears it', () async {
      await AppSettings.instance.setGroqApiKey('gsk_temp');
      await AppSettings.instance.setGroqApiKey('');

      expect(AppSettings.instance.hasGroqApiKey, isFalse);
      expect(AppSettings.instance.groqModel, AppSettings.defaultGroqModel);
    });

    test('works in memory before the store is bootstrapped', () {
      AppSettings.debugReset();

      // Widget tests (and early startup) hit this path.
      AppSettings.instance.setGroqApiKey('gsk_memory');
      AppSettings.instance.setCodeforcesHandle('Late');

      expect(AppSettings.instance.groqApiKey, 'gsk_memory');
      expect(AppSettings.instance.codeforcesHandle, 'Late');
    });
  });

  group('SolvedStore', () {
    test('marks, counts and unmarks problems', () async {
      final store = SolvedStore.instance;
      expect(store.count, 0);
      expect(store.isSolved('1850C'), isFalse);

      await store.mark(id: '1850C', name: 'Roman and Numbers', rating: 1800);
      await store.mark(
        id: '1A',
        name: 'Theatre Square',
        rating: 1000,
        tags: ['math'],
      );

      expect(store.count, 2);
      expect(store.isSolved('1850C'), isTrue);
      expect(store.find('1A')!.tags, ['math']);

      // Marking twice must not double-count.
      await store.mark(id: '1850C', name: 'Roman and Numbers', rating: 1800);
      expect(store.count, 2);

      await store.unmark('1850C');
      expect(store.count, 1);
      expect(store.isSolved('1850C'), isFalse);
    });

    test('groups the count by difficulty band', () async {
      final store = SolvedStore.instance;
      await store.mark(id: '1A', name: 'easy', rating: 900);
      await store.mark(id: '2A', name: 'also easy', rating: 1100);
      await store.mark(id: '3A', name: 'medium', rating: 1500);
      await store.mark(id: '4A', name: 'hard', rating: 2100);
      await store.mark(id: '5A', name: 'unrated', rating: null);

      final counts = store.countByRating();
      expect(counts['Beginner'], 3); // two rated + the unrated one
      expect(counts['Easy'], 0);
      expect(counts['Medium'], 1);
      expect(counts['Hard'], 1);
      expect(ratingBandOf(1500).label, 'Medium');
      expect(ratingBandOf(null).label, 'Beginner');
    });

    test('survives a restart and notifies listeners on every change', () async {
      final store = SolvedStore.instance;
      final revisionBefore = store.revision.value;

      await store.mark(id: '1A', name: 'Theatre Square', rating: 1000);
      expect(store.revision.value, revisionBefore + 1);

      SolvedStore.debugReset();
      await SolvedStore.init();

      expect(SolvedStore.instance.count, 1);
      expect(SolvedStore.instance.isSolved('1A'), isTrue);
    });

    test('clears everything', () async {
      await SolvedStore.instance.mark(id: '1A', name: 'Theatre Square');
      await SolvedStore.instance.clear();

      expect(SolvedStore.instance.count, 0);
    });
  });
}
