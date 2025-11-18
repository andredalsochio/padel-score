import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/set_assignment.dart';
import '../viewmodels/register_game_view_model.dart';

class CollapsibleSetsList extends StatelessWidget {
  final Map<int, SetScore> sets;
  const CollapsibleSetsList({super.key, required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return const SizedBox.shrink();
    }
    final items = sets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final e = items[i];
        return GestureDetector(
          onLongPress: () async {
            final action = await showModalBottomSheet<String>(
              context: context,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Editar set'),
                      onTap: () => Navigator.of(ctx).pop('edit'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Excluir set'),
                      onTap: () => Navigator.of(ctx).pop('delete'),
                    ),
                  ],
                ),
              ),
            );
            if (!context.mounted) return;
            final vm = context.read<RegisterGameViewModel>();
            if (action == 'delete') {
              vm.removeSet(e.key);
              return;
            }
            if (action == 'edit') {
              int a = e.value.team1;
              int b = e.value.team2;
              await showDialog<void>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: Text('Set ${e.key + 1}'),
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(onPressed: () { if (a > 0) a--; }, icon: const Icon(Icons.remove_circle_outline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('$a', style: Theme.of(ctx).textTheme.headlineMedium),
                        ),
                        IconButton(onPressed: () { if (a < 7) a++; }, icon: const Icon(Icons.add_circle_outline)),
                        const SizedBox(width: 24),
                        IconButton(onPressed: () { if (b > 0) b--; }, icon: const Icon(Icons.remove_circle_outline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('$b', style: Theme.of(ctx).textTheme.headlineMedium),
                        ),
                        IconButton(onPressed: () { if (b < 7) b++; }, icon: const Icon(Icons.add_circle_outline)),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                      FilledButton(onPressed: () { vm.selectScore(e.key, a, b); Navigator.of(ctx).pop(); }, child: const Text('Salvar')),
                    ],
                  );
                },
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListTile(
              title: Text('Set ${e.key + 1} — ${e.value.team1} × ${e.value.team2}'),
              trailing: const Icon(Icons.more_horiz),
            ),
          ),
        );
      },
    );
  }
}