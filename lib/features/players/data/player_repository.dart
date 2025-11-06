import '../data/player_model.dart';
import '../service/player_service.dart';

class PlayerRepository {
  final PlayerService service;
  PlayerRepository(this.service);

  Future<List<PlayerModel>> listMine({String? query}) async {
    final res = await service.listMine(query: query);
    return res.map(PlayerModel.fromMap).toList();
  }

  Future<PlayerModel> create({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Nome do jogador não pode ser vazio');
    }
    // Basic duplicate check (case-insensitive exact match)
    final existing = await listMine(query: trimmed);
    final hasDuplicate = existing.any(
      (p) => p.name.toLowerCase().trim() == trimmed.toLowerCase(),
    );
    if (hasDuplicate) {
      throw StateError('Já existe um jogador com este nome');
    }
    final res = await service.create(trimmed);
    return PlayerModel.fromMap(res);
  }
}
