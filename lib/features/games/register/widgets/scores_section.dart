import 'package:flutter/material.dart';
import 'score_grid.dart';
import 'sets_summary.dart';

class ScoresSection extends StatelessWidget {
  final Map<int, Map<String, int>> sets;
  final void Function(int setIndex, int team1, int team2) onSelect;
  final void Function(int setIndex) onRemove;

  const ScoresSection({
    super.key,
    required this.sets,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final setIndices = List<int>.generate(3, (i) => i); // best of 3 default
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sets', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...setIndices.map((i) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Set ${i + 1}', style: Theme.of(context).textTheme.titleMedium)),
                    if (sets.containsKey(i))
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => onRemove(i),
                        tooltip: 'Remover set',
                      )
                  ],
                ),
                ScoreGrid(
                  setIndex: i,
                  selected: sets[i],
                  onSelect: (a, b) => onSelect(i, a, b),
                ),
                const SizedBox(height: 12),
              ],
            )),
        SetsSummary(sets: sets),
      ],
    );
  }
}