import 'package:flutter/material.dart';
import '../helpers/register_styles.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final int? team; // 1 or 2
  final VoidCallback? onRemove;
  final ValueChanged<int>? onSetTeam;

  const PlayerCard({
    super.key,
    required this.name,
    this.team,
    this.onRemove,
    this.onSetTeam,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: RegisterStyles.surfaceHigh(scheme),
      borderRadius: RegisterStyles.cardRadius,
      child: InkWell(
        borderRadius: RegisterStyles.cardRadius,
        onTap: null,
        child: Padding(
          padding: RegisterStyles.cardPadding,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Time 1'),
                          selected: team == 1,
                          onSelected: onSetTeam == null ? null : (v) => onSetTeam!(1),
                        ),
                        ChoiceChip(
                          label: const Text('Time 2'),
                          selected: team == 2,
                          onSelected: onSetTeam == null ? null : (v) => onSetTeam!(2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }
}