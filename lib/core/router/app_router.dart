import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/anime/anime_screen.dart';
import '../../features/company/company_screen.dart';
import '../../features/details/details_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/movies/movies_screen.dart';
import '../../features/new_popular/new_popular_screen.dart';
import '../../features/person/person_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/series/series_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/watch/watch_screen.dart';
import '../../shared/widgets/app_scaffold.dart' show AppScaffold;
import '../constants/app_constants.dart';

/// Root navigator key — used so the bottom nav bar persists across tabs.
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Builds the app's [GoRouter] with a shell route that hosts the
/// bottom navigation bar. Watch + Details + Person + Company open as
/// full-screen routes above the shell.
GoRouter buildAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // Splash is a top-level route so it can take over the whole screen.
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // Tabs hosted inside the shell (bottom nav visible).
      ShellRoute(
        builder: (context, state, child) => _Shell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: AppRoute.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/movies',
            name: AppRoute.movies,
            builder: (_, __) => const MoviesScreen(),
          ),
          GoRoute(
            path: '/series',
            name: AppRoute.series,
            builder: (_, __) => const SeriesScreen(),
          ),
          GoRoute(
            path: '/anime',
            name: AppRoute.anime,
            builder: (_, __) => const AnimeScreen(),
          ),
          GoRoute(
            path: '/new-popular',
            name: AppRoute.newPopular,
            builder: (_, __) => const NewPopularScreen(),
          ),
          GoRoute(
            path: '/search',
            name: AppRoute.search,
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: AppRoute.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav).
      GoRoute(
        path: '/details/:type/:id',
        name: AppRoute.details,
        builder: (_, state) => DetailsScreen(
          type: state.pathParameters['type']!,
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/watch/:type/:id',
        name: AppRoute.watch,
        builder: (_, state) => WatchScreen(
          type: state.pathParameters['type']!,
          id: int.parse(state.pathParameters['id']!),
          season: int.tryParse(state.uri.queryParameters['s'] ?? '') ?? 1,
          episode: int.tryParse(state.uri.queryParameters['e'] ?? '') ?? 1,
        ),
      ),
      GoRoute(
        path: '/person/:id',
        name: AppRoute.person,
        builder: (_, state) =>
            PersonScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/company/:id',
        name: AppRoute.company,
        builder: (_, state) =>
            CompanyScreen(id: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
}

/// Route names used throughout the app for type-safe navigation.
class AppRoute {
  AppRoute._();
  static const home = 'home';
  static const movies = 'movies';
  static const series = 'series';
  static const anime = 'anime';
  static const newPopular = 'newPopular';
  static const search = 'search';
  static const profile = 'profile';
  static const details = 'details';
  static const watch = 'watch';
  static const person = 'person';
  static const company = 'company';
}

/// The shell that wraps every tabbed page and renders the bottom nav.
class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(child: child);
  }
}
