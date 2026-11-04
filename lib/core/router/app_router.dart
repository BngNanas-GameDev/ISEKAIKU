import 'package:go_router/go_router.dart';

import '../../core/widgets/iseakaiku_wordmark.dart';
import '../../features/account/presentation/account_page.dart';
import '../../features/donate/presentation/donate_page.dart';
import '../../features/forum/presentation/forum_compose_page.dart';
import '../../features/forum/presentation/forum_page.dart';
import '../../features/forum/presentation/forum_thread_page.dart';
import '../../features/legal/presentation/legal_pages.dart';
import '../../features/library/presentation/library_page.dart';
import '../../features/manga/presentation/browse_page.dart';
import '../../features/manga/presentation/home_page.dart';
import '../../features/manga/presentation/manga_detail_page.dart';
import '../../features/manga/presentation/reader_page.dart';
import '../../features/manga/presentation/search_page.dart';
import 'shell_page.dart';

/// Rute aplikasi.
///
/// - `/` beranda (tab Beranda/Cari/Pustaka/Forum/Akun)
/// - `/manga/:id` detail manga
/// - `/manga/:id/read/:chapterId?title=&number=` reader
/// - `/forum` daftar topik, `/forum/new` tulis, `/forum/:threadId` detail
final appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/search',
          builder: (context, state) =>
              SearchPage(initialQuery: state.uri.queryParameters['q'] ?? ''),
        ),
        GoRoute(
          path: '/browse',
          builder: (context, state) => const BrowsePage(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryPage(),
        ),
        GoRoute(path: '/forum', builder: (context, state) => const ForumPage()),
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/forum/new',
      builder: (context, state) => const ForumComposePage(),
    ),
    GoRoute(
      path: '/forum/:threadId',
      builder: (context, state) =>
          ForumThreadPage(threadId: state.pathParameters['threadId']!),
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
        initialPage: int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 0,
      ),
    ),
    GoRoute(
      path: '/dev/design',
      builder: (context, state) => const IsekaikuDesignSystemPreview(),
    ),
    GoRoute(path: '/donate', builder: (context, state) => const DonatePage()),
    GoRoute(
      path: '/legal/terms',
      builder: (context, state) => const TermsPage(),
    ),
    GoRoute(
      path: '/legal/privacy',
      builder: (context, state) => const PrivacyPage(),
    ),
  ],
);
