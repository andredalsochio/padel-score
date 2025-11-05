import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(SupabaseClient client)
    : _client = client,
      _service = AuthService(client) {
    _init();
  }

  final SupabaseClient _client;
  final AuthService _service;

  bool _loading = false;
  String? _error;
  bool _authenticated = false;

  bool get isLoading => _loading;
  String? get errorMessage => _error;
  bool get isAuthenticated => _authenticated;

  Future<void> _init() async {
    // Estado inicial baseado na sessão atual
    _authenticated = _client.auth.currentSession != null;
    notifyListeners();

    // Observa mudanças de auth para redirecionos via go_router
    _client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      developer.log(
        'Auth event: $event, isAuthenticated: ${session != null}',
        name: 'padel_app.auth',
      );
      _authenticated = session != null;
      _error = null;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() => _signIn(_service.signInWithGoogle);
  Future<void> signInWithApple() => _signIn(_service.signInWithApple);
  Future<void> signInWithFacebook() => _signIn(_service.signInWithFacebook);

  Future<void> _signIn(Future<void> Function() action) async {
    _setLoading(true);
    try {
      await action();
      _error = null;
    } catch (e, s) {
      developer.log(
        'Erro ao autenticar',
        name: 'padel_app.auth',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _service.signOut();
      _error = null;
    } catch (e, s) {
      developer.log(
        'Erro ao sair',
        name: 'padel_app.auth',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithPassword(String email, String password) async {
    _setLoading(true);
    try {
      await _service.signInWithPassword(email: email, password: password);
      _error = null;
    } catch (e, s) {
      developer.log(
        'Erro ao autenticar com e‑mail/senha',
        name: 'padel_app.auth',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      await _service.signUp(email: email, password: password);
      _error = null;
    } catch (e, s) {
      developer.log(
        'Erro ao registrar usuário',
        name: 'padel_app.auth',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  String _formatError(Object e) {
    // Mensagem concisa para UI
    return e.toString();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
