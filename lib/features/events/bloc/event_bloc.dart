import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/models/event_model.dart';
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
    on<EventCompleteRequested>(_onComplete);
  }

  Future<void> _onLoad(
      EventsLoadRequested event,
      Emitter<EventState> emit,
      ) async {
    emit(const EventLoading());
    try {
      final result = await _repository.getEvents(
        lavvaggioId: event.lavvaggioId,
        from:        event.from,
        to:          event.to,
        page:        1,
        perPage:     25,
      );
      emit(EventsLoaded(result.data, result.meta));
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
      final result = await _repository.getEvents(
        lavvaggioId: event.lavvaggioId,
        from:        event.from,
        to:          event.to,
        page:        1,
        perPage:     25,
      );
      emit(EventsLoaded(result.data, result.meta));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to load events';
      emit(EventError(msg));
    } catch (_) {}
  }

  Future<void> _onComplete(
      EventCompleteRequested event,
      Emitter<EventState> emit,
      ) async {
    // Capture previous events list and meta before transitioning
    final List<EventModel> previousEvents;
    switch (state) {
      case EventsLoaded s:
        previousEvents = s.events;
      case EventCompleted s:
        previousEvents = s.updatedEvents;
      default:
        previousEvents = const [];
    }

    emit(EventCompleting(event.eventId));

    try {
      final completedEvent = await _repository.completeEvent(event.eventId);

      // Replace the matching event in the list
      final updatedList = previousEvents.map((e) {
        return e.id == completedEvent.id ? completedEvent : e;
      }).toList();

      emit(EventCompleted(completedEvent, updatedList));

      await Future.delayed(const Duration(milliseconds: 1500));

      // After 1.5s, settle back into EventsLoaded with the updated list.
      // We need the meta from the original loaded state — re-fetch is not
      // needed; preserve meta from wherever we captured events above.
      // At this point state is EventCompleted, so we use the updatedList
      // directly. Meta is retrieved via a second snapshot captured here.
      if (state is EventCompleted) {
        // We cannot retrieve meta from EventCompleted (it doesn't carry it),
        // so we reload from the repository to get fresh meta + latest data.
        // Silently reload — no loading spinner.
        try {
          final refreshed = await _repository.getEvents(page: 1, perPage: 25);
          emit(EventsLoaded(refreshed.data, refreshed.meta));
        } catch (_) {
          // If refresh fails, stay in EventCompleted — UI still shows correct state.
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to complete event';
      emit(EventError(msg));
    } catch (_) {
      emit(const EventError('An unexpected error occurred'));
    }
  }
}
