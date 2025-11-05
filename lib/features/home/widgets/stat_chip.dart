import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: text.bodySmall),
          const SizedBox(width: 6),
          Text(value, style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}