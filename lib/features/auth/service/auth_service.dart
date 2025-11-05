import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this.client);

  final SupabaseClient client;

  // Define redirect para provedores OAuth.
  // Web: usa a origem atual. Mobile: esquema padrão do supabase_flutter.
  String? get _redirectUrl {
    if (kIsWeb) return Uri.base.origin;
    return 'io.supabase.flutter://login-callback/';
  }

  Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectUrl,
    );
  }

  Future<void> signInWithApple() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: _redirectUrl,
    );
  }

  Future<void> signInWithFacebook() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: _redirectUrl,
    );
  }

  Future<void> signInWithPassword({required String email, required String password}) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    // Opcional: redireciono verificação de e‑mail para a origem atual no Web
    final redirect = _redirectUrl;
    await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: redirect,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }
}