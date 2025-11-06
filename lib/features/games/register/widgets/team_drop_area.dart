import 'package:flutter/material.dart';
import '../helpers/register_styles.dart';

class TeamDropArea extends StatelessWidget {
  final String title;
  final int teamNumber; // 1 or 2
  final List<String> playerNames; // preview of assigned players
  final void Function(String playerId) onAcceptPlayer;
  final VoidCallback onReset;

  const TeamDropArea({
    super.key,
    required this.title,
    required this.teamNumber,
    required this.playerNames,
    required this.onAcceptPlayer,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor =
        teamNumber == 1 ? scheme.primaryContainer : scheme.tertiaryContainer;
    final onBase = teamNumber == 1
        ? scheme.onPrimaryContainer
        : scheme.onTertiaryContainer;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => onAcceptPlayer(details.data),
      builder: (context, candidates, rejects) {
        final isHighlighted = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isHighlighted
                ? baseColor
                : scheme.surfaceContainerHighest,
            borderRadius: RegisterStyles.cardRadius,
            boxShadow: [RegisterStyles.elevatedShadow(scheme)],
            border: Border.all(
              color: isHighlighted ? baseColor : scheme.outline,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: isHighlighted ? onBase : null),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Resetar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (playerNames.isEmpty)
                Text(
                  'Arraste jogadores para cá',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: isHighlighted ? onBase : null),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: playerNames
                      .map(
                        (n) => Chip(
                          label: Text(n),
                          backgroundColor: isHighlighted ? baseColor : null,
                          labelStyle:
                              TextStyle(color: isHighlighted ? onBase : null),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}