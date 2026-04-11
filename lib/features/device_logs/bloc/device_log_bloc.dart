import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/repositories/device_log_repository.dart';
import 'device_log_event.dart';
import 'device_log_state.dart';

class DeviceLogBloc extends Bloc<DeviceLogEvent, DeviceLogState> {
  final DeviceLogRepository _repository;

  DeviceLogBloc({required DeviceLogRepository repository})
      : _repository = repository,
        super(const DeviceLogsInitial()) {
    on<DeviceLogsFetchRequested>(_onFetch);
    on<DeviceLogsRefreshRequested>(_onRefresh);
  }

  Future<void> _onFetch(
    DeviceLogsFetchRequested event,
    Emitter<DeviceLogState> emit,
  ) async {
    emit(const DeviceLogsLoading());
    try {
      final result = await _repository.fetchLogs(
        lavvaggioId: event.lavvaggioId,
        page:        1,
        perPage:     25,
      );
      emit(DeviceLogsLoaded(
        result.data,
        result.meta,
        hasMore: result.meta.hasNextPage,
      ));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to load device logs';
      emit(DeviceLogsError(msg));
    } catch (_) {
      emit(const DeviceLogsError('An unexpected error occurred'));
    }
  }

  Future<void> _onRefresh(
    DeviceLogsRefreshRequested event,
    Emitter<DeviceLogState> emit,
  ) async {
    try {
      final result = await _repository.fetchLogs(
        lavvaggioId: event.lavvaggioId,
        page:        1,
        perPage:     25,
      );
      emit(DeviceLogsLoaded(
        result.data,
        result.meta,
        hasMore: result.meta.hasNextPage,
      ));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to load device logs';
      emit(DeviceLogsError(msg));
    } catch (_) {}
  }
}
