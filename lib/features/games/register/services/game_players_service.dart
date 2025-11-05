import 'package:supabase_flutter/supabase_flutter.dart';

class GamePlayersService {
  final SupabaseClient client;
  GamePlayersService(this.client);

  PostgrestQueryBuilder _table() => client.from('game_players');

  Future<List<Map<String, dynamic>>> listByGame(String gameId) async {
    final res = await _table().select('*').eq('game_id', gameId).order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> upsert(String gameId, String playerId, {int? team}) async {
    await _table().upsert({
      'game_id': gameId,
      'player_id': playerId,
      if (team != null) 'team': team,
    });
  }

  Future<void> remove(String gameId, String playerId) async {
    await _table().delete().eq('game_id', gameId).eq('player_id', playerId);
  }
}