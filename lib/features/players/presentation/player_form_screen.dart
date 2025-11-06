import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodel/player_viewmodel.dart';

class PlayerFormScreen extends StatefulWidget {
  const PlayerFormScreen({super.key});

  @override
  State<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends State<PlayerFormScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlayerViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Jogador')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Digite o nome do jogador',
                  prefixIcon: Icon(Icons.person),
                ),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Informe um nome válido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: vm.loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        HapticFeedback.selectionClick();
                        final ok = await vm.addPlayer(_controller.text);
                        if (!context.mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        if (ok) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Jogador salvo')),
                          );
                          Navigator.of(context).pop();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                vm.errorMessage ?? 'Erro ao salvar',
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.save),
                label: vm.loading
                    ? const Text('Salvando...')
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
