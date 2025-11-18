import 'package:flutter/material.dart';
import '../../models/set_assignment.dart';

class SetsDuoList extends StatelessWidget {
  final Map<int, SetScore> sets;
  final String duoNameA;
  final String duoNameB;
  const SetsDuoList({
    super.key,
    required this.sets,
    required this.duoNameA,
    required this.duoNameB,
  });

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const SizedBox.shrink();
    final items = sets.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = items[i];
        final winner = e.value.team1 == e.value.team2
            ? null
            : (e.value.team1 > e.value.team2 ? 1 : 2);
        final setIndex = e.key + 1;
        final leftName = duoNameA;
        final rightName = duoNameB;
        final setWinnerName = winner == null
            ? 'Empate'
            : (winner == 1 ? duoNameA : duoNameB);
        debugPrint(
          "[MatchSummary] Set $setIndex -> scoreA=${e.value.team1} x scoreB=${e.value.team2}",
        );
        debugPrint("[MatchSummary] Set $setIndex winner: '$setWinnerName'");
        debugPrint(
          "[MatchSummary] Set $setIndex display left='$leftName' right='$rightName'",
        );
        return _SetDuoCard(
          index: e.key,
          team1: e.value.team1,
          team2: e.value.team2,
          duoNameA: duoNameA,
          duoNameB: duoNameB,
          winnerTeam: winner,
          delayMs: 100 * i,
        );
      },
    );
  }
}

class _SetDuoCard extends StatelessWidget {
  final int index;
  final int team1;
  final int team2;
  final String duoNameA;
  final String duoNameB;
  final int? winnerTeam;
  final int delayMs;
  const _SetDuoCard({
    required this.index,
    required this.team1,
    required this.team2,
    required this.duoNameA,
    required this.duoNameB,
    required this.winnerTeam,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = winnerTeam == 1 ? scheme.primary : scheme.tertiary;
    final winnerName = winnerTeam == 1 ? duoNameA : duoNameB;
    debugPrint("[MatchSummary] Rendering Set ${index + 1} card winner='$winnerName' score='$team1 × $team2'");
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + delayMs),
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: accent.withValues(alpha: 0.16)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set ${index + 1}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Vencedor',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: accent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    winnerName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ScoreChip(
                    label: duoNameA,
                    value: team1,
                    highlight: winnerTeam == 1,
                    accent: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreChip(
                    label: duoNameB,
                    value: team2,
                    highlight: winnerTeam == 2,
                    accent: scheme.tertiary,
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

class _ScoreChip extends StatelessWidget {
  final String label;
  final int value;
  final bool highlight;
  final Color accent;
  const _ScoreChip({
    required this.label,
    required this.value,
    required this.highlight,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: highlight ? accent : scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: highlight ? accent : null,
              ),
            ),
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlight ? accent : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
