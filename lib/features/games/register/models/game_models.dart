import 'package:flutter/foundation.dart';

@immutable
class GameModel {
  final String id;
  final String createdBy;
  final String status; // 'draft' | 'completed' | 'cancelled'
  final int bestOf; // 1,3,5
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? notes;

  const GameModel({
    required this.id,
    required this.createdBy,
    required this.status,
    required this.bestOf,
    this.startedAt,
    this.endedAt,
    this.notes,
  });

  factory GameModel.fromMap(Map<String, dynamic> m) => GameModel(
    id: m['id'] as String,
    createdBy: m['created_by'] as String,
    status: m['status'] as String,
    bestOf: (m['best_of'] as num).toInt(),
    startedAt: m['started_at'] != null
        ? DateTime.parse(m['started_at'] as String)
        : null,
    endedAt: m['ended_at'] != null
        ? DateTime.parse(m['ended_at'] as String)
        : null,
    notes: m['notes'] as String?,
  );

  Map<String, dynamic> toInsert() => {
    'status': status,
    'best_of': bestOf,
    if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
    if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
    if (notes != null) 'notes': notes,
  };
}

// Removed duplicated PlayerModel. Use canonical model from features/players/data/player_model.dart.

@immutable
class GamePlayerModel {
  final String id;
  final String gameId;
  final String playerId;
  final int? team; // 1 | 2

  const GamePlayerModel({
    required this.id,
    required this.gameId,
    required this.playerId,
    this.team,
  });

  factory GamePlayerModel.fromMap(Map<String, dynamic> m) => GamePlayerModel(
    id: m['id'] as String,
    gameId: m['game_id'] as String,
    playerId: m['player_id'] as String,
    team: m['team'] == null ? null : (m['team'] as num).toInt(),
  );

  Map<String, dynamic> toInsert({
    required String gameId,
    required String playerId,
    int? team,
  }) => {
    'game_id': gameId,
    'player_id': playerId,
    if (team != null) 'team': team,
  };
}

@immutable
class ScoreSetModel {
  final String id;
  final String gameId;
  final int setIndex;
  final int team1Games;
  final int team2Games;
  final int? winnerTeam;

  const ScoreSetModel({
    required this.id,
    required this.gameId,
    required this.setIndex,
    required this.team1Games,
    required this.team2Games,
    this.winnerTeam,
  });

  factory ScoreSetModel.fromMap(Map<String, dynamic> m) => ScoreSetModel(
    id: m['id'] as String,
    gameId: m['game_id'] as String,
    setIndex: (m['set_index'] as num).toInt(),
    team1Games: (m['team1_games'] as num).toInt(),
    team2Games: (m['team2_games'] as num).toInt(),
    winnerTeam: m['winner_team'] == null
        ? null
        : (m['winner_team'] as num).toInt(),
  );

  Map<String, dynamic> toInsert({
    required String gameId,
    required int setIndex,
    required int team1,
    required int team2,
    int? winnerTeam,
  }) => {
    'game_id': gameId,
    'set_index': setIndex,
    'team1_games': team1,
    'team2_games': team2,
    if (winnerTeam != null) 'winner_team': winnerTeam,
  };
}
