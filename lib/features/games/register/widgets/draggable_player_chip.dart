import 'package:flutter/material.dart';
import '../helpers/register_styles.dart';

class DraggablePlayerChip extends StatelessWidget {
  final String playerId;
  final String name;
  final int? team; // current assignment
  const DraggablePlayerChip({
    super.key,
    required this.playerId,
    required this.name,
    this.team,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final assignedColor = team == null
        ? scheme.surfaceContainerLow
        : (team == 1 ? scheme.primaryContainer : scheme.tertiaryContainer);
    final onAssignedColor = team == null
        ? scheme.onSurface
        : (team == 1 ? scheme.onPrimaryContainer : scheme.onTertiaryContainer);
    return LongPressDraggable<String>(
      data: playerId,
      feedback: Material(
        color: assignedColor,
        borderRadius: RegisterStyles.cardRadius,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(name, style: TextStyle(color: onAssignedColor)),
        ),
      ),
      child: Chip(
        label: Text(name),
        backgroundColor: assignedColor,
        labelStyle: TextStyle(color: onAssignedColor),
      ),
    );
  }
}