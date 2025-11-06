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
import '../widgets/team_drop_area.dart';
import '../widgets/current_set_counter.dart';
import '../widgets/collapsible_sets_list.dart';
import '../widgets/add_player_sheet.dart';

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
                              Text('Patotas', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      // Capture dependências antes do primeiro await para evitar lint de BuildContext
                                      final messenger = ScaffoldMessenger.of(context);
                                      final vm = context.read<RegisterGameViewModel>();
                                      final controller = TextEditingController();
                                      PatotaItem? created;
                                      await showDialog<void>(
                                        context: context,
                                        builder: (dialogCtx) {
                                          final scheme = Theme.of(dialogCtx).colorScheme;
                                          final navigator = Navigator.of(dialogCtx);
                                          bool saving = false;
                                          return StatefulBuilder(
                                            builder: (dialogCtx, setState) => AlertDialog(
                                              title: const Text('Nova patota'),
                                              content: TextField(
                                                controller: controller,
                                                autofocus: true,
                                                decoration: const InputDecoration(
                                                  labelText: 'Nome da patota',
                                                  hintText: 'Ex.: Padel das 19h',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(dialogCtx).pop(),
                                                  child: const Text('Cancelar'),
                                                ),
                                                FilledButton(
                                                  onPressed: saving
                                                      ? null
                                                      : () async {
                                                          final name = controller.text.trim();
                                                          if (name.isEmpty) return;
                                                          setState(() => saving = true);
                                                          final p = await vm.createPatota(name: name);
                                                          setState(() => saving = false);
                                                          if (p == null) {
                                                            messenger.showSnackBar(
                                                              SnackBar(
                                                                content: const Text('Falha ao criar patota. Verifique sua conexão ou tente novamente.'),
                                                                backgroundColor: scheme.error,
                                                              ),
                                                            );
                                                            return;
                                                          }
                                                          created = p;
                                                          navigator.pop();
                                                        },
                                                  child: const Text('Salvar'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                      if (created != null) {
                                        await vm.selectPatota(created!);
                                      }
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                    label: const Text('Nova patota'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<List<PatotaItem>>(
                                future: context.read<RegisterGameViewModel>().listPatotas(),
                                builder: (context, snapshot) {
                                  final patotas = snapshot.data ?? const <PatotaItem>[];
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                                  }
                                  if (patotas.isEmpty) {
                                    return Text('Nenhuma patota encontrada. Crie uma para começar.', style: Theme.of(context).textTheme.bodyMedium);
                                  }
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: patotas.map((p) {
                                      return ActionChip(
                                        avatar: CircleAvatar(
                                          backgroundColor: scheme.primaryContainer,
                                          foregroundColor: scheme.onPrimaryContainer,
                                          child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                                        ),
                                        label: Text(p.name),
                                        onPressed: () {
                                          final vm = context.read<RegisterGameViewModel>();
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
                                'Jogadores',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final vm = context.read<RegisterGameViewModel>();
                                    await showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (ctx) => AddPlayerSheet(
                                        onSearch: vm.searchPlayers,
                                        onCreate: vm.createPlayer,
                                        onSelect: (player) => vm.addPlayerToGame(player),
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
                        ),
                        const SizedBox(height: 16),
                        // Team areas
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TeamDropArea(
                                title: 'Time A',
                                teamNumber: 1,
                                playerNames: vm.assignedPlayers
                                    .where((p) => p.team == 1)
                                    .map((p) => p.name)
                                    .toList(),
                                onAcceptPlayer: (pid) => vm.setTeam(pid, 1),
                                onReset: vm.resetTeams,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TeamDropArea(
                                title: 'Time B',
                                teamNumber: 2,
                                playerNames: vm.assignedPlayers
                                    .where((p) => p.team == 2)
                                    .map((p) => p.name)
                                    .toList(),
                                onAcceptPlayer: (pid) => vm.setTeam(pid, 2),
                                onReset: vm.resetTeams,
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
                    )
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
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withValues(alpha: 0.08),
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
                      await vm.saveGame();
                      if (context.mounted) Navigator.of(context).pop();
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
