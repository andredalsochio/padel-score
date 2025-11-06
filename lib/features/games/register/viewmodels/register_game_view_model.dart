import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/validators.dart';
import '../services/games_service.dart';
import '../services/players_service.dart';
import '../services/game_players_service.dart';
import '../services/scores_service.dart';

class RegisterGameViewModel extends ChangeNotifier {
  final SupabaseClient client;
  final GamesService games;
  final PlayersService players;
  final GamePlayersService gamePlayers;
  final ScoresService scores;

  RegisterGameViewModel(this.client)
      : games = GamesService(client),
        players = PlayersService(client),
        gamePlayers = GamePlayersService(client),
        scores = ScoresService(client);

  String? _gameId;
  String? get gameId => _gameId;

  int bestOf = 3; // default
  bool saving = false;
  bool deleting = false;

  // Local working state
  final List<Map<String, dynamic>> _assignedPlayers = [];
  List<Map<String, dynamic>> get assignedPlayers => List.unmodifiable(_assignedPlayers);

  final Map<int, Map<String, int>> _sets = {}; // setIndex -> {team1: x, team2: y}
  Map<int, Map<String, int>> get sets => Map.unmodifiable(_sets);

  Future<void> startDraft() async {
    _gameId = await games.createDraft(bestOf: bestOf);
    _assignedPlayers.clear();
    _sets.clear();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchPlayers(String query) => players.listMine(query: query);

  Future<Map<String, dynamic>> createPlayer(String name) => players.create(name);

  Future<void> addPlayerToGame(Map<String, dynamic> player, {int? team}) async {
    if (_gameId == null) return;
    await gamePlayers.upsert(_gameId!, player['id'] as String, team: team);
    _assignedPlayers.add({'id': player['id'], 'name': player['name'], 'team': team});
    notifyListeners();
  }

  Future<void> removePlayerFromGame(String playerId) async {
    if (_gameId == null) return;
    await gamePlayers.remove(_gameId!, playerId);
    _assignedPlayers.removeWhere((p) => p['id'] == playerId);
    notifyListeners();
  }

  void setTeam(String playerId, int team) {
    final idx = _assignedPlayers.indexWhere((p) => p['id'] == playerId);
    if (idx >= 0) {
      _assignedPlayers[idx] = {
        ..._assignedPlayers[idx],
        'team': team,
      };
      notifyListeners();
    }
  }

  void selectScore(int setIndex, int team1, int team2) {
    _sets[setIndex] = {'team1': team1, 'team2': team2};
    notifyListeners();
  }

  void removeSet(int setIndex) {
    _sets.remove(setIndex);
    notifyListeners();
  }

  Future<void> persistScores() async {
    if (_gameId == null) return;
    for (final entry in _sets.entries) {
      final setIndex = entry.key;
      final team1 = entry.value['team1']!;
      final team2 = entry.value['team2']!;
      final winner = Validators.winnerFromSet(team1, team2);
      await scores.upsert(_gameId!, setIndex, team1, team2, winnerTeam: winner);
    }
  }

  bool get canSaveGame => Validators.hasMinPlayers(_assignedPlayers.length) && _sets.isNotEmpty;

  Future<void> saveGame() async {
    if (_gameId == null) return;
    saving = true;
    notifyListeners();
    await persistScores();
    await games.updateStatus(_gameId!, 'completed');
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