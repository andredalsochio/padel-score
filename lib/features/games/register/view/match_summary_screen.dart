import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import '../helpers/register_styles.dart';
import '../models/set_assignment.dart';
import '../widgets/summary_v2/hero_winner_banner.dart';
import '../widgets/summary_v2/sports_scoreboard.dart';
import '../widgets/summary_v2/sets_duo_list.dart';
import '../widgets/summary_v2/premium_actions_bar.dart';

class MatchSummaryScreen extends StatelessWidget {
  final String gameId;
  const MatchSummaryScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    debugPrint("[MatchSummary] Entering screen with gameId: $gameId");
    return Scaffold(
      appBar: AppBar(title: const Text('Resumo da Partida')),
      body: FutureBuilder<_SummaryData>(
        future: _loadSummary(Supabase.instance.client, gameId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final winnerTeam = data.winnerTeam;
          debugPrint("[MatchSummary] Loaded summary data");
          debugPrint(
            "[MatchSummary] Duo A players (${data.teamA.length}): ${data.teamA}",
          );
          debugPrint(
            "[MatchSummary] Duo B players (${data.teamB.length}): ${data.teamB}",
          );
          final duoACombined = _duoName(data.teamA);
          final duoBCombined = _duoName(data.teamB);
          debugPrint(
            "[MatchSummary] Building Duo A combined name = '$duoACombined'",
          );
          debugPrint(
            "[MatchSummary] Building Duo B combined name = '$duoBCombined'",
          );
          debugPrint("[MatchSummary] Winner calculation started");
          int setsWonByDuoA = 0;
          int setsWonByDuoB = 0;
          for (final e in data.sets.entries) {
            if (e.value.team1 > e.value.team2) setsWonByDuoA++;
            if (e.value.team2 > e.value.team1) setsWonByDuoB++;
          }
          debugPrint(
            "[MatchSummary] setsWonByDuoA=$setsWonByDuoA, setsWonByDuoB=$setsWonByDuoB",
          );
          final winnerName = winnerTeam == 1 ? duoACombined : duoBCombined;
          debugPrint("[MatchSummary] Winner of the match: '$winnerName'");
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroWinnerBanner(
                  winnerLabel: winnerTeam == 1
                      ? _duoName(data.teamA)
                      : _duoName(data.teamB),
                  accent: winnerTeam == 1 ? scheme.primary : scheme.tertiary,
                ),
                const SizedBox(height: 16),
                SportsScoreboard(
                  sets: data.sets,
                  duoNameA: _duoName(data.teamA),
                  duoNameB: _duoName(data.teamB),
                ),
                const SizedBox(height: 16),
                Text('Sets', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SetsDuoList(
                  sets: data.sets,
                  duoNameA: _duoName(data.teamA),
                  duoNameB: _duoName(data.teamB),
                ),
                const SizedBox(height: 20),
                PremiumActionsBar(
                  onDone: () => Navigator.of(context).pop(),
                  onShare: null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<_SummaryData> _loadSummary(
    SupabaseClient client,
    String gameId,
  ) async {
    final setsRows = await client
        .from('score_sets')
        .select('set_index,team1_games,team2_games')
        .eq('game_id', gameId);
    debugPrint("[MatchSummary] Raw score_sets rows: $setsRows");
    final setsMaps = List<Map<String, dynamic>>.from(setsRows);
    final sets = <int, SetScore>{};
    for (final m in setsMaps) {
      final idx = m['set_index'] as int;
      sets[idx] = SetScore(
        team1: m['team1_games'] as int,
        team2: m['team2_games'] as int,
      );
      debugPrint(
        "[MatchSummary] Set ${idx + 1} parsed -> scoreA=${sets[idx]!.team1}, scoreB=${sets[idx]!.team2}",
      );
    }
    int winsA = 0;
    int winsB = 0;
    for (final e in sets.entries) {
      if (e.value.team1 > e.value.team2) {
        winsA++;
      } else if (e.value.team2 > e.value.team1) {
        winsB++;
      }
    }
    final winnerTeam = winsA >= winsB ? 1 : 2;
    debugPrint(
      "[MatchSummary] Winner calc from sets: A=$winsA, B=$winsB -> winnerTeam=$winnerTeam",
    );

    final playersRows = await client
        .from('game_players')
        .select('player_id,team')
        .eq('game_id', gameId);
    debugPrint("[MatchSummary] Raw game_players rows: $playersRows");
    final playersMaps = List<Map<String, dynamic>>.from(playersRows);
    final teamAIds = playersMaps
        .where((m) => m['team'] == 1)
        .map((m) => m['player_id'] as String)
        .toList();
    final teamBIds = playersMaps
        .where((m) => m['team'] == 2)
        .map((m) => m['player_id'] as String)
        .toList();
    debugPrint("[MatchSummary] Duo A player IDs: $teamAIds");
    debugPrint("[MatchSummary] Duo B player IDs: $teamBIds");
    final teamANames = await _resolveNames(client, teamAIds);
    final teamBNames = await _resolveNames(client, teamBIds);
    debugPrint(
      "[MatchSummary] Duo A player names (${teamANames.length}): $teamANames",
    );
    debugPrint(
      "[MatchSummary] Duo B player names (${teamBNames.length}): $teamBNames",
    );

    return _SummaryData(
      teamA: teamANames,
      teamB: teamBNames,
      sets: sets,
      winnerTeam: winnerTeam,
    );
  }

  Future<List<String>> _resolveNames(
    SupabaseClient client,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const [];
    final or = ids.map((id) => 'id.eq.$id').join(',');
    debugPrint("[MatchSummary] Resolving names for IDs: $ids");
    final rows = await client.from('players').select('id,name').or(or);
    final maps = List<Map<String, dynamic>>.from(rows);
    return maps.map((m) => m['name'] as String).toList();
  }

  String _duoName(List<String> players) {
    final combined = players.take(2).join(' & ');
    debugPrint(
      "[MatchSummary] Building duo name from players=$players -> '$combined'",
    );
    return combined;
  }

  // Removed: winners list helper not used after redesign
}

class _SummaryData {
  final List<String> teamA;
  final List<String> teamB;
  final Map<int, SetScore> sets;
  final int winnerTeam;
  _SummaryData({
    required this.teamA,
    required this.teamB,
    required this.sets,
    required this.winnerTeam,
  });
}
