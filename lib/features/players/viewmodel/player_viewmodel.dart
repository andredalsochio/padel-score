import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/player_model.dart';
import '../data/player_repository.dart';
import '../service/player_service.dart';

class PlayerViewModel extends ChangeNotifier {
  final SupabaseClient client;
  late final PlayerRepository repo;

  PlayerViewModel(this.client) {
    repo = PlayerRepository(PlayerService(client));
    _loadInitial();
  }

  bool _loading = false;
  String? _error;
  List<PlayerModel> _players = [];

  bool get loading => _loading;
  String? get errorMessage => _error;
  List<PlayerModel> get players => _players;
  bool get minPlayersMet => _players.length >= 4;
  int get playerCount => _players.length;
  List<PlayerModel> get rankedPlayers => List<PlayerModel>.from(_players);

  Future<void> _loadInitial() async {
    _setLoading(true);
    try {
      _players = await repo.listMine();
      _error = null;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    try {
      _players = await repo.listMine();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
    }
  }

  Future<bool> addPlayer(String name) async {
    _setLoading(true);
    try {
      final p = await repo.create(name: name);
      _players = [..._players, p];
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> editPlayer({required String id, required String name}) async {
    _setLoading(true);
    try {
      final updated = await repo.updateName(id: id, name: name);
      _players = _players.map((p) => p.id == id ? updated : p).toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removePlayer(String id) async {
    _setLoading(true);
    try {
      await repo.delete(id: id);
      _players = _players.where((p) => p.id != id).toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  String _formatError(Object e) {
    final msg = e.toString();
    return msg.replaceAll('Exception: ', '');
  }
}
