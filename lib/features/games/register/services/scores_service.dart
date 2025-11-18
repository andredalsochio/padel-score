import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScoresService {
  final SupabaseClient client;
  ScoresService(this.client);

  PostgrestQueryBuilder _table() => client.from('score_sets');

  Future<List<Map<String, dynamic>>> listByGame(String gameId) async {
    final res = await _table()
        .select('*')
        .eq('game_id', gameId)
        .order('set_index');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> upsert(
    String gameId,
    int setIndex,
    int team1,
    int team2, {
    int? winnerTeam,
  }) async {
    debugPrint(
      "[RegisterSave] score_sets.upsert gameId=$gameId setIndex=$setIndex team1=$team1 team2=$team2 winnerTeam=$winnerTeam",
    );
    final payload = {
      'game_id': gameId,
      'set_index': setIndex,
      'team1_games': team1,
      'team2_games': team2,
      if (winnerTeam != null) 'winner_team': winnerTeam,
    };
    final res = await _table()
        .upsert(payload)
        .select('game_id,set_index,team1_games,team2_games,winner_team');
    debugPrint("[RegisterSave] score_sets.upsert response: $res");
  }

  Future<void> removeSet(String gameId, int setIndex) async {
    await _table().delete().eq('game_id', gameId).eq('set_index', setIndex);
  }
}
