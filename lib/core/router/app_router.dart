import 'package:go_router/go_router.dart';

import '../../core/widgets/iseakaiku_wordmark.dart';
import '../../features/library/presentation/library_page.dart';
import '../../features/manga/presentation/home_page.dart';
import '../../features/manga/presentation/manga_detail_page.dart';
import '../../features/manga/presentation/reader_page.dart';
import '../../features/manga/presentation/search_page.dart';
import 'shell_page.dart';

/// Rute aplikasi.
///
/// - `/` beranda (tab Beranda/Cari/Pustaka)
/// - `/manga/:id` detail manga
/// - `/manga/:id/read/:chapterId?title=&number=` reader
final appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => SearchPage(
            initialQuery: state.uri.queryParameters['q'] ?? '',
          ),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/manga/:id',
      builder: (context, state) =>
          MangaDetailPage(mangaId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/manga/:id/read/:chapterId',
      builder: (context, state) => ReaderPage(
        mangaId: state.pathParameters['id']!,
        chapterId: state.pathParameters['chapterId']!,
        chapterTitle: state.uri.queryParameters['title'] ?? '',
        chapterNumber: state.uri.queryParameters['number'] ?? '',
        initialPage:
            int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 0,
      ),
    ),
    GoRoute(
      path: '/dev/design',
      builder: (context, state) => const IsekaikuDesignSystemPreview(),
    ),
  ],
);
