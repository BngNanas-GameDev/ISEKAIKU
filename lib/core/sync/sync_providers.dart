import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/library_providers.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import 'remote_library.dart';

enum SyncPhase { idle, syncing, done, error }

class SyncState {
  const SyncState({
    required this.phase,
    this.message,
    this.at,
  });

  const SyncState.idle() : this(phase: SyncPhase.idle);

  final SyncPhase phase;
  final String? message;
  final DateTime? at;

  bool get isSyncing => phase == SyncPhase.syncing;
}

/// Menjalankan sinkronisasi Pustaka dengan Supabase.
///
/// Aman dipanggil walau belum login atau backend belum dikonfigurasi:
/// keduanya hanya menghasilkan status, bukan crash.
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref) : super(const SyncState.idle());

  final Ref _ref;

  Future<void> syncNow() async {
    if (state.isSyncing) return;

    if (!AppConfig.hasSupabase) {
      state = const SyncState(
        phase: SyncPhase.error,
        message: 'Backend belum dikonfigurasi.',
      );
      return;
    }

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = const SyncState(
        phase: SyncPhase.error,
        message: 'Masuk ke akun terlebih dahulu.',
      );
      return;
    }

    state = const SyncState(phase: SyncPhase.syncing);
    try {
      final remote = RemoteLibrary(
        _ref.read(supabaseClientProvider),
        _ref.read(libraryStoreProvider),
      );
      await remote.sync(user.id);

      // Segarkan state di memori dari hasil penggabungan.
      _ref.read(followedMangaProvider.notifier).reload();
      _ref.read(readingHistoryProvider.notifier).reload();
      _ref.read(readChaptersProvider.notifier).reload();

      state = SyncState(phase: SyncPhase.done, at: DateTime.now());
    } catch (error) {
      state = SyncState(
        phase: SyncPhase.error,
        message: _message(error),
      );
    }
  }

  String _message(Object error) {
    final text = error.toString();
    return text.length > 200 ? '${text.substring(0, 200)}…' : text;
  }
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) => SyncNotifier(ref));
