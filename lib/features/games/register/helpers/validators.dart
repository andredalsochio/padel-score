import '../models/set_assignment.dart';

class Validators {
  const Validators._();

  static bool isValidSetScore(int a, int b) {
    if (a < 0 || b < 0 || a > 7 || b > 7) return false;
    // Simple validation: one side must have at least 6 and lead by 2, unless 7-6 tie-break.
    final max = a > b ? a : b;
    final min = a > b ? b : a;
    if (max < 6) return false;
    if (max == 6 && (max - min) >= 2) return true;
    if (max == 7 && (max - min) == 1) return true; // e.g., 7-6
    if (max == 7 && (max - min) >= 2) return true; // e.g., 7-5
    return false;
  }

  static int? winnerFromSet(int team1, int team2) {
    if (!isValidSetScore(team1, team2)) return null;
    return team1 > team2 ? 1 : 2;
  }

  static bool hasMinPlayers(int count) => count >= 4;

  /// Exactly 2 players on team 1, exactly 2 on team 2, none duplicated across teams.
  /// If there are 5 players registered overall, exactly 1 must be resting in this set.
  static bool hasValidSetComposition(
    SetAssignment assignment, {
    required int totalRegisteredPlayers,
  }) {
    // Two per team
    if (assignment.team1Count != 2) return false;
    if (assignment.team2Count != 2) return false;

    // No player can be in both teams in the same set (implicit by single team per entry)
    // Ensure no duplicates in entries list
    final ids = assignment.entries.map((e) => e.playerId).toList();
    final uniqueIds = ids.toSet();
    if (uniqueIds.length != ids.length) return false;

    // Fifth player scenario: when total is 5, exactly one resting
    if (totalRegisteredPlayers == 5 && assignment.restingCount != 1)
      return false;
    if (totalRegisteredPlayers < 5 && assignment.restingCount != 0)
      return false;

    return true;
  }
}
