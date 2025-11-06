// Model simples para exibir patotas na UI de registro de jogo.

class PatotaItem {
  final String id;
  final String name;
  final String? avatarUrl;

  const PatotaItem({required this.id, required this.name, this.avatarUrl});

  factory PatotaItem.fromMap(Map<String, dynamic> map) {
    return PatotaItem(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  @override
  String toString() => 'PatotaItem($id, $name)';
}