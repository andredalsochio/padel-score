import 'package:flutter/material.dart';
import '../helpers/register_styles.dart';

class ScoreCard extends StatelessWidget {
  final int team1;
  final int team2;
  final bool selected;
  final VoidCallback onTap;

  const ScoreCard({
    super.key,
    required this.team1,
    required this.team2,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? scheme.primaryContainer
        : RegisterStyles.surfaceLow(scheme);
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Material(
      color: bg,
      borderRadius: RegisterStyles.cardRadius,
      child: InkWell(
        borderRadius: RegisterStyles.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$team1',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: fg),
              ),
              const Text('—'),
              Text(
                '$team2',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
