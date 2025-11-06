import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodel/player_viewmodel.dart';

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider(
      create: (_) => PlayerViewModel(Supabase.instance.client),
      child: Scaffold(
        appBar: AppBar(title: const Text('Jogadores')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.push('/players/new');
          },
          label: const Text('Adicionar'),
          icon: const Icon(Icons.person_add),
        ),
        body: Consumer<PlayerViewModel>(
          builder: (context, vm, _) {
            if (vm.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final players = vm.players;
            return RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!vm.minPlayersMet)
                    MaterialBanner(
                      backgroundColor: scheme.surfaceContainerLow,
                      content: const Text(
                        'Cadastre pelo menos 4 jogadores para iniciar partidas.',
                      ),
                      leadingPadding: const EdgeInsets.only(right: 8),
                      leading: const Icon(Icons.info_outline),
                      actions: [
                        TextButton(
                          onPressed: () => context.push('/players/new'),
                          child: const Text('Adicionar'),
                        ),
                      ],
                    ),
                  if (players.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.group,
                            size: 48,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum jogador cadastrado ainda',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toque em Adicionar para criar seu primeiro jogador.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...players.map(
                      (p) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(p.name),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
