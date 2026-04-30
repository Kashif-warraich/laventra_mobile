import 'package:equatable/equatable.dart';
import '../data/models/lavvaggio_model.dart';

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
  final LavvaggioModel?      current; // fallback when bloc state is the list (not detail)
  const LavvaggioUpdateRequested({
    required this.lavvaggioId,
    required this.data,
    this.current,
  });

  @override
  List<Object?> get props => [lavvaggioId, data, current];
}

class LavvaggioRefreshRequested extends LavvaggioEvent {
  const LavvaggioRefreshRequested();
}

class LavvaggioStatsLoadRequested extends LavvaggioEvent {
  final int       lavvaggioId;
  final DateTime? from;
  final DateTime? to;
  const LavvaggioStatsLoadRequested(this.lavvaggioId, {this.from, this.to});
  @override
  List<Object?> get props => [lavvaggioId, from, to];
}