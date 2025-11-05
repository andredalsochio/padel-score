import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'features/auth/viewmodel/auth_view_model.dart';
import 'core/config/app_config.dart';

// Permite override via --dart-define, mas fonte primária é asset AppConfig.
const String _supabaseUrlEnv = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKeyEnv = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carrega configuração primária do asset e permite override por dart-defines.
  await AppConfig.load();
  var supabaseUrl = AppConfig.instance.supabaseUrl;
  var supabaseAnonKey = AppConfig.instance.supabaseAnonKey;
  if (_supabaseUrlEnv.isNotEmpty) supabaseUrl = _supabaseUrlEnv;
  if (_supabaseAnonKeyEnv.isNotEmpty) supabaseAnonKey = _supabaseAnonKeyEnv;

  // Validação defensiva: evitar inicialização com URL vazia ou inválida
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    // Fornece dica clara no console para configuração incorreta
    // e aborta para evitar chamadas com host ausente ("/auth/v1/...").
    // Use --dart-define-from-file=dart_defines.<env>.json com SUPABASE_URL e SUPABASE_ANON_KEY.
    throw StateError(
      'Supabase não configurado: defina SUPABASE_URL e SUPABASE_ANON_KEY via dart-defines.',
    );
  }

  // Valida se a URL tem host e esquema
  final parsed = Uri.tryParse(supabaseUrl);
  if (parsed == null || parsed.host.isEmpty || parsed.scheme.isEmpty) {
    throw StateError(
      'SUPABASE_URL inválida: "$supabaseUrl". Esperado algo como "https://<ref>.supabase.co".',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(Supabase.instance.client),
        ),
      ],
      child: Builder(
        builder: (context) {
          final authVm = context.watch<AuthViewModel>();
          final router = createAppRouter(authVm);
          return MaterialApp.router(
            title: 'Padel App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}

