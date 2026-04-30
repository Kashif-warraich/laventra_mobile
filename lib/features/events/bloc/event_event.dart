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
  final String? status;
  final String? search;

  const EventsLoadRequested({
    this.lavvaggioId,
    this.from,
    this.to,
    this.status,
    this.search,
  });

  @override
  List<Object?> get props => [lavvaggioId, from, to, status, search];
}

class EventsRefreshRequested extends EventEvent {
  final int?    lavvaggioId;
  final String? from;
  final String? to;
  final String? status;
  final String? search;

  const EventsRefreshRequested({
    this.lavvaggioId,
    this.from,
    this.to,
    this.status,
    this.search,
  });

  @override
  List<Object?> get props => [lavvaggioId, from, to, status, search];
}
