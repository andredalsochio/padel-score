import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/viewmodel/auth_view_model.dart';
import '../../features/home/view/home_screen.dart';

GoRouter createAppRouter(AuthViewModel authVm) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authVm, // Reavalia redirects quando o estado muda
    redirect: (context, state) {
      final loggedIn = authVm.isAuthenticated;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn) {
        return loggingIn ? null : '/login';
      }
      // Já autenticado
      if (loggingIn) return '/home';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const MaterialPage<void>(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => const MaterialPage<void>(
          child: HomeScreen(),
        ),
      ),
    ],
  );
}