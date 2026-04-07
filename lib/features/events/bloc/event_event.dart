import 'package:equatable/equatable.dart';

abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => [];
}

class EventsLoadRequested extends EventEvent {
  final int?    lavvaggioId;
  final String? from;
  final String? to;

  const EventsLoadRequested({
    this.lavvaggioId,
    this.from,
    this.to,
  });

  @override
  List<Object?> get props => [lavvaggioId, from, to];
}

class EventsRefreshRequested extends EventEvent {
  final int?    lavvaggioId;
  final String? from;
  final String? to;

  const EventsRefreshRequested({
    this.lavvaggioId,
    this.from,
    this.to,
  });

  @override
  List<Object?> get props => [lavvaggioId, from, to];
}
