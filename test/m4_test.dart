import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/features/manga/data/search_history.dart';
import 'package:isekaiku/features/manga/manga_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SearchHistory', () {
    Future<SearchHistory> build() async =>
        SearchHistory(await StorageService.create());

    test('query terbaru di atas dan duplikat dipindah, bukan digandakan', () async {
      final history = await build();

      await history.add('frieren');
      await history.add('chainsaw');
      await history.add('Frieren');

      expect(history.items, <String>['Frieren', 'chainsaw']);
    });

    test('dibatasi maxItems', () async {
      final history = await build();

      for (var i = 0; i < SearchHistory.maxItems + 5; i++) {
        await history.add('judul $i');
      }

      expect(history.items, hasLength(SearchHistory.maxItems));
      expect(history.items.first, 'judul ${SearchHistory.maxItems + 4}');
    });

    test('query kosong diabaikan', () async {
      final history = await build();
      await history.add('   ');
      expect(history.items, isEmpty);
    });

    test('remove dan clear', () async {
      final history = await build();
      await history.add('a');
      await history.add('b');

      await history.remove('a');
      expect(history.items, <String>['b']);

      await history.clear();
      expect(history.items, isEmpty);
    });

    test('tersimpan dan terbaca lagi oleh instance baru', () async {
      final storage = await StorageService.create();
      await SearchHistory(storage).add('tersimpan');

      expect(SearchHistory(storage).items, <String>['tersimpan']);
    });
  });

  group('BrowseFilter', () {
    test('toggleTag menambah lalu menghapus', () {
      final notifier = BrowseFilterNotifier();

      notifier.toggleTag('t1');
      expect(notifier.state.tagIds, <String>{'t1'});

      notifier.toggleTag('t1');
      expect(notifier.state.tagIds, isEmpty);
    });

    test('setStatus dan setYear bisa dikosongkan', () {
      final notifier = BrowseFilterNotifier();

      notifier.setStatus('completed');
      notifier.setYear(2020);
      expect(notifier.state.status, 'completed');
      expect(notifier.state.year, 2020);

      notifier.setStatus(null);
      notifier.setYear(null);
      expect(notifier.state.status, isNull);
      expect(notifier.state.year, isNull);
    });

    test('reset mengembalikan ke kondisi awal', () {
      final notifier = BrowseFilterNotifier();
      notifier.toggleTag('t1');
      notifier.setStatus('ongoing');
      notifier.setOrder(BrowseOrder.rating);

      notifier.reset();

      expect(notifier.state, const BrowseFilter());
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.order, BrowseOrder.popular);
    });

    test('dua filter dengan isi sama dianggap setara', () {
      const a = BrowseFilter(
        tagIds: <String>{'x', 'y'},
        status: 'ongoing',
        year: 2024,
      );
      const b = BrowseFilter(
        tagIds: <String>{'y', 'x'},
        status: 'ongoing',
        year: 2024,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('urutan berbeda membuat filter tidak setara', () {
      const a = BrowseFilter(order: BrowseOrder.popular);
      const b = BrowseFilter(order: BrowseOrder.rating);

      expect(a == b, isFalse);
    });
  });
}
