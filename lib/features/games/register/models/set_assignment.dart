import 'package:flutter/foundation.dart';

/// Draft-level membership of a player in the current game.
@immutable
class AssignedPlayer {
  final String id;
  final String name;
  final int?
  team; // Optional default team (1/2). Not used for persistence per set.

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
