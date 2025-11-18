import 'package:flutter/material.dart';
import '../helpers/home_styles.dart';

class RecentMatchCard extends StatelessWidget {
  const RecentMatchCard({
    super.key,
    required this.duoA,
    required this.duoB,
    required this.scores,
    required this.winnerDuo,
  });
  final String duoA;
  final String duoB;
  final List<String> scores; // e.g., ['6×0','4×7']
  final String winnerDuo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: scheme.surface,
          boxShadow: [HomeShadows.soft()],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Partidas recentes',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Vencedor',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    duoA,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('vs', style: text.labelMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    duoB,
                    textAlign: TextAlign.right,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Placar: ${scores.join('  |  ')}',
                    style: text.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    winnerDuo,
                    textAlign: TextAlign.right,
                    style: text.bodyMedium?.copyWith(color: scheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
