import 'package:flutter/material.dart';
import '../models/set_assignment.dart';
import 'dupla_player_chip.dart';

class DuplaDropCard extends StatelessWidget {
  final String title;
  final int teamNumber;
  final List<AssignedPlayer> players;
  final void Function(String playerId) onAcceptPlayer;
  final VoidCallback onReset;
  final void Function(String playerId) onRemove;
  const DuplaDropCard({super.key, required this.title, required this.teamNumber, required this.players, required this.onAcceptPlayer, required this.onReset, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = teamNumber == 1 ? scheme.primary : scheme.tertiary;
    final pillBg = teamNumber == 1 ? scheme.primaryContainer : scheme.tertiaryContainer;
    final pillOn = teamNumber == 1 ? scheme.onPrimaryContainer : scheme.onTertiaryContainer;
    const double cardHeight = 200;
    final isComplete = players.length >= 2;
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => players.length < 2,
      onAcceptWithDetails: (d) => onAcceptPlayer(d.data),
      builder: (context, candidates, rejects) {
        final hover = candidates.isNotEmpty;
        return SizedBox(
          height: cardHeight,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      (hover ? accent : scheme.surfaceContainerHigh).withValues(alpha: 0.18),
                      (hover ? accent : scheme.surfaceContainerHigh).withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: scheme.shadow.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 10)),
                  ],
                  border: Border.all(color: hover ? accent : scheme.outlineVariant),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(14)),
                          child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: pillOn)),
                        ),
                        const Spacer(),
                        IconButton(onPressed: onReset, icon: const Icon(Icons.refresh)),
                        if (isComplete) Icon(Icons.check_circle, color: accent),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: players.isEmpty
                            ? Center(child: Icon(Icons.person_add_alt_1, color: accent))
                            : SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: players
                                      .map((p) => DuplaPlayerChip(
                                            key: ValueKey('${p.id}-${p.team}'),
                                            playerId: p.id,
                                            name: p.name,
                                            team: p.team,
                                            onRemove: () => onRemove(p.id),
                                          ))
                                      .toList(),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}