# Typed Data Refactor — Padel App

Este documento consolida a análise completa do código Flutter e a refatoração aplicada para cumprir a regra de Typed Data Handling descrita em `AGENTS.md`.

O objetivo foi eliminar usos de `Map<String, dynamic>` diretamente na UI e lógica de negócio, substituindo por modelos tipados e concentrando a conversão `fromMap`/`toMap` nos próprios modelos.

---

## Arquivos e linhas afetadas (antes da refatoração)

- `lib/core/config/app_config.dart`
  - 26–27: acesso direto a chaves do Map (`map['supabaseUrl']`, `map['supabaseAnonKey']`).

- `lib/features/players/data/player_repository.dart`
  - 22: verificação de duplicidade usando `p['name']` dentro da lógica do repositório.

- `lib/features/games/register/viewmodels/register_game_view_model.dart`
  - 56–57: `searchPlayers`/`createPlayer` retornavam `List<Map<String, dynamic>>`/`Map<String, dynamic>`.
  - 64–70: `addPlayerToGame` consumia `Map<String, dynamic>` e acessava chaves (`player['id']`, `player['name']`).
  - 110–111: conversão de linhas vindas do serviço com acesso direto a chaves (`r['player_id']`, `r['team']`).

- `lib/features/games/register/widgets/add_player_sheet.dart`
  - 4, 21, 83: listas e seleção usando `Map<String, dynamic>` e acesso direto `p['name']` na UI.

- `lib/features/games/register/widgets/set_card.dart`
  - Uso de `Map<String, int>` para estado inicial do placar.

Observações sobre ocorrências toleradas por estarem no escopo de modelos/serviços (mantidas por estarem alinhadas à regra):

- `lib/features/players/data/player_model.dart` (16–18), `lib/features/games/register/models/game_models.dart` e `lib/features/games/register/services/games_service.dart` — acessos ao `Map` estão encapsulados nas fábricas `fromMap` dos modelos ou conversão em serviços (dentro da camada de dados), não em UI/negócio.

---

## Correções aplicadas e racional

1) Centralização de conversões em modelos
- Adicionada `factory SetPlayerEntry.fromMap(Map<String, dynamic>)` em `set_assignment.dart`.
- Mantidos `fromMap` existentes em `PlayerModel`, `GameModel`, `GamePlayerModel`, `ScoreSetModel`.

Motivo: conversões ficam no domínio dos modelos, garantindo tipagem forte na UI/negócio e evitando duplicação de parsing.

2) Tipagem de UI e ViewModel
- `AddPlayerSheet` agora recebe/retorna `PlayerModel` e renderiza `p.name`.
- `RegisterGameViewModel` passa a depender de `PlayerRepository` (em vez de `PlayersService`), expondo:
  - `Future<List<PlayerModel>> searchPlayers(String)`
  - `Future<PlayerModel> createPlayer(String)`
  - `Future<void> addPlayerToGame(PlayerModel, {int? team})`
- `ensureAssignmentLoaded` utiliza `ScoreSetPlayersService.listBySet` tipado, removendo conversões manuais com `Map`.
- `SetCard` usa `SetScore?` para estado inicial, eliminando `Map<String, int>`.

Motivo: UI e ViewModel devem trabalhar apenas com objetos tipados (modelos), preservando consistência com MVVM e evitando casts/acessos por chave.

3) Camada de dados (serviços) mantida com retorno de Map quando não há consumo direto pela UI
- `PlayersService`, `GamePlayersService`, `ScoresService` permanecem retornando `Map` apenas dentro da camada de dados.
- `ScoreSetPlayersService.listBySet` atualizado para retornar `List<SetPlayerEntry>`.

Motivo: serviços podem lidar com respostas cruas de APIs/DB; repositórios e modelos garantem tipagem antes de chegar à UI/negócio.

4) AppConfig com conversão tipada
- `AppConfig.fromMap` introduzida; `load()` usa a fábrica e aplica overrides via `dart-defines`.

Motivo: encapsular parsing e manter a configuração como objeto tipado, evitando acesso direto a `Map` fora do modelo.

