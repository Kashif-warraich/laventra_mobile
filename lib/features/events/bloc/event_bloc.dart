import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/repositories/event_repository.dart';
import 'event_event.dart';
import 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository _repository;

  EventBloc({required EventRepository repository})
      : _repository = repository,
        super(const EventInitial()) {
    on<EventsLoadRequested>(_onLoad);
    on<EventsRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
      EventsLoadRequested event,
      Emitter<EventState> emit,
      ) async {
    emit(const EventLoading());
    try {
      final events = await _repository.getEvents(
        lavvaggioId: event.lavvaggioId,
        from:        event.from,
        to:          event.to,
      );
      emit(EventsLoaded(events));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to load events';
      emit(EventError(msg));
    } catch (_) {
      emit(const EventError('An unexpected error occurred'));
    }
  }

  Future<void> _onRefresh(
      EventsRefreshRequested event,
      Emitter<EventState> emit,
      ) async {
    try {
      final events = await _repository.getEvents(
        lavvaggioId: event.lavvaggioId,
        from:        event.from,
        to:          event.to,
      );
      emit(EventsLoaded(events));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to load events';
      emit(EventError(msg));
    } catch (_) {}
  }
}