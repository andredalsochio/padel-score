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

  static bool hasMinPlayers(int count) => count >= 2;
}