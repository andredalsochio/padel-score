import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/validators.dart';
import '../models/set_assignment.dart';
import '../services/games_service.dart';
import '../services/players_service.dart';
import '../services/game_players_service.dart';
import '../services/scores_service.dart';
import '../services/score_set_players_service.dart';

class RegisterGameViewModel extends ChangeNotifier {
  final SupabaseClient client;
  final GamesService games;
  final PlayersService players;
  final GamePlayersService gamePlayers;
  final ScoresService scores;
  final ScoreSetPlayersService setPlayers;

  RegisterGameViewModel(this.client)
    : games = GamesService(client),
      players = PlayersService(client),
      gamePlayers = GamePlayersService(client),
      scores = ScoresService(client),
      setPlayers = ScoreSetPlayersService(client);

  String? _gameId;
  String? get gameId => _gameId;

  int bestOf = 3; // default
  bool saving = false;
  bool deleting = false;

  // Local working state
  final List<AssignedPlayer> _assignedPlayers = [];
  List<AssignedPlayer> get assignedPlayers =>
      List.unmodifiable(_assignedPlayers);

  final Map<int, SetScore> _sets = {}; // setIndex -> SetScore
  Map<int, SetScore> get sets => Map.unmodifiable(_sets);

  // Per-set player assignments
  final Map<int, SetAssignment> _setAssignments =
      {}; // setIndex -> SetAssignment
  SetAssignment? assignmentForSet(int setIndex) => _setAssignments[setIndex];
  Map<int, SetAssignment> get setAssignments =>
      Map.unmodifiable(_setAssignments);

  Future<void> startDraft() async {
    _gameId = await games.createDraft(bestOf: bestOf);
    _assignedPlayers.clear();
    _sets.clear();
    _setAssignments.clear();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchPlayers(String query) =>
      players.listMine(query: query);

  Future<Map<String, dynamic>> createPlayer(String name) =>
      players.create(name);

  Future<void> addPlayerToGame(Map<String, dynamic> player, {int? team}) async {
    if (_gameId == null) return;
    await gamePlayers.upsert(_gameId!, player['id'] as String, team: team);
    final exists = _assignedPlayers.any((p) => p.id == player['id']);
    if (!exists) {
      _assignedPlayers.add(
        AssignedPlayer(
          id: player['id'] as String,
          name: player['name'] as String,
          team: team,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> removePlayerFromGame(String playerId) async {
    if (_gameId == null) return;
    await gamePlayers.remove(_gameId!, playerId);
    _assignedPlayers.removeWhere((p) => p.id == playerId);
    // Remove from all set assignments locally
    for (final idx in _setAssignments.keys) {
      final current = _setAssignments[idx]!;
      _setAssignments[idx] = current.copyWith(
        entries: current.entries.where((e) => e.playerId != playerId).toList(),
      );
    }
    notifyListeners();
  }

  // Optional default team selection at draft level (does not persist per set)
  void setTeam(String playerId, int team) {
    final idx = _assignedPlayers.indexWhere((p) => p.id == playerId);
    if (idx >= 0) {
      _assignedPlayers[idx] = _assignedPlayers[idx].copyWith(team: team);
      notifyListeners();
    }
  }

  /// Ensure we have a SetAssignment in memory for a given set.
  Future<void> ensureAssignmentLoaded(int setIndex) async {
    if (_gameId == null) return;
    if (_setAssignments.containsKey(setIndex)) return;
    // Load from backend
    final rows = await setPlayers.listBySet(_gameId!, setIndex);
    final entries = rows
        .map(
          (r) => SetPlayerEntry(
            playerId: r['player_id'] as String,
            team: r['team'] as int?,
          ),
        )
        .toList();
    // If empty, initialize entries from current assigned players (no teams yet)
    if (entries.isEmpty) {
      for (final p in _assignedPlayers) {
        entries.add(SetPlayerEntry(playerId: p.id, team: null));
      }
    }
    _setAssignments[setIndex] = SetAssignment(
      setIndex: setIndex,
      entries: entries,
    );
    notifyListeners();
  }

  /// Persist and update team for a player in a given set.
  Future<void> setTeamForSet(int setIndex, String playerId, int? team) async {
    if (_gameId == null) return;
    await ensureAssignmentLoaded(setIndex);
    await setPlayers.upsert(_gameId!, setIndex, playerId, team: team);
    final current = _setAssignments[setIndex]!;
    final idx = current.entries.indexWhere((e) => e.playerId == playerId);
    List<SetPlayerEntry> updated = List.of(current.entries);
    if (idx >= 0) {
      updated[idx] = updated[idx].copyWith(team: team);
    } else {
      updated.add(SetPlayerEntry(playerId: playerId, team: team));
    }
    _setAssignments[setIndex] = current.copyWith(entries: updated);
    notifyListeners();
  }

  void selectScore(int setIndex, int team1, int team2) {
    _sets[setIndex] = SetScore(team1: team1, team2: team2);
    notifyListeners();
  }

  void removeSet(int setIndex) {
    _sets.remove(setIndex);
    _setAssignments.remove(setIndex);
    notifyListeners();
  }

  Future<void> persistScores() async {
    if (_gameId == null) return;
    for (final entry in _sets.entries) {
      final setIndex = entry.key;
      final team1 = entry.value.team1;
      final team2 = entry.value.team2;
      final winner = Validators.winnerFromSet(team1, team2);
      await scores.upsert(_gameId!, setIndex, team1, team2, winnerTeam: winner);
    }
  }

  bool get hasMinPlayers => Validators.hasMinPlayers(_assignedPlayers.length);

  bool canConfirmSet(int setIndex) {
    final score = _sets[setIndex];
    final assign = _setAssignments[setIndex];
    if (score == null || assign == null) return false;
    final total = _assignedPlayers.length;
    return Validators.isValidSetScore(score.team1, score.team2) &&
        Validators.hasValidSetComposition(
          assign,
          totalRegisteredPlayers: total,
        );
  }

  bool get canSaveGame {
    if (!hasMinPlayers) return false;
    if (_sets.isEmpty) return false;
    // All saved sets must have valid composition
    for (final idx in _sets.keys) {
      if (!canConfirmSet(idx)) return false;
    }
    return true;
  }

  Future<void> saveGame() async {
    if (_gameId == null) return;
    saving = true;
    notifyListeners();
    try {
      // Try transactional RPC first
      final payload = _sets.entries.map((e) {
        final assign = _setAssignments[e.key];
        return {
          'set_index': e.key,
          'team1_games': e.value.team1,
          'team2_games': e.value.team2,
          'winner_team': Validators.winnerFromSet(e.value.team1, e.value.team2),
          'players': assign == null
              ? []
              : assign.entries
                    .map((p) => {'player_id': p.playerId, 'team': p.team})
                    .toList(),
        };
      }).toList();

      await client.rpc(
        'save_game_with_sets',
        params: {'game_id': _gameId, 'sets': payload},
      );
    } catch (_) {
      // Fallback: persist scores sequentially and mark game completed
      await persistScores();
      await games.updateStatus(_gameId!, 'completed');
    }
    saving = false;
    notifyListeners();
  }

  Future<void> deleteGame() async {
    if (_gameId == null) return;
    deleting = true;
    notifyListeners();
    await games.deleteGame(_gameId!);
    deleting = false;
    _gameId = null;
    _assignedPlayers.clear();
    _sets.clear();
    notifyListeners();
  }
}
