import 'package:flutter/material.dart';
import '../models/set_assignment.dart';

class CollapsibleSetsList extends StatelessWidget {
  final Map<int, SetScore> sets;
  const CollapsibleSetsList({super.key, required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return const SizedBox.shrink();
    }
    final items = sets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final e = items[i];
        return ExpansionTile(
          title: Text('Set ${e.key + 1}: ${e.value.team1}–${e.value.team2}'),
          children: const [
            // Placeholder for per-set composition summary
            // Could render team assignments here when available
            ListTile(title: Text('Composição do set')), 
          ],
        );
      },
    );
  }
}