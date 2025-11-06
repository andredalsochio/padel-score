import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/validators.dart';
import '../models/set_assignment.dart';
import 'score_button.dart';

/// Displays one active set with two score buttons (Team A / Team B)
/// and a confirmation action.
class SetCard extends StatefulWidget {
  final int setIndex; // zero-based
  final SetScore? initial;
  final void Function(int team1, int team2) onConfirm;
  final List<AssignedPlayer> players;
  final SetAssignment? assignment; // per-set assignments
  final void Function(String playerId, int? team)
  onSetPlayerTeam; // persist immediately

  const SetCard({
    super.key,
    required this.setIndex,
    this.initial,
    required this.onConfirm,
    required this.players,
    required this.assignment,
    required this.onSetPlayerTeam,
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
    team1 = widget.initial?.team1 ?? 0;
    team2 = widget.initial?.team2 ?? 0;
  }

  void _cycleTeam1() {
    setState(() => team1 = (team1 + 1) % 8);
  }

  void _cycleTeam2() {
    setState(() => team2 = (team2 + 1) % 8);
  }

  @override
  Widget build(BuildContext context) {
    final totalPlayers = widget.players.length;
    final compOk = widget.assignment != null
        ? Validators.hasValidSetComposition(
            widget.assignment!,
            totalRegisteredPlayers: totalPlayers,
          )
        : false;
    final canSave = Validators.isValidSetScore(team1, team2) && compOk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Set ${widget.setIndex + 1}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Composição de times deste set',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        _PlayersSelector(
          players: widget.players,
          assignment: widget.assignment,
          onSetPlayerTeam: widget.onSetPlayerTeam,
        ),
        if (totalPlayers == 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Com 5 jogadores, exatamente 1 precisa descansar neste set.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
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

class _PlayersSelector extends StatelessWidget {
  final List<AssignedPlayer> players;
  final SetAssignment? assignment;
  final void Function(String playerId, int? team) onSetPlayerTeam;

  const _PlayersSelector({
    required this.players,
    required this.assignment,
    required this.onSetPlayerTeam,
  });

  int? _selectedTeamFor(String playerId) {
    final entry = assignment?.entries.firstWhere(
      (e) => e.playerId == playerId,
      orElse: () => SetPlayerEntry(playerId: playerId, team: null),
    );
    return entry?.team;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: players
          .map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(p.name)),
                  ChoiceChip(
                    label: const Text('Time 1'),
                    selected: _selectedTeamFor(p.id) == 1,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      onSetPlayerTeam(p.id, 1);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Time 2'),
                    selected: _selectedTeamFor(p.id) == 2,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      onSetPlayerTeam(p.id, 2);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Descansando'),
                    selected: _selectedTeamFor(p.id) == null,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      onSetPlayerTeam(p.id, null);
                    },
                    avatar: Icon(Icons.hotel, color: scheme.primary, size: 18),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
