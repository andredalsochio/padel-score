import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/patotas_view_model.dart';
import '../../players/data/player_model.dart';
import '../../games/register/models/patota_item.dart';

class PatotasManagementScreen extends StatelessWidget {
  const PatotasManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatotasViewModel(Supabase.instance.client)..refreshPatotas(),
      child: const _PatotasBody(),
    );
  }
}

class _PatotasBody extends StatelessWidget {
  const _PatotasBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<PatotasViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Patotas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePatotaDialog(context),
        label: const Text('Nova patota'),
        icon: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in vm.patotas)
                  GestureDetector(
                    onLongPress: () => _confirmDelete(context, p),
                    child: ChoiceChip(
                      label: Text(p.name),
                      avatar: CircleAvatar(child: Text(_initials(p.name))),
                      selected: vm.selected?.id == p.id,
                      onSelected: (selected) => selected ? vm.selectPatota(p) : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Jogadores da patota', style: theme.textTheme.titleMedium),
                const SizedBox(width: 12),
                if (vm.selected != null)
                  Row(
                    children: [
                      Chip(label: Text(vm.selected!.name)),
                      IconButton(
                        tooltip: 'Editar nome da patota',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditPatotaDialog(context, vm.selected!),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (vm.selected == null)
              Text('Selecione uma patota para gerenciar jogadores.',
                  style: theme.textTheme.bodyMedium)
            else
              Expanded(
                child: _PlayersList(
                  players: vm.players,
                  patota: vm.selected!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    final a = parts.isNotEmpty ? parts.first.characters.first : '';
    final b = parts.length > 1 ? parts[1].characters.first : '';
    return (a + b).toUpperCase();
  }

  Future<void> _showCreatePatotaDialog(BuildContext context) async {
    final vm = context.read<PatotasViewModel>();
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova patota'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nome da patota'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final created = await vm.createPatota(name);
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    created == null
                        ? 'Falha ao criar patota. Verifique conexão/RLS.'
                        : 'Patota "${created.name}" criada.',
                  ),
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PatotaItem p) async {
    final vm = context.read<PatotasViewModel>();
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir patota'),
            content: Text('Excluir "${p.name}"? Esta ação é permanente.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
            ],
          ),
        ) ??
        false;
    if (ok) await vm.deletePatota(p.id);
  }

  Future<void> _showEditPatotaDialog(BuildContext context, PatotaItem p) async {
    final vm = context.read<PatotasViewModel>();
    final controller = TextEditingController(text: p.name);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renomear patota'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Novo nome'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final ok = await vm.updatePatotaName(p.id, name);
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text(ok ? 'Patota renomeada.' : 'Falha ao renomear patota.')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _PlayersList extends StatelessWidget {
  final List<PlayerModel> players;
  final PatotaItem patota;
  const _PlayersList({required this.players, required this.patota});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PatotasViewModel>();
    return Column(
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: () => _showAddPlayersModal(context, patota.id),
              icon: const Icon(Icons.person_add),
              label: const Text('Adicionar jogador'),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: () => vm.refreshPatotas(),
              child: const Text('Atualizar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final player = players[i];
              return Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: CircleAvatar(child: Text(_initials(player.name))),
                  title: Text(player.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => vm.removePlayer(patota.id, player.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    final a = parts.isNotEmpty ? parts.first.characters.first : '';
    final b = parts.length > 1 ? parts[1].characters.first : '';
    return (a + b).toUpperCase();
  }

  Future<void> _showAddPlayersModal(BuildContext context, String patotaId) async {
    final vm = context.read<PatotasViewModel>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _SelectPlayersModal(patotaId: patotaId, viewModel: vm),
      ),
    );
  }
}

class _SelectPlayersModal extends StatefulWidget {
  final String patotaId;
  final PatotasViewModel viewModel;
  const _SelectPlayersModal({required this.patotaId, required this.viewModel});

  @override
  State<_SelectPlayersModal> createState() => _SelectPlayersModalState();
}

class _SelectPlayersModalState extends State<_SelectPlayersModal> {
  List<PlayerModel> allPlayers = [];
  final Set<String> selected = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.viewModel.listAllPlayers();
    setState(() {
      allPlayers = list;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Selecionar jogadores', style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: allPlayers.length,
                      itemBuilder: (_, i) {
                        final player = allPlayers[i];
                        final isSelected = selected.contains(player.id);
                        return CheckboxListTile(
                          title: Text(player.name),
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selected.add(player.id);
                              } else {
                                selected.remove(player.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              final ok = await widget.viewModel.addPlayers(
                                widget.patotaId,
                                selected.toList(),
                              );
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(content: Text(ok ? 'Jogadores vinculados.' : 'Falha ao vincular jogadores.')),
                              );
                            },
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}