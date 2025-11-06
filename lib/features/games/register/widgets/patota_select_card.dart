// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../helpers/register_styles.dart';
import '../models/patota_item.dart';
import '../viewmodels/register_game_view_model.dart';
import 'add_player_sheet.dart';

class PatotaSelectCard extends StatefulWidget {
  const PatotaSelectCard({super.key});

  @override
  State<PatotaSelectCard> createState() => _PatotaSelectCardState();
}

class _PatotaSelectCardState extends State<PatotaSelectCard> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: RegisterStyles.surfaceHigh(scheme),
        borderRadius: RegisterStyles.cardRadius,
        boxShadow: [RegisterStyles.elevatedShadow(scheme)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group, size: 48, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            'Selecionar Patota',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Toque para escolher uma patota e organizar os jogadores.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () async {
              HapticFeedback.selectionClick();
              final vm = context.read<RegisterGameViewModel>();
              final patotas = await vm.listPatotas();
              if (!mounted) return; // garante que o contexto ainda está válido antes de abrir o modal
              final PatotaItem? selected = await showModalBottomSheet<PatotaItem?>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => _PatotaBottomSheet(patotas: patotas, vm: vm),
              );
              if (!mounted) return; // evita usar context após await se widget foi descartado
              if (selected != null) {
                await vm.selectPatota(selected);
                if (!mounted) return;
                // Se a patota estiver vazia, oferece adicionar jogadores à patota
                if (vm.assignedPlayers.isEmpty) {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => _AddPlayersToPatotaSheet(patota: selected, vm: vm),
                  );
                }
              }
            },
            child: const Text('Escolher'),
          ),
        ],
      ),
    );
  }
}

class _PatotaBottomSheet extends StatelessWidget {
  final List<PatotaItem> patotas;
  final RegisterGameViewModel vm;
  const _PatotaBottomSheet({required this.patotas, required this.vm});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patotas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (patotas.isEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: RegisterStyles.cardRadius,
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nenhuma patota encontrada. Você pode criar uma nova e adicionar jogadores manualmente.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final controller = TextEditingController();
                  PatotaItem? created;
                  await showDialog<void>(
                    context: context,
                    builder: (dialogCtx) {
                      final scheme = Theme.of(dialogCtx).colorScheme;
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
                                      Navigator.of(dialogCtx).pop();
                                    },
                              child: const Text('Salvar'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  if (created != null) {
                    // Fecha o bottom sheet retornando a patota criada
                    navigator.pop(created);
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Criar nova patota'),
              ),
            ] else ...[
              Wrap(
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
                    onPressed: () => Navigator.of(context).pop(p),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddPlayersToPatotaSheet extends StatelessWidget {
  final PatotaItem patota;
  final RegisterGameViewModel vm;
  const _AddPlayersToPatotaSheet({required this.patota, required this.vm});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adicionar jogadores à patota', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Patota: ${patota.name}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Flexible(
              child: AddPlayerSheet(
                onSearch: vm.searchPlayers,
                onCreate: vm.createPlayer,
                onSelect: (player) async {
                  final ok = await vm.addPlayerToPatota(patota.id, player.id);
                  if (!ok) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text('Não foi possível adicionar o jogador à patota.'),
                        backgroundColor: scheme.error,
                      ),
                    );
                    return;
                  }
                  await vm.selectPatota(patota); // recarrega lista de jogadores da patota
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}