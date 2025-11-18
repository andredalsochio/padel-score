import 'package:flutter/material.dart';
import '../../models/set_assignment.dart';

class SportsScoreboard extends StatelessWidget {
  final Map<int, SetScore> sets;
  final String duoNameA;
  final String duoNameB;
  const SportsScoreboard({
    super.key,
    required this.sets,
    required this.duoNameA,
    required this.duoNameB,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = sets.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final headers = List.generate(items.length, (i) => 'S${i + 1}');
    debugPrint("[MatchSummary] Scoreboard left='$duoNameA' right='$duoNameB'");
    debugPrint(
      "[MatchSummary] Scoreboard A scores=${items.map((e) => e.value.team1).toList()}",
    );
    debugPrint(
      "[MatchSummary] Scoreboard B scores=${items.map((e) => e.value.team2).toList()}",
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                for (final h in headers)
                  SizedBox(
                    width: 44,
                    child: Center(
                      child: Text(
                        h,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _ScoreRow(
              name: duoNameA,
              scores: items.map<int>((e) => e.value.team1).toList(),
              accent: scheme.primary,
            ),
            const SizedBox(height: 6),
            _ScoreRow(
              name: duoNameB,
              scores: items.map<int>((e) => e.value.team2).toList(),
              accent: scheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String name;
  final List<int> scores;
  final Color accent;
  const _ScoreRow({
    required this.name,
    required this.scores,
    required this.accent,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    debugPrint(
      "[MatchSummary] Rendering scoreboard row for '$name' with scores=$scores",
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        for (int i = 0; i < scores.length; i++)
          Container(
            width: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: accent.withValues(alpha: 0.14)),
            ),
            child: Center(
              child: Text(
                '${scores[i]}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
