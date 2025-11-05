import 'package:supabase_flutter/supabase_flutter.dart';

class GamesService {
  final SupabaseClient client;
  GamesService(this.client);

  PostgrestQueryBuilder _table() => client.from('games');

  Future<String> createDraft({int bestOf = 3, String? notes}) async {
    final res = await _table().insert({
      'status': 'draft',
      'best_of': bestOf,
      if (notes != null) 'notes': notes,
      'created_by': client.auth.currentUser!.id,
    }).select('id').single();
    return res['id'] as String;
  }

  Future<void> updateStatus(String gameId, String status) async {
    await _table().update({'status': status}).eq('id', gameId);
  }

  Future<void> deleteGame(String gameId) async {
    await _table().delete().eq('id', gameId);
  }
}