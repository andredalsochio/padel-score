import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/validators.dart';
import '../models/set_assignment.dart';
import '../services/games_service.dart';
import '../../../players/data/player_repository.dart';
import '../../../players/service/player_service.dart';
import '../../../players/data/player_model.dart';
import '../services/game_players_service.dart';
import '../services/scores_service.dart';
import '../services/score_set_players_service.dart';
import '../models/patota_item.dart';
import '../../../players/service/ranking_service.dart';

class RegisterGameViewModel extends ChangeNotifier {
  final SupabaseClient client;
  final GamesService games;
  final PlayerRepository players;
  final GamePlayersService gamePlayers;
  final ScoresService scores;
  final ScoreSetPlayersService setPlayers;

  RegisterGameViewModel(this.client)
    : games = GamesService(client),
      players = PlayerRepository(PlayerService(client)),
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

  // Patota selection
  PatotaItem? _selectedPatota;
  PatotaItem? get selectedPatota => _selectedPatota;

  /// List user's patotas. Fallback to empty when table is missing.
  Future<List<PatotaItem>> listPatotas() async {
    try {
      final res = await client
          .from('patotas')
          .select('id,name')
          .eq('created_by', client.auth.currentUser!.id)
          .order('created_at');
      final maps = List<Map<String, dynamic>>.from(res);
      return maps.map(PatotaItem.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        // Log da falha para diagnóstico (ex.: coluna inexistente, RLS, etc.)
        print('listPatotas error: $e');
      }
      return const [];
    }
  }

  /// Create a new patota owned by the current user.
  /// Returns the created PatotaItem, or null on failure/missing table.
  Future<PatotaItem?> createPatota({
    required String name,
    String? avatarUrl,
  }) async {
    try {
      final uid = client.auth.currentUser?.id;
      if (uid == null) return null;
      final inserted = await client
          .from('patotas')
          .insert({'name': name, 'created_by': uid})
          .select('id,name')
          .single();
      return PatotaItem.fromMap(Map<String, dynamic>.from(inserted));
    } catch (e) {
      if (kDebugMode) {
        print('createPatota error: $e');
      }
      return null;
    }
  }

  /// Select a patota and load players. If relation table doesn't exist,
  /// fallback to the user's players list.
  Future<void> selectPatota(PatotaItem patota) async {
    _selectedPatota = patota;
    _assignedPlayers.clear();
    try {
      // 1) Busca os IDs de jogadores vinculados à patota
      final linkRows = await client
          .from('patota_players')
          .select('player_id')
          .eq('patota_id', patota.id)
          .order('created_at');
      final ids = List<Map<String, dynamic>>.from(
        linkRows,
      ).map((r) => r['player_id'] as String).toList();

      if (ids.isEmpty) {
        // Patota vazia: nenhum jogador
        _assignedPlayers.clear();
      } else {
        // 2) Carrega nomes dos jogadores pela lista de IDs
        // Supabase Dart nem sempre expõe `in_`; usamos `or` com múltiplos eq
        final orClause = ids.map((id) => 'id.eq.$id').join(',');
        final playersRows = await client
            .from('players')
            .select('id,name')
            .or(orClause);
        final maps = List<Map<String, dynamic>>.from(playersRows);
        for (final m in maps) {
          _assignedPlayers.add(
            AssignedPlayer(id: m['id'] as String, name: m['name'] as String),
          );
        }
      }
    } catch (_) {
      // Fallback: use user's players
      final list = await players.listMine();
      _assignedPlayers.addAll(
        list.map((p) => AssignedPlayer(id: p.id, name: p.name)),
      );
    }
    notifyListeners();
  }

  /// Link a player to a patota (creates a row in `patota_players`).
  /// Returns true on success, false otherwise. Duplicate links are ignored.
  Future<bool> addPlayerToPatota(String patotaId, String playerId) async {
    try {
      await client.from('patota_players').insert({
        'patota_id': patotaId,
        'player_id': playerId,
      });
      return true;
    } catch (_) {
      // Ignore duplicates or missing table
      return false;
    }
  }

  Future<void> startDraft() async {
    debugPrint("[RegisterSave] startDraft bestOf=$bestOf");
    _gameId = await games.createDraft(bestOf: bestOf);
    debugPrint("[RegisterSave] startDraft created gameId=$_gameId");
    _assignedPlayers.clear();
    _sets.clear();
    _setAssignments.clear();
    notifyListeners();
  }

  Future<List<PlayerModel>> searchPlayers(String query) =>
      players.listMine(query: query);

  Future<PlayerModel> createPlayer(String name) => players.create(name: name);