---

## Código atualizado (pós-refatoração)

### lib/core/config/app_config.dart

```dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;

  const AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  factory AppConfig.fromMap(Map<String, dynamic> m) => AppConfig(
    supabaseUrl: (m['supabaseUrl'] as String?)?.trim() ?? '',
    supabaseAnonKey: (m['supabaseAnonKey'] as String?)?.trim() ?? '',
  );

  static AppConfig? _instance;

  static AppConfig get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
        'AppConfig not loaded. Call AppConfig.load() before use.',
      );
    }
    return inst;
  }

  static Future<void> load() async {
    // Load from asset file
    final raw = await rootBundle.loadString('assets/config/app_config.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    var config = AppConfig.fromMap(map);

    // Allow dart-defines to override if provided
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    final url = envUrl.trim().isNotEmpty ? envUrl.trim() : config.supabaseUrl;
    final key = envKey.trim().isNotEmpty
        ? envKey.trim()
        : config.supabaseAnonKey;

    _instance = AppConfig(supabaseUrl: url, supabaseAnonKey: key);
  }
}
```

Explicação: Parsing do JSON confinado ao modelo tipado via `fromMap`, removendo o acesso a chaves do `Map` na lógica de carregamento.

---

### lib/features/players/data/player_repository.dart

```dart
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
```

Explicação: Repositório opera com `PlayerModel`, removendo acesso a `Map` na verificação de duplicidade e alinhando com MVVM + Provider.

---

### lib/features/games/register/models/set_assignment.dart

```dart
import 'package:flutter/foundation.dart';

/// Draft-level membership of a player in the current game.
@immutable
class AssignedPlayer {
  final String id;
  final String name;
  final int? team; // Optional default team (1/2). Not used for persistence per set.

  const AssignedPlayer({required this.id, required this.name, this.team});

  AssignedPlayer copyWith({String? id, String? name, int? team}) =>
      AssignedPlayer(id: id ?? this.id, name: name ?? this.name, team: team);
}

/// One player's assignment for a specific set.
@immutable
class SetPlayerEntry {
  final String playerId;
  final int? team; // 1, 2, or null for resting

  const SetPlayerEntry({required this.playerId, this.team});

  factory SetPlayerEntry.fromMap(Map<String, dynamic> m) => SetPlayerEntry(
        playerId: m['player_id'] as String,
        team: m['team'] == null ? null : (m['team'] as num).toInt(),
      );

  bool get isResting => team == null;

  SetPlayerEntry copyWith({String? playerId, int? team}) =>
      SetPlayerEntry(playerId: playerId ?? this.playerId, team: team);
}

/// Assignment container for a set.
@immutable
class SetAssignment {
  final int setIndex; // zero-based
  final List<SetPlayerEntry> entries;

  const SetAssignment({required this.setIndex, required this.entries});

  int get team1Count => entries.where((e) => e.team == 1).length;
  int get team2Count => entries.where((e) => e.team == 2).length;
  int get restingCount => entries.where((e) => e.team == null).length;

  SetAssignment copyWith({int? setIndex, List<SetPlayerEntry>? entries}) =>
      SetAssignment(
        setIndex: setIndex ?? this.setIndex,
        entries: entries ?? this.entries,
      );
}

/// Typed local score for a set (used in UI state before persistence).
@immutable
class SetScore {
  final int team1;
  final int team2;

  const SetScore({required this.team1, required this.team2});

  SetScore copyWith({int? team1, int? team2}) =>
      SetScore(team1: team1 ?? this.team1, team2: team2 ?? this.team2);
}
```

Explicação: Conversão `fromMap` passou a existir no próprio modelo `SetPlayerEntry`, centralizando parsing.

---

### lib/features/games/register/services/score_set_players_service.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/set_assignment.dart';

class ScoreSetPlayersService {
  final SupabaseClient client;
  ScoreSetPlayersService(this.client);

  PostgrestQueryBuilder _table() => client.from('score_set_players');

  /// Lista atribuições de jogadores para um set específico de um jogo.
  Future<List<SetPlayerEntry>> listBySet(String gameId, int setIndex) async {
    final res = await _table()
        .select('game_id,set_index,player_id,team')
        .eq('game_id', gameId)
        .eq('set_index', setIndex)
        .order('player_id');
    return List<Map<String, dynamic>>.from(
      res,
    ).map(SetPlayerEntry.fromMap).toList();
  }

  /// Upsert a player's team for a given set. Pass null to mark as resting.
  Future<void> upsert(
    String gameId,
    int setIndex,
    String playerId, {
    int? team,
  }) async {
    await _table().upsert({
      'game_id': gameId,
      'set_index': setIndex,
      'player_id': playerId,
      'team': team,
    });
  }

  Future<void> remove(String gameId, int setIndex, String playerId) async {
    await _table()
        .delete()
        .eq('game_id', gameId)
        .eq('set_index', setIndex)
        .eq('player_id', playerId);
  }
}
```

Explicação: Serviço já entrega `List<SetPlayerEntry>` à camada de apresentação, evitando conversões por chave em ViewModel.

---

### lib/features/games/register/viewmodels/register_game_view_model.dart

```dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/validators.dart';
import '../models/set_assignment.dart';
import '../services/games_service.dart';
import '../../players/data/player_repository.dart';
import '../../players/service/player_service.dart';
import '../../players/data/player_model.dart';
import '../services/game_players_service.dart';
import '../services/scores_service.dart';
import '../services/score_set_players_service.dart';

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

  Future<void> startDraft() async {
    _gameId = await games.createDraft(bestOf: bestOf);
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
    await gamePlayers.upsert(_gameId!, player.id, team: team);
    final exists = _assignedPlayers.any((p) => p.id == player.id);
    if (!exists) {
      _assignedPlayers.add(
        AssignedPlayer(id: player.id, name: player.name, team: team),
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
```

Explicação: Toda a interação com jogadores e atribuições de set está tipada. Conversões de `Map` só ocorrem em serviços/modelos.

---

### lib/features/games/register/widgets/add_player_sheet.dart

```dart
import 'package:flutter/material.dart';
import '../../../players/data/player_model.dart';

class AddPlayerSheet extends StatefulWidget {
  final Future<List<PlayerModel>> Function(String query) onSearch;
  final Future<PlayerModel> Function(String name) onCreate;
  final ValueChanged<PlayerModel> onSelect;

  const AddPlayerSheet({
    super.key,
    required this.onSearch,
    required this.onCreate,
    required this.onSelect,
  });

  @override
  State<AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends State<AddPlayerSheet> {
  final TextEditingController _query = TextEditingController();
  List<PlayerModel> _results = const [];
  bool _loading = false;

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    final res = await widget.onSearch(_query.text);
    setState(() {
      _results = res;
      _loading = false;
    });
  }

  Future<void> _create() async {
    if (_query.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final created = await widget.onCreate(_query.text.trim());
    setState(() => _loading = false);
    widget.onSelect(created);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _query,
              decoration: const InputDecoration(
                labelText: 'Pesquisar ou criar jogador',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _runSearch(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _runSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Pesquisar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _create,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Criar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final p = _results[index];
                  return ListTile(
                    title: Text(p.name),
                    onTap: () {
                      widget.onSelect(p);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Explicação: UI sem `Map` — interage com `PlayerModel` apenas, removendo casts/índices por chave.

---

### lib/features/games/register/widgets/set_card.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/validators.dart';
import '../models/set_assignment.dart';
import 'score_button.dart';

/// Displays one active set with two score buttons (Team A / Team B)
/// and a confirmation action.
class SetCard extends StatefulWidget {
  final int setIndex; // zero-based
  final SetScore? initial;
  final void Function(int team1, int team2) onConfirm;
  final List<AssignedPlayer> players;
  final SetAssignment? assignment; // per-set assignments
  final void Function(String playerId, int? team)
  onSetPlayerTeam; // persist immediately

  const SetCard({
    super.key,
    required this.setIndex,
    this.initial,
    required this.onConfirm,
    required this.players,
    required this.assignment,
    required this.onSetPlayerTeam,
  });

  @override
  State<SetCard> createState() => _SetCardState();
}

class _SetCardState extends State<SetCard> {
  late int team1;
  late int team2;

  @override
  void initState() {
    super.initState();
    team1 = widget.initial?.team1 ?? 0;
    team2 = widget.initial?.team2 ?? 0;
  }

  void _cycleTeam1() {
    setState(() => team1 = (team1 + 1) % 8);
  }

  void _cycleTeam2() {
    setState(() => team2 = (team2 + 1) % 8);
  }

  @override
  Widget build(BuildContext context) {
    final totalPlayers = widget.players.length;
    final compOk = widget.assignment != null
        ? Validators.hasValidSetComposition(
            widget.assignment!,
            totalRegisteredPlayers: totalPlayers,
          )
        : false;
    final canSave = Validators.isValidSetScore(team1, team2) && compOk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Set ${widget.setIndex + 1}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ScoreButton(
                label: 'Team A',
                score: team1,
                onTap: _cycleTeam1,
                highlighted: team1 >= team2 && team1 > 0,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: ScoreButton(
                label: 'Team B',
                score: team2,
                onTap: _cycleTeam2,
                highlighted: team2 >= team1 && team2 > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Composição de times deste set',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        _PlayersSelector(
          players: widget.players,
          assignment: widget.assignment,
          onSetPlayerTeam: widget.onSetPlayerTeam,
        ),
        if (totalPlayers == 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Com 5 jogadores, exatamente 1 precisa descansar neste set.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: 180,
          child: FilledButton.icon(
            icon: const Icon(Icons.check_circle),
            onPressed: canSave
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onConfirm(team1, team2);
                  }
                : null,
            label: const Text('Salvar Set'),
          ),
        ),
      ],
    );
  }
}

class _PlayersSelector extends StatelessWidget {
  final List<AssignedPlayer> players;
  final SetAssignment? assignment;
  final void Function(String playerId, int? team) onSetPlayerTeam;

  const _PlayersSelector({
    required this.players,
    required this.assignment,
    required this.onSetPlayerTeam,
  });

  int? _selectedTeamFor(String playerId) {
    final entry = assignment?.entries.firstWhere(
      (e) => e.playerId == playerId,
      orElse: () => SetPlayerEntry(playerId: playerId, team: null),
    );
    return entry?.team;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: players
          .map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(p.name)),
                  ChoiceChip(
                    label: const Text('Time 1'),
                    selected: _selectedTeamFor(p.id) == 1,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      onSetPlayerTeam(p.id, 1);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Time 2'),
                    selected: _selectedTeamFor(p.id) == 2,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      onSetPlayerTeam(p.id, 2);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Descansando'),
                    selected: _selectedTeamFor(p.id) == null,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      onSetPlayerTeam(p.id, null);
                    },
                    avatar: Icon(Icons.hotel, color: scheme.primary, size: 18),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
```

Explicação: `initial` é `SetScore?`, substituindo `Map<String, int>` e evitando acesso por chave na inicialização do estado.

---

## Notas finais

- As conversões de dados brutos (Map) ficam exclusivamente na camada de dados (serviços) e nos modelos (`fromMap`/`toMap`).
- UI e ViewModels operam apenas com objetos tipados, eliminando `dynamic`, `var` ambíguo e acessos `p['id']`, `data['name']` etc.
- Convenções respeitadas:
  - MVVM + Provider
  - Um widget público por arquivo
  - Imports relativos
  - Material 3 e APIs modernas do Flutter 3.35+

---

## Próximos passos sugeridos (opcional)

- Tipar `GamePlayersService.listByGame` e `ScoresService.listByGame` caso venham a ser consumidos na UI futuramente.
- Considerar `sealed` classes/`typedefs` para payloads complexos enviados ao `rpc` (quando houver necessidade), mantendo tipagem forte.

---

Todos os arquivos foram formatados com `dart format` e seguem os padrões do projeto.