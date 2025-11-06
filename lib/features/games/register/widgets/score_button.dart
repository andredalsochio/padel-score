import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A large tappable card that cycles the score from 0 → 7 → 0
/// with subtle motion and color feedback.
class ScoreButton extends StatelessWidget {
  final String label;
  final int score;
  final VoidCallback? onTap; // Parent computes next value; we only notify
  final bool highlighted;

  const ScoreButton({
    super.key,
    required this.label,
    required this.score,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHighest;
    final highlightColor = scheme.primary.withValues(alpha: 0.12);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: highlighted ? baseColor : baseColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: highlighted ? 16 : 10,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: highlighted
                ? scheme.primary.withValues(alpha: 0.24)
                : scheme.outlineVariant,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AnimatedScale(
              duration: const Duration(milliseconds: 140),
              scale: highlighted ? 1.06 : 1.0,
              curve: Curves.easeOut,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: highlighted ? highlightColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '$score',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
