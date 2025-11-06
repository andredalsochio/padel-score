import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../players/data/player_model.dart';
import '../../games/register/models/patota_item.dart';

class PatotasViewModel extends ChangeNotifier {
  final SupabaseClient client;
  PatotasViewModel(this.client);

  List<PatotaItem> _patotas = const [];
  PatotaItem? _selected;
  List<PlayerModel> _players = const [];

  List<PatotaItem> get patotas => _patotas;
  PatotaItem? get selected => _selected;
  List<PlayerModel> get players => _players;

  Future<void> refreshPatotas() async {
    try {
      final res = await client
          .from('patotas')
          .select('id,name')
          .eq('created_by', client.auth.currentUser!.id)
          .order('created_at');
      _patotas = List<Map<String, dynamic>>.from(res)
          .map(PatotaItem.fromMap)
          .toList();
    } catch (e) {
      if (kDebugMode) print('refreshPatotas error: $e');
      _patotas = const [];
    }
    notifyListeners();
  }

  Future<PatotaItem?> createPatota(String name) async {
    try {
      final uid = client.auth.currentUser?.id;
      if (uid == null) return null;
      final inserted = await client
          .from('patotas')
          .insert({'name': name, 'created_by': uid})
          .select('id,name')
          .single();
      final p = PatotaItem.fromMap(Map<String, dynamic>.from(inserted));
      _patotas = [p, ..._patotas];
      notifyListeners();
      return p;
    } catch (e) {
      if (kDebugMode) print('createPatota error: $e');
      return null;
    }
  }

  Future<void> deletePatota(String patotaId) async {
    try {
      await client.from('patotas').delete().eq('id', patotaId);
      _patotas = _patotas.where((p) => p.id != patotaId).toList();
      if (_selected?.id == patotaId) {
        _selected = null;
        _players = const [];
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('deletePatota error: $e');
    }
  }

  Future<void> selectPatota(PatotaItem p) async {
    _selected = p;
    await _loadPlayersForPatota(p.id);
    notifyListeners();
  }

  Future<void> _loadPlayersForPatota(String patotaId) async {
    try {
      final res = await client
          .from('patota_players')
          .select('player_id, players(name,created_by)')
          .eq('patota_id', patotaId)
          .order('created_at');
      final rows = List<Map<String, dynamic>>.from(res);
      _players = rows
          .map((row) => PlayerModel(
                id: row['player_id'] as String,
                name: (row['players'] as Map<String, dynamic>)['name'] as String,
                createdBy: (row['players'] as Map<String, dynamic>)['created_by'] as String,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) print('loadPlayersForPatota error: $e');
      _players = const [];
    }
  }

  Future<bool> addPlayer(String patotaId, PlayerModel player) async {
    try {
      await client
          .from('patota_players')
          .insert({'patota_id': patotaId, 'player_id': player.id});
      // Recarrega para garantir dados completos (ex.: nome do jogador)
      await _loadPlayersForPatota(patotaId);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('addPlayer error: $e');
      return false;
    }
  }

  Future<bool> removePlayer(String patotaId, String playerId) async {
    try {
      await client
          .from('patota_players')
          .delete()
          .eq('patota_id', patotaId)
          .eq('player_id', playerId);
      await _loadPlayersForPatota(patotaId);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('removePlayer error: $e');
      return false;
    }
  }

  /// Lista todos os jogadores do usuário atual (para seleção múltipla).
  Future<List<PlayerModel>> listAllPlayers() async {
    try {
      final uid = client.auth.currentUser?.id;
      if (uid == null) return [];
      final res = await client
          .from('players')
          .select('id,name,created_by')
          .eq('created_by', uid)
          .order('created_at');
      final rows = List<Map<String, dynamic>>.from(res);
      return rows
          .map((m) => PlayerModel(
                id: m['id'] as String,
                name: m['name'] as String,
                createdBy: m['created_by'] as String,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) print('listAllPlayers error: $e');
      return [];
    }
  }

  /// Adiciona vários jogadores à patota; ignora duplicados.
  Future<bool> addPlayers(String patotaId, List<String> playerIds) async {
    if (playerIds.isEmpty) return false;
    try {
      final rows = playerIds
          .map((id) => {'patota_id': patotaId, 'player_id': id})
          .toList();
      await client
          .from('patota_players')
          .upsert(rows, onConflict: 'patota_id,player_id');
      await _loadPlayersForPatota(patotaId);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('addPlayers error: $e');
      return false;
    }
  }

  /// Atualiza o nome da patota e reflete no estado local.
  Future<bool> updatePatotaName(String patotaId, String newName) async {
    try {
      await client
          .from('patotas')
          .update({'name': newName})
          .eq('id', patotaId);
      _patotas = _patotas
          .map((p) => p.id == patotaId ? PatotaItem(id: p.id, name: newName) : p)
          .toList();
      if (_selected?.id == patotaId) {
        _selected = PatotaItem(id: patotaId, name: newName);
      }
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('updatePatotaName error: $e');
      return false;
    }
  }
}