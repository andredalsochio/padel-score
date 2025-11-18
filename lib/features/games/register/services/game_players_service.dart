import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GamePlayersService {
  final SupabaseClient client;
  GamePlayersService(this.client);

  PostgrestQueryBuilder _table() => client.from('game_players');

  Future<List<Map<String, dynamic>>> listByGame(String gameId) async {
    final res = await _table()
        .select('*')
        .eq('game_id', gameId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> upsert(String gameId, String playerId, {int? team}) async {
    debugPrint(
      "[RegisterSave] game_players.upsert gameId=$gameId playerId=$playerId team=$team",
    );
    final payload = {
      'game_id': gameId,
      'player_id': playerId,
      if (team != null) 'team': team,
    };
    final res = await _table().upsert(payload).select('game_id,player_id,team');
    debugPrint("[RegisterSave] game_players.upsert response: $res");
  }

  Future<void> remove(String gameId, String playerId) async {
    debugPrint(
      "[RegisterSave] game_players.remove gameId=$gameId playerId=$playerId",
    );
    final res = await _table()
        .delete()
        .eq('game_id', gameId)
        .eq('player_id', playerId);
    debugPrint("[RegisterSave] game_players.remove response: $res");
  }
}
