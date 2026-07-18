import 'package:equatable/equatable.dart';

final class RescueReceipt extends Equatable {
  const RescueReceipt({
    required this.noteId,
    required this.previousSurfacedAt,
    required this.previousRescueCount,
    required this.rescuedSurfacedAt,
  });

  final String noteId;
  final DateTime previousSurfacedAt;
  final int previousRescueCount;
  final DateTime rescuedSurfacedAt;

  @override
  List<Object> get props => [
    noteId,
    previousSurfacedAt,
    previousRescueCount,
    rescuedSurfacedAt,
  ];
}
