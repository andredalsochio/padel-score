import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GamesService {
  final SupabaseClient client;
  GamesService(this.client);

  PostgrestQueryBuilder _table() => client.from('games');

  Future<String> createDraft({int bestOf = 3, String? notes}) async {
    debugPrint(
      "[RegisterSave] games.createDraft bestOf=$bestOf notes=${notes ?? ''}",
    );
    final res = await _table()
        .insert({
          'status': 'draft',
          'best_of': bestOf,
          if (notes != null) 'notes': notes,
          'created_by': client.auth.currentUser!.id,
        })
        .select('id')
        .single();
    debugPrint("[RegisterSave] games.createDraft response: $res");
    return res['id'] as String;
  }

  Future<void> updateStatus(String gameId, String status) async {
    debugPrint(
      "[RegisterSave] games.updateStatus gameId=$gameId status=$status",
    );
    final res = await _table().update({'status': status}).eq('id', gameId);
    debugPrint("[RegisterSave] games.updateStatus response: $res");
  }

  Future<void> deleteGame(String gameId) async {
    debugPrint("[RegisterSave] games.deleteGame gameId=$gameId");
    final res = await _table().delete().eq('id', gameId);
    debugPrint("[RegisterSave] games.deleteGame response: $res");
  }
}
