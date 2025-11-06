import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerService {
  final SupabaseClient client;
  PlayerService(this.client);

  PostgrestQueryBuilder _table() => client.from('players');

  Future<List<Map<String, dynamic>>> listMine({String? query}) async {
    var q = _table().select('*').eq('created_by', client.auth.currentUser!.id);
    if (query != null && query.trim().isNotEmpty) {
      q = q.ilike('name', '%${query.trim()}%');
    }
    q = q..order('created_at');
    final res = await q;
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> create(String name) async {
    final res = await _table()
        .insert({'name': name, 'created_by': client.auth.currentUser!.id})
        .select('*')
        .single();
    return res;
  }

  Future<Map<String, dynamic>> updateName({
    required String id,
    required String name,
  }) async {
    final res = await _table()
        .update({'name': name})
        .eq('id', id)
        .eq('created_by', client.auth.currentUser!.id)
        .select('*')
        .single();
    return res;
  }

  Future<void> delete({required String id}) async {
    await _table()
        .delete()
        .eq('id', id)
        .eq('created_by', client.auth.currentUser!.id);
  }
}
