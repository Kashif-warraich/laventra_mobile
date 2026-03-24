import 'package:equatable/equatable.dart';
import '../data/models/event_model.dart';
import '../../../../core/models/pagination_meta.dart';

abstract class EventState extends Equatable {
  const EventState();

  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {
  const EventInitial();
}

class EventLoading extends EventState {
  const EventLoading();
}

class EventsLoaded extends EventState {
  final List<EventModel> events;
  final PaginationMeta   meta;
  const EventsLoaded(this.events, this.meta);

  @override
  List<Object?> get props => [events, meta];
}

class EventError extends EventState {
  final String message;
  const EventError(this.message);

  @override
  List<Object?> get props => [message];
}
