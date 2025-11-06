import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/validators.dart';
import 'score_button.dart';

/// Displays one active set with two score buttons (Team A / Team B)
/// and a confirmation action.
class SetCard extends StatefulWidget {
  final int setIndex; // zero-based
  final Map<String, int>? initial;
  final void Function(int team1, int team2) onConfirm;

  const SetCard({
    super.key,
    required this.setIndex,
    this.initial,
    required this.onConfirm,
  });

  @override
  State<SetCard> createState() => _SetCardState();
}

class _SetCardState extends State<SetCard> {
  late int team1;
  late int team2;

  @override
  void initState() {
    super.initState();
    team1 = widget.initial?['team1'] ?? 0;
    team2 = widget.initial?['team2'] ?? 0;
  }

  void _cycleTeam1() {
    setState(() => team1 = (team1 + 1) % 8);
  }

  void _cycleTeam2() {
    setState(() => team2 = (team2 + 1) % 8);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = Validators.isValidSetScore(team1, team2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Set ${widget.setIndex + 1}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ScoreButton(
                label: 'Team A',
                score: team1,
                onTap: _cycleTeam1,
                highlighted: team1 >= team2 && team1 > 0,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: ScoreButton(
                label: 'Team B',
                score: team2,
                onTap: _cycleTeam2,
                highlighted: team2 >= team1 && team2 > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 180,
          child: FilledButton.icon(
            icon: const Icon(Icons.check_circle),
            onPressed: canSave
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onConfirm(team1, team2);
                  }
                : null,
            label: const Text('Salvar Set'),
          ),
        ),
      ],
    );
  }
}