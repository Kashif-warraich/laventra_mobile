import 'package:equatable/equatable.dart';

abstract class LavvaggioEvent extends Equatable {
  const LavvaggioEvent();

  @override
  List<Object?> get props => [];
}

class LavvaggiosLoadRequested extends LavvaggioEvent {
  const LavvaggiosLoadRequested();
}

class LavvaggioDetailLoadRequested extends LavvaggioEvent {
  final int lavvaggioId;
  const LavvaggioDetailLoadRequested(this.lavvaggioId);

  @override
  List<Object?> get props => [lavvaggioId];
}

class LavvaggioUpdateRequested extends LavvaggioEvent {
  final int                  lavvaggioId;
  final Map<String, dynamic> data;
  const LavvaggioUpdateRequested({
    required this.lavvaggioId,
    required this.data,
  });

  @override
  List<Object?> get props => [lavvaggioId, data];
}

class LavvaggioRefreshRequested extends LavvaggioEvent {
  const LavvaggioRefreshRequested();
}