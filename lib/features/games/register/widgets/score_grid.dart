import 'package:flutter/material.dart';
import 'score_card.dart';

class ScoreGrid extends StatelessWidget {
  final int setIndex;
  final Map<String, int>? selected;
  final void Function(int team1, int team2) onSelect;

  const ScoreGrid({
    super.key,
    required this.setIndex,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Build common tennis/padel set outcomes
    final options = <List<int>>[
      [6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [7, 5], [7, 6],
      [0, 6], [1, 6], [2, 6], [3, 6], [4, 6], [5, 7], [6, 7],
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final o = options[index];
        final isSelected = selected != null && selected!['team1'] == o[0] && selected!['team2'] == o[1];
        return ScoreCard(
          team1: o[0],
          team2: o[1],
          selected: isSelected,
          onTap: () => onSelect(o[0], o[1]),
        );
      },
    );
  }
}