import 'package:flutter/material.dart';
import 'player_card.dart';

class PlayersSection extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final Future<void> Function() onAddPlayer;
  final void Function(String playerId) onRemovePlayer;
  final void Function(String playerId, int team) onSetTeam;

  const PlayersSection({
    super.key,
    required this.players,
    required this.onAddPlayer,
    required this.onRemovePlayer,
    required this.onSetTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Jogadores', style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
              onPressed: onAddPlayer,
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Adicionar jogador',
            )
          ],
        ),
        const SizedBox(height: 8),
        if (players.isEmpty) const Text('Adicione pelo menos 2 jogadores.'),
        ...players.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PlayerCard(
                name: p['name'] as String,
                team: p['team'] as int?,
                onRemove: () => onRemovePlayer(p['id'] as String),
                onSetTeam: (t) => onSetTeam(p['id'] as String, t),
              ),
            )),
      ],
    );
  }
}