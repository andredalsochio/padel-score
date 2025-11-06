import 'package:flutter/material.dart';
import '../helpers/validators.dart';
import '../models/set_assignment.dart';

class SetsSummary extends StatelessWidget {
  final Map<int, SetScore> sets;
  const SetsSummary({super.key, required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return const Text('Nenhum set selecionado ainda.');
    }
    final entries = sets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        final w = Validators.winnerFromSet(e.value.team1, e.value.team2);
        final winnerLabel = w == null
            ? ''
            : ' (Winner: Team ${w == 1 ? 'A' : 'B'})';
        return Chip(
          label: Text(
            '✅ Set ${e.key + 1}: ${e.value.team1}–${e.value.team2}$winnerLabel',
          ),
        );
      }).toList(),
    );
  }
}
