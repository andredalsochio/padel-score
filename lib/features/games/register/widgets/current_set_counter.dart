import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/validators.dart';
import '../helpers/register_styles.dart';

class CurrentSetCounter extends StatefulWidget {
  final int setIndex;
  final void Function(int team1, int team2) onFinalizeSet;
  const CurrentSetCounter({
    super.key,
    required this.setIndex,
    required this.onFinalizeSet,
  });

  @override
  State<CurrentSetCounter> createState() => _CurrentSetCounterState();
}

class _CurrentSetCounterState extends State<CurrentSetCounter> {
  int a = 0;
  int b = 0;

  void _incA() => setState(() => a = (a + 1).clamp(0, 7));
  void _decA() => setState(() => a = (a - 1).clamp(0, 7));
  void _incB() => setState(() => b = (b + 1).clamp(0, 7));
  void _decB() => setState(() => b = (b - 1).clamp(0, 7));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canFinish = Validators.isValidSetScore(a, b);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: RegisterStyles.surfaceHigh(scheme),
        borderRadius: RegisterStyles.cardRadius,
        boxShadow: [RegisterStyles.elevatedShadow(scheme)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Set atual', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterCard(label: 'Dupla A', value: a, onInc: _incA, onDec: _decA),
              const SizedBox(width: 16),
              _CounterCard(label: 'Dupla B', value: b, onInc: _incB, onDec: _decB),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 220,
            child: FilledButton.icon(
              onPressed: canFinish
                  ? () {
                      HapticFeedback.selectionClick();
                      widget.onFinalizeSet(a, b);
                    }
                  : null,
              icon: const Icon(Icons.flag_circle),
              label: const Text('Finalizar Set'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const _CounterCard({
    required this.label,
    required this.value,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Flexible(
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: RegisterStyles.cardRadius,
          boxShadow: [RegisterStyles.elevatedShadow(scheme)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 28,
                    onPressed: onDec,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$value',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    iconSize: 28,
                    onPressed: onInc,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}