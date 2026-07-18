import 'package:equatable/equatable.dart';

final class TideFailure extends Equatable {
  const TideFailure({required this.message, this.retryable = false});

  final String message;
  final bool retryable;

  @override
  List<Object> get props => [message, retryable];
}
