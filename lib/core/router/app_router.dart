import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/viewmodel/auth_view_model.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/games/register/view/register_game_screen.dart';
import '../../features/players/presentation/player_list_screen.dart';
import '../../features/players/presentation/player_form_screen.dart';
import '../../features/players/viewmodel/player_viewmodel.dart';
import '../../features/patotas/view/patotas_management_screen.dart';

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
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: LoginScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: HomeScreen()),
      ),
      GoRoute(
        path: '/games/register',
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: RegisterGameScreen()),
      ),
      GoRoute(
        path: '/players',
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: PlayerListScreen()),
      ),
      GoRoute(
        path: '/players/new',
        pageBuilder: (context, state) => MaterialPage<void>(
          child: ChangeNotifierProvider(
            create: (_) => PlayerViewModel(Supabase.instance.client),
            child: const PlayerFormScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/patotas',
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: PatotasManagementScreen()),
      ),
    ],
  );
}