  Future<void> addPlayerToGame(PlayerModel player, {int? team}) async {
    if (_gameId == null) return;
    debugPrint(
      "[RegisterSave] addPlayerToGame gameId=$_gameId playerId=${player.id} name='${player.name}' team=$team",
    );
    await gamePlayers.upsert(_gameId!, player.id, team: team);
    final exists = _assignedPlayers.any((p) => p.id == player.id);
    if (!exists) {
      _assignedPlayers.add(
        AssignedPlayer(id: player.id, name: player.name, team: team),
      );
      debugPrint(
        "[RegisterSave] addPlayerToGame assignedPlayers size=${_assignedPlayers.length}",
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
  /// Set the default team for a player in the draft context.
  /// Pass null to clear assignment (unassigned).
  void setTeam(String playerId, int? team) {
    debugPrint("[RegisterSave] setTeam playerId=$playerId team=$team");
    final idx = _assignedPlayers.indexWhere((p) => p.id == playerId);
    if (idx >= 0) {
      _assignedPlayers[idx] = _assignedPlayers[idx].copyWith(team: team);
      debugPrint(
        "[RegisterSave] setTeam updated assignedPlayers[$idx] name='${_assignedPlayers[idx].name}' team=${_assignedPlayers[idx].team}",
      );
      notifyListeners();
    }
  }

  /// Reset all players to no team (used by Teams UI reset action).
  void resetTeams() {
    for (var i = 0; i < _assignedPlayers.length; i++) {
      _assignedPlayers[i] = _assignedPlayers[i].copyWith(team: null);
    }
    notifyListeners();
  }

  /// Derived state: whether both teams have at least one player
  bool get hasProgressTeams {
    final a = _assignedPlayers.where((p) => p.team == 1).length;
    final b = _assignedPlayers.where((p) => p.team == 2).length;
    return a > 0 && b > 0;
  }

  /// Ensure we have a SetAssignment in memory for a given set.
  Future<void> ensureAssignmentLoaded(int setIndex) async {
    if (_gameId == null) return;
    if (_setAssignments.containsKey(setIndex)) return;
    // Load from backend
    final entries = await setPlayers.listBySet(_gameId!, setIndex);
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

  /// Apply the currently assigned draft teams to a given set's composition.
  /// This prepares the per-set assignment used by validation and saving.
  void applyTeamsToSet(int setIndex) {
    debugPrint("[RegisterSave] applyTeamsToSet setIndex=$setIndex");
    final entries = _assignedPlayers
        .map((p) => SetPlayerEntry(playerId: p.id, team: p.team))
        .toList();
    debugPrint(
      "[RegisterSave] applyTeamsToSet entries=${entries.map((e) => {"id": e.playerId, "team": e.team}).toList()}",
    );
    _setAssignments[setIndex] = SetAssignment(
      setIndex: setIndex,
      entries: entries,
    );
    notifyListeners();
  }

  Future<void> persistScores() async {
    if (_gameId == null) return;
    debugPrint(
      "[RegisterSave] persistScores gameId=$_gameId sets=${_sets.entries.map((e) => {"index": e.key, "t1": e.value.team1, "t2": e.value.team2}).toList()}",
    );
    for (final entry in _sets.entries) {
      final setIndex = entry.key;
      final team1 = entry.value.team1;
      final team2 = entry.value.team2;
      final winner = Validators.winnerFromSet(team1, team2);
      debugPrint(
        "[RegisterSave] persistScores upsert setIndex=$setIndex team1=$team1 team2=$team2 winner=$winner",
      );
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
      debugPrint(
        "[RegisterSave] saveGame begin gameId=$_gameId assignedPlayers=${_assignedPlayers.map((p) => {"id": p.id, "name": p.name, "team": p.team}).toList()} setAssignments=${_setAssignments.map((k, v) => MapEntry(k, v.entries.map((e) => {"id": e.playerId, "team": e.team}).toList()))}",
      );
      await _persistGamePlayers();
      await _persistSetPlayers();
      await persistScores();
      await games.updateStatus(_gameId!, 'completed');
      debugPrint(
        "[RegisterSave] saveGame completed status updated for gameId=$_gameId",
      );
    } catch (e) {
      debugPrint("[RegisterSave] saveGame error: $e");
    }
    saving = false;
    notifyListeners();
  }

  Future<void> _persistGamePlayers() async {
    if (_gameId == null) return;
    debugPrint(
      "[RegisterSave] _persistGamePlayers gameId=$_gameId players=${_assignedPlayers.map((p) => {"id": p.id, "name": p.name, "team": p.team}).toList()}",
    );
    for (final p in _assignedPlayers) {
      await gamePlayers.upsert(_gameId!, p.id, team: p.team);
    }
  }

  Future<void> _persistSetPlayers() async {
    if (_gameId == null) return;
    debugPrint(
      "[RegisterSave] _persistSetPlayers gameId=$_gameId assignments=${_setAssignments.map((k, v) => MapEntry(k, v.entries.map((e) => {"id": e.playerId, "team": e.team}).toList()))}",
    );
    for (final entry in _setAssignments.entries) {
      final setIndex = entry.key;
      for (final e in entry.value.entries) {
        await setPlayers.upsert(_gameId!, setIndex, e.playerId, team: e.team);
      }
    }
  }

  Future<void> updateRankingForGame() async {
    if (_gameId == null) return;
    final ranking = RankingService(client);
    await ranking.updateAfterMatch(_gameId!);
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
