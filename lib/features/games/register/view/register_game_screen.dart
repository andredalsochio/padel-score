import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/register_styles.dart';
import '../helpers/validators.dart';
import '../viewmodels/register_game_view_model.dart';
import '../widgets/actions_bar.dart';
import '../models/patota_item.dart';
import '../widgets/draggable_player_chip.dart';
import '../widgets/dupla_drop_card.dart';
import '../widgets/current_set_counter.dart';
import '../widgets/collapsible_sets_list.dart';
import '../widgets/add_player_sheet.dart';
import '../../../patotas/view/patotas_management_screen.dart';
import 'match_summary_screen.dart';

class RegisterGameScreen extends StatefulWidget {
  const RegisterGameScreen({super.key});

  @override
  State<RegisterGameScreen> createState() => _RegisterGameScreenState();
}

class _RegisterGameScreenState extends State<RegisterGameScreen> {
  int _activeSet = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider(
      create: (_) =>
          RegisterGameViewModel(Supabase.instance.client)..startDraft(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar Jogo')),
        body: Consumer<RegisterGameViewModel>(
          builder: (context, vm, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patotas inline chips + create button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: RegisterStyles.surfaceHigh(scheme),
                      borderRadius: RegisterStyles.cardRadius,
                      boxShadow: [RegisterStyles.elevatedShadow(scheme)],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patotas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final route = MaterialPageRoute(
                                  builder: (_) =>
                                      const PatotasManagementScreen(),
                                );
                                await Navigator.of(context).push(route);
                                setState(() {});
                              },
                              icon: const Icon(Icons.group_add_outlined),
                              label: const Text('Gerenciar patotas'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<PatotaItem>>(
                          future: context
                              .read<RegisterGameViewModel>()
                              .listPatotas(),
                          builder: (context, snapshot) {
                            final patotas =
                                snapshot.data ?? const <PatotaItem>[];
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (patotas.isEmpty) {
                              return Text(
                                'Nenhuma patota encontrada. Crie uma para começar.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: patotas.map((p) {
                                return ActionChip(
                                  avatar: CircleAvatar(
                                    backgroundColor: scheme.primaryContainer,
                                    foregroundColor: scheme.onPrimaryContainer,
                                    child: Text(
                                      p.name.isNotEmpty
                                          ? p.name[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  label: Text(p.name),
                                  onPressed: () {
                                    final vm = context
                                        .read<RegisterGameViewModel>();
                                    vm.selectPatota(p);
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Players as draggable chips (appears when patota selecionada)
                  DragTarget<String>(
                    onWillAcceptWithDetails: (_) => true,
                    onAcceptWithDetails: (details) {
                      final vm = context.read<RegisterGameViewModel>();
                      vm.setTeam(details.data, null);
                    },
                    builder: (context, candidates, rejects) {
                      final highlight = candidates.isNotEmpty;
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: highlight
                              ? scheme.surfaceContainerHigh
                              : RegisterStyles.surfaceHigh(scheme),
                          borderRadius: RegisterStyles.cardRadius,
                          boxShadow: [RegisterStyles.elevatedShadow(scheme)],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jogadores',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final vm = context
                                      .read<RegisterGameViewModel>();
                                  await showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (ctx) => AddPlayerSheet(
                                      onSearch: vm.searchPlayers,
                                      onCreate: vm.createPlayer,
                                      onSelect: (player) =>
                                          vm.addPlayerToGame(player),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Adicionar jogador'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: vm.assignedPlayers
                                  .map(
                                    (p) => DraggablePlayerChip(
                                      playerId: p.id,
                                      name: p.name,
                                      team: p.team,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Dupla areas
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DuplaDropCard(
                          title: 'Dupla A',
                          teamNumber: 1,
                          players: vm.assignedPlayers
                              .where((p) => p.team == 1)
                              .toList(),
                          onAcceptPlayer: (pid) => vm.setTeam(pid, 1),
                          onReset: vm.resetTeams,
                          onRemove: (pid) => vm.setTeam(pid, null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DuplaDropCard(
                          title: 'Dupla B',
                          teamNumber: 2,
                          players: vm.assignedPlayers
                              .where((p) => p.team == 2)
                              .toList(),
                          onAcceptPlayer: (pid) => vm.setTeam(pid, 2),
                          onReset: vm.resetTeams,
                          onRemove: (pid) => vm.setTeam(pid, null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Scoreboard current set
                  CurrentSetCounter(
                    setIndex: _activeSet,
                    onFinalizeSet: (t1, t2) {
                      if (!Validators.isValidSetScore(t1, t2)) return;
                      // Materializa a composição do set a partir das equipes atuais
                      vm.applyTeamsToSet(_activeSet);
                      vm.selectScore(_activeSet, t1, t2);
                      HapticFeedback.lightImpact();
                      if (_activeSet + 1 < vm.bestOf) {
                        setState(() => _activeSet++);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  CollapsibleSetsList(sets: vm.sets),
                  const SizedBox(height: 80), // spacing above floating bar
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Consumer<RegisterGameViewModel>(
          builder: (context, vm, _) {
            final visible = vm.hasProgressTeams;
            return AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: visible ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                opacity: visible ? 1 : 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: ActionsBar(
                    canSave: vm.canSaveGame,
                    saving: vm.saving,
                    deleting: vm.deleting,
                    onSave: () async {
                      HapticFeedback.heavyImpact();
                      final vm = context.read<RegisterGameViewModel>();
                      debugPrint(
                        "[RegisterSave] UI onSave tapped gameId=${vm.gameId} assignedPlayers=${vm.assignedPlayers.map((p) => {"id": p.id, "name": p.name, "team": p.team}).toList()} sets=${vm.sets.entries.map((e) => {"index": e.key, "t1": e.value.team1, "t2": e.value.team2}).toList()} assignments=${vm.setAssignments.map((k, v) => MapEntry(k, v.entries.map((e) => {"id": e.playerId, "team": e.team}).toList()))}",
                      );
                      await vm.saveGame();
                      await vm.updateRankingForGame();
                      if (context.mounted && vm.gameId != null) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MatchSummaryScreen(gameId: vm.gameId!),
                          ),
                        );
                      }
                    },
                    onDelete: () async {
                      HapticFeedback.vibrate();
                      await vm.deleteGame();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
