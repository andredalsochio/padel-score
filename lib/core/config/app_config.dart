import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;

  const AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  static AppConfig? _instance;

  static AppConfig get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError('AppConfig not loaded. Call AppConfig.load() before use.');
    }
    return inst;
  }

  static Future<void> load() async {
    // Load from asset file
    final raw = await rootBundle.loadString('assets/config/app_config.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    var url = (map['supabaseUrl'] as String?)?.trim() ?? '';
    var key = (map['supabaseAnonKey'] as String?)?.trim() ?? '';

    // Allow dart-defines to override if provided
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envUrl.trim().isNotEmpty) url = envUrl.trim();
    if (envKey.trim().isNotEmpty) key = envKey.trim();

    _instance = AppConfig(supabaseUrl: url, supabaseAnonKey: key);
  }
}