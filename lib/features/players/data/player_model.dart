import 'package:flutter/foundation.dart';

@immutable
class PlayerModel {
  final String id;
  final String name;
  final String createdBy;

  const PlayerModel({required this.id, required this.name, required this.createdBy});

  factory PlayerModel.fromMap(Map<String, dynamic> m) => PlayerModel(
        id: m['id'] as String,
        name: m['name'] as String,
        createdBy: m['created_by'] as String,
      );

  static Map<String, dynamic> toInsert({required String name, required String createdBy}) => {
        'name': name,
        'created_by': createdBy,
      };
}