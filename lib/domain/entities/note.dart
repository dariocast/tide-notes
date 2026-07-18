import 'package:equatable/equatable.dart';

final class Note extends Equatable {
  const Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.surfacedAt,
    required this.rescueCount,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime surfacedAt;
  final int rescueCount;

  Note copyWith({
    String? content,
    DateTime? updatedAt,
    DateTime? surfacedAt,
    int? rescueCount,
  }) => Note(
    id: id,
    content: content ?? this.content,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    surfacedAt: surfacedAt ?? this.surfacedAt,
    rescueCount: rescueCount ?? this.rescueCount,
  );

  @override
  List<Object> get props => [
    id,
    content,
    createdAt,
    updatedAt,
    surfacedAt,
    rescueCount,
  ];
}
