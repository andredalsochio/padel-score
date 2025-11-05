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
import '../widgets/scores_section.dart';

class RegisterGameScreen extends StatelessWidget {
  const RegisterGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider(
      create: (_) => RegisterGameViewModel(Supabase.instance.client)..startDraft(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrar Jogo'),
        ),
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
                    child: ScoresSection(
                      sets: vm.sets,
                      onSelect: (i, a, b) {
                        HapticFeedback.selectionClick();
                        if (Validators.isValidSetScore(a, b)) {
                          vm.selectScore(i, a, b);
                        }
                      },
                      onRemove: (i) {
                        HapticFeedback.lightImpact();
                        vm.removeSet(i);
                      },
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