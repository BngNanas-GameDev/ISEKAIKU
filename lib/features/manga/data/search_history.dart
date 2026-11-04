import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/storage/storage_service.dart';

/// Riwayat kata kunci pencarian (maksimum [maxItems]).
class SearchHistory {
  SearchHistory(this._storage) {
    _items = _load();
  }

  final StorageService _storage;
  late List<String> _items;

  static const String key = 'search.history';
  static const int maxItems = 10;

  List<String> get items => List<String>.unmodifiable(_items);

  List<String> _load() {
    final raw = _storage.getStringList(key);
    return raw.where((e) => e.trim().isNotEmpty).take(maxItems).toList();
  }

  /// Tambah ke urutan teratas, tanpa duplikat (tidak peka huruf besar/kecil).
  Future<void> add(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final next = <String>[
      value,
      ..._items.where((e) => e.toLowerCase() != value.toLowerCase()),
    ].take(maxItems).toList();

    _items = next;
    await _storage.setStringList(key, next);
  }

  Future<void> remove(String query) async {
    _items = _items.where((e) => e != query).toList();
    await _storage.setStringList(key, _items);
  }

  Future<void> clear() async {
    _items = const <String>[];
    await _storage.setStringList(key, const <String>[]);
  }
}

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier(this._history) : super(_history.items);

  final SearchHistory _history;

  Future<void> add(String query) async {
    await _history.add(query);
    state = _history.items;
  }

  Future<void> remove(String query) async {
    await _history.remove(query);
    state = _history.items;
  }

  Future<void> clear() async {
    await _history.clear();
    state = const <String>[];
  }
}

final searchHistoryServiceProvider = Provider<SearchHistory>(
  (ref) => SearchHistory(ref.watch(storageServiceProvider)),
);

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>(
  (ref) => SearchHistoryNotifier(ref.watch(searchHistoryServiceProvider)),
);
