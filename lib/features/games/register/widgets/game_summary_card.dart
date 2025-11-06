import 'package:flutter/material.dart';
import '../helpers/validators.dart';
import '../models/set_assignment.dart';

class GameSummaryCard extends StatelessWidget {
  final Map<int, SetScore> sets;
  final Map<int, SetAssignment>? assignments;
  final int totalPlayers;
  final VoidCallback onSaveGame;
  const GameSummaryCard({
    super.key,
    required this.sets,
    this.assignments,
    required this.totalPlayers,
    required this.onSaveGame,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = sets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final winner = _winner(entries);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      offset: const Offset(0, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '🏆 Final Score',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (winner != null)
                    Chip(
                      label: Text('Winner: Team ${winner == 1 ? 'A' : 'B'}'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'Set ${e.key + 1}: ${e.value.team1}–${e.value.team2}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onSaveGame,
                  child: const Text('Salvar Jogo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _winner(List<MapEntry<int, SetScore>> entries) {
    // Best of X winner by majority of sets
    int winsA = 0;
    int winsB = 0;
    for (final e in entries) {
      // Consider only valid sets with valid composition
      final assign = assignments?[e.key];
      final score = e.value;
      if (assign == null) continue;
      final compOk = Validators.hasValidSetComposition(
        assign,
        totalRegisteredPlayers: totalPlayers,
      );
      if (!compOk) continue;
      final w = Validators.winnerFromSet(score.team1, score.team2);
      if (w == 1) {
        winsA++;
      } else if (w == 2) {
        winsB++;
      }
    }
    if (winsA == winsB) return null;
    return winsA > winsB ? 1 : 2;
  }
}
