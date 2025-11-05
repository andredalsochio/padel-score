import 'package:supabase_flutter/supabase_flutter.dart';

class ScoresService {
  final SupabaseClient client;
  ScoresService(this.client);

  PostgrestQueryBuilder _table() => client.from('score_sets');

  Future<List<Map<String, dynamic>>> listByGame(String gameId) async {
    final res = await _table().select('*').eq('game_id', gameId).order('set_index');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> upsert(String gameId, int setIndex, int team1, int team2, {int? winnerTeam}) async {
    await _table().upsert({
      'game_id': gameId,
      'set_index': setIndex,
      'team1_games': team1,
      'team2_games': team2,
      if (winnerTeam != null) 'winner_team': winnerTeam,
    });
  }

  Future<void> removeSet(String gameId, int setIndex) async {
    await _table().delete().eq('game_id', gameId).eq('set_index', setIndex);
  }
}