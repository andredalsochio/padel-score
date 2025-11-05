import 'package:flutter/material.dart';
import '../helpers/home_styles.dart';
import 'shimmer.dart';

class RecentMatchPlaceholder extends StatelessWidget {
  const RecentMatchPlaceholder({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surface,
        boxShadow: [HomeShadows.soft()],
      ),
      child: Shimmer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_tennis, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('Match #${index + 1}', style: text.titleMedium),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 12,
                width: 180,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 240,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Coming soon',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}