import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;

  const AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  factory AppConfig.fromMap(Map<String, dynamic> m) => AppConfig(
    supabaseUrl: (m['supabaseUrl'] as String?)?.trim() ?? '',
    supabaseAnonKey: (m['supabaseAnonKey'] as String?)?.trim() ?? '',
  );

  static AppConfig? _instance;

  static AppConfig get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
        'AppConfig not loaded. Call AppConfig.load() before use.',
      );
    }
    return inst;
  }

  static Future<void> load() async {
    // Load from asset file
    final raw = await rootBundle.loadString('assets/config/app_config.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    var config = AppConfig.fromMap(map);

    // Allow dart-defines to override if provided
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    final url = envUrl.trim().isNotEmpty ? envUrl.trim() : config.supabaseUrl;
    final key = envKey.trim().isNotEmpty
        ? envKey.trim()
        : config.supabaseAnonKey;

    _instance = AppConfig(supabaseUrl: url, supabaseAnonKey: key);
  }
}
