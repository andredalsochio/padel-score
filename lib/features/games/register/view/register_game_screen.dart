import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/register_styles.dart';
import '../helpers/validators.dart';
import '../viewmodels/register_game_view_model.dart';
import '../widgets/actions_bar.dart';
import '../widgets/add_player_sheet.dart';
import '../widgets/players_section.dart';
import '../widgets/set_card.dart';
import '../widgets/sets_summary.dart';
import '../widgets/game_summary_card.dart';

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
                  // Players
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: RegisterStyles.surfaceHigh(scheme),
                      borderRadius: RegisterStyles.cardRadius,
                      boxShadow: [RegisterStyles.elevatedShadow(scheme)],
                    ),
                    padding: RegisterStyles.sectionPadding,
                    child: PlayersSection(
                      players: vm.assignedPlayers,
                      onAddPlayer: () async {
                        HapticFeedback.selectionClick();
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AddPlayerSheet(
                            onSearch: vm.searchPlayers,
                            onCreate: vm.createPlayer,
                            onSelect: (p) => vm.addPlayerToGame(p),
                          ),
                        );
                      },
                      onRemovePlayer: (id) {
                        HapticFeedback.lightImpact();
                        vm.removePlayerFromGame(id);
                      },
                      onSetTeam: (id, t) {
                        HapticFeedback.selectionClick();
                        vm.setTeam(id, t);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Scores
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: RegisterStyles.surfaceHigh(scheme),
                      borderRadius: RegisterStyles.cardRadius,
                      boxShadow: [RegisterStyles.elevatedShadow(scheme)],
                    ),
                    padding: RegisterStyles.sectionPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Placar',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (vm.assignedPlayers.length < 4) ...[
                          MaterialBanner(
                            content: const Text(
                              'Cadastre e selecione pelo menos 4 jogadores para definir o placar.',
                            ),
                            leading: const Icon(Icons.warning_amber_outlined),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  HapticFeedback.selectionClick();
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => AddPlayerSheet(
                                      onSearch: vm.searchPlayers,
                                      onCreate: vm.createPlayer,
                                      onSelect: (p) => vm.addPlayerToGame(p),
                                    ),
                                  );
                                },
                                child: const Text('Adicionar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeOut,
                          child: Builder(
                            key: ValueKey(_activeSet),
                            builder: (context) {
                              final initialScore = vm.sets[_activeSet];
                              // Preload per-set assignments
                              vm.ensureAssignmentLoaded(_activeSet);
                              return Column(
                                children: [
                                  // One active set card
                                  IgnorePointer(
                                    ignoring: vm.assignedPlayers.length < 4,
                                    child: Opacity(
                                      opacity: vm.assignedPlayers.length < 4
                                          ? 0.5
                                          : 1.0,
                                      child: SetCard(
                                        setIndex: _activeSet,
                                        initial: initialScore,
                                        onConfirm: (t1, t2) {
                                          if (!Validators.isValidSetScore(
                                            t1,
                                            t2,
                                          ))
                                            return;
                                          vm.selectScore(_activeSet, t1, t2);
                                          HapticFeedback.lightImpact();
                                          if (_activeSet + 1 < vm.bestOf) {
                                            setState(() => _activeSet++);
                                          }
                                        },
                                        players: vm.assignedPlayers,
                                        assignment: vm.assignmentForSet(
                                          _activeSet,
                                        ),
                                        onSetPlayerTeam: (pid, team) =>
                                            vm.setTeamForSet(
                                              _activeSet,
                                              pid,
                                              team,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Chips summary of saved sets
                                  SetsSummary(sets: vm.sets),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (vm.sets.length >= vm.bestOf)
                          GameSummaryCard(
                            sets: vm.sets,
                            assignments: vm.setAssignments,
                            totalPlayers: vm.assignedPlayers.length,
                            onSaveGame: () async {
                              HapticFeedback.heavyImpact();
                              await vm.saveGame();
                              if (context.mounted) Navigator.of(context).pop();
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ActionsBar(
                    canSave: vm.canSaveGame,
                    saving: vm.saving,
                    deleting: vm.deleting,
                    onSave: () async {
                      HapticFeedback.heavyImpact();
                      await vm.saveGame();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    onDelete: () async {
                      HapticFeedback.vibrate();
                      await vm.deleteGame();
                      if (context.mounted) Navigator.of(context).pop();
                    },
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
