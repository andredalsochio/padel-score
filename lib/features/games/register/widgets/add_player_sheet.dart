import 'package:flutter/material.dart';

class AddPlayerSheet extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function(String query) onSearch;
  final Future<Map<String, dynamic>> Function(String name) onCreate;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const AddPlayerSheet({
    super.key,
    required this.onSearch,
    required this.onCreate,
    required this.onSelect,
  });

  @override
  State<AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends State<AddPlayerSheet> {
  final TextEditingController _query = TextEditingController();
  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    final res = await widget.onSearch(_query.text);
    setState(() {
      _results = res;
      _loading = false;
    });
  }

  Future<void> _create() async {
    if (_query.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final created = await widget.onCreate(_query.text.trim());
    setState(() => _loading = false);
    widget.onSelect(created);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _query,
              decoration: const InputDecoration(
                labelText: 'Pesquisar ou criar jogador',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _runSearch(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _runSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Pesquisar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _create,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Criar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final p = _results[index];
                  return ListTile(
                    title: Text(p['name'] as String),
                    onTap: () {
                      widget.onSelect(p);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
