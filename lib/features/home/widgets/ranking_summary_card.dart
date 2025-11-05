import 'package:flutter/material.dart';
import '../helpers/home_styles.dart';
import 'stat_chip.dart';

class RankingSummaryCard extends StatelessWidget {
  const RankingSummaryCard({super.key, required this.expanded, required this.onToggle});
  final bool expanded;
  final VoidCallback onToggle;

  @override 
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surface,
        boxShadow: [HomeShadows.soft()],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Your Ranking Summary',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: expanded
                    ? Padding(
                        key: const ValueKey('expanded'),
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Highlights', style: text.titleSmall),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                StatChip(label: 'Wins', value: '—'),
                                StatChip(label: 'Streak', value: '—'),
                                StatChip(label: 'Position', value: '—'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Coming soon: personalized ranking insights',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('collapsed')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}