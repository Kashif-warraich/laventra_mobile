import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/repositories/device_repository.dart';
import 'device_event.dart';
import 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceRepository _repository;

  DeviceBloc({required DeviceRepository repository})
      : _repository = repository,
        super(const DeviceInitial()) {
    on<DevicesLoadRequested>(_onLoad);
    on<DevicesRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(DevicesLoadRequested event, Emitter<DeviceState> emit) async {
    emit(const DeviceLoading());
    try {
      final result = await _repository.getDevices(
        lavvaggioId: event.lavvaggioId,
        status:      event.status,
        deviceType:  event.deviceType,
      );
      emit(DevicesLoaded(result.data, result.meta));
    } on DioException catch (e) {
      emit(DeviceError(_msg(e, 'Failed to load devices')));
    } catch (_) {
      emit(const DeviceError('An unexpected error occurred'));
    }
  }

  Future<void> _onRefresh(DevicesRefreshRequested event, Emitter<DeviceState> emit) async {
    try {
      final result = await _repository.getDevices(
        lavvaggioId: event.lavvaggioId,
        status:      event.status,
        deviceType:  event.deviceType,
      );
      emit(DevicesLoaded(result.data, result.meta));
    } on DioException catch (e) {
      emit(DeviceError(_msg(e, 'Failed to refresh devices')));
    } catch (_) {}
  }

  String _msg(DioException e, String fallback) =>
      (e.response?.data?['errors']?[0] as String?) ?? fallback;
}
