import 'package:flutter/material.dart';

class ActionsBar extends StatelessWidget {
  final bool canSave;
  final bool saving;
  final bool deleting;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const ActionsBar({
    super.key,
    required this.canSave,
    required this.saving,
    required this.deleting,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: (!saving && canSave) ? onSave : null,
            icon: const Icon(Icons.save_outlined),
            label: saving ? const Text('Salvando...') : const Text('Salvar jogo'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: deleting ? null : onDelete,
            icon: const Icon(Icons.delete_outline),
            label: deleting ? const Text('Excluindo...') : const Text('Excluir rascunho'),
          ),
        ),
      ],
    );
  }
}