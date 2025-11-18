import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/set_assignment.dart';

class ScoreSetPlayersService {
  final SupabaseClient client;
  ScoreSetPlayersService(this.client);

  PostgrestQueryBuilder _table() => client.from('score_set_players');

  /// Lista atribuições de jogadores para um set específico de um jogo.
  Future<List<SetPlayerEntry>> listBySet(String gameId, int setIndex) async {
    debugPrint(
      "[RegisterSave] score_set_players.listBySet gameId=$gameId setIndex=$setIndex",
    );
    final res = await _table()
        .select('game_id,set_index,player_id,team')
        .eq('game_id', gameId)
        .eq('set_index', setIndex)
        .order('player_id');
    debugPrint("[RegisterSave] score_set_players.listBySet response: $res");
    return List<Map<String, dynamic>>.from(
      res,
    ).map(SetPlayerEntry.fromMap).toList();
  }

  /// Upsert a player's team for a given set. Pass null to mark as resting.
  Future<void> upsert(
    String gameId,
    int setIndex,
    String playerId, {
    int? team,
  }) async {
    debugPrint(
      "[RegisterSave] score_set_players.upsert gameId=$gameId setIndex=$setIndex playerId=$playerId team=$team",
    );
    final payload = {
      'game_id': gameId,
      'set_index': setIndex,
      'player_id': playerId,
      'team': team,
    };
    final res = await _table()
        .upsert(payload)
        .select('game_id,set_index,player_id,team');
    debugPrint("[RegisterSave] score_set_players.upsert response: $res");
  }

  Future<void> remove(String gameId, int setIndex, String playerId) async {
    debugPrint(
      "[RegisterSave] score_set_players.remove gameId=$gameId setIndex=$setIndex playerId=$playerId",
    );
    final res = await _table()
        .delete()
        .eq('game_id', gameId)
        .eq('set_index', setIndex)
        .eq('player_id', playerId);
    debugPrint("[RegisterSave] score_set_players.remove response: $res");
  }
}
