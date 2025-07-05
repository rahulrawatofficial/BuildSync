import 'package:buildsync/core/routing/router_utils.dart';
import 'package:buildsync/features/auth/presentation/splash_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/home/presentation/home_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final location = state.uri.toString();
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = location == '/login';

      if (!isLoggedIn && location != '/login') return '/login';
      if (isLoggedIn && isLoggingIn) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    ],
  );
}
