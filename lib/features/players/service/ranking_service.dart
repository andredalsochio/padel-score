import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

class RankingService {
  final SupabaseClient client;
  RankingService(this.client);

  Future<void> updateAfterMatch(String gameId, {int kFactor = 32}) async {
    final setRows = await client
        .from('score_sets')
        .select('winner_team,team1_games,team2_games')
        .eq('game_id', gameId);
    final sets = List<Map<String, dynamic>>.from(setRows);
    final winsA = sets.where((m) => m['winner_team'] == 1).length;
    final winsB = sets.where((m) => m['winner_team'] == 2).length;
    final winnerTeam = winsA >= winsB ? 1 : 2;

    final spRows = await client
        .from('score_set_players')
        .select('player_id,team')
        .eq('game_id', gameId);
    final sp = List<Map<String, dynamic>>.from(spRows);
    final teamA = sp.where((m) => m['team'] == 1).map((m) => m['player_id'] as String).toSet().toList();
    final teamB = sp.where((m) => m['team'] == 2).map((m) => m['player_id'] as String).toSet().toList();
    if (teamA.isEmpty || teamB.isEmpty) return;

    final aRank = await _getOrCreateRankings(teamA);
    final bRank = await _getOrCreateRankings(teamB);

    final avgA = aRank.values.fold<double>(0, (s, e) => s + e) / aRank.length;
    final avgB = bRank.values.fold<double>(0, (s, e) => s + e) / bRank.length;
    final eA = 1.0 / (1.0 + math.pow(10.0, (avgB - avgA) / 400.0));
    final eB = 1.0 - eA;
    final sA = winnerTeam == 1 ? 1.0 : 0.0;
    final sB = 1.0 - sA;

    for (final pid in teamA) {
      final elo = aRank[pid] ?? 1200.0;
      final newElo = (elo + kFactor * (sA - eA)).round();
      await _upsertRanking(pid, newElo, won: winnerTeam == 1);
    }
    for (final pid in teamB) {
      final elo = bRank[pid] ?? 1200.0;
      final newElo = (elo + kFactor * (sB - eB)).round();
      await _upsertRanking(pid, newElo, won: winnerTeam == 2);
    }
  }

  Future<Map<String, double>> _getOrCreateRankings(List<String> playerIds) async {
    if (playerIds.isEmpty) return {};
    final or = playerIds.map((id) => 'player_id.eq.$id').join(',');
    final rows = await client.from('ranking').select('player_id,elo').or(or);
    final maps = List<Map<String, dynamic>>.from(rows);
    final res = <String, double>{};
    for (final pid in playerIds) {
      final m = maps.firstWhere(
        (r) => r['player_id'] == pid,
        orElse: () => {},
      );
      if (m.isEmpty) {
        await client.from('ranking').insert({'player_id': pid, 'wins': 0, 'losses': 0, 'total_points': 0, 'elo': 1200});
        res[pid] = 1200.0;
      } else {
        res[pid] = (m['elo'] as num?)?.toDouble() ?? 1200.0;
      }
    }
    return res;
  }

  Future<void> _upsertRanking(String playerId, int elo, {required bool won}) async {
    final rows = await client.from('ranking').select('id,wins,losses,total_points').eq('player_id', playerId);
    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) {
      await client.from('ranking').insert({
        'player_id': playerId,
        'wins': won ? 1 : 0,
        'losses': won ? 0 : 1,
        'total_points': 0,
        'elo': elo,
      });
    } else {
      final m = list.first;
      final wins = (m['wins'] as int) + (won ? 1 : 0);
      final losses = (m['losses'] as int) + (won ? 0 : 1);
      await client.from('ranking').update({'wins': wins, 'losses': losses, 'elo': elo}).eq('player_id', playerId);
    }
  }
}