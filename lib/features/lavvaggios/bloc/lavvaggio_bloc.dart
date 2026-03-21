import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/repositories/lavvaggio_repository.dart';
import 'lavvaggio_event.dart';
import 'lavvaggio_state.dart';

class LavvaggioBloc extends Bloc<LavvaggioEvent, LavvaggioState> {
  final LavvaggioRepository _repository;

  LavvaggioBloc({required LavvaggioRepository repository})
      : _repository = repository,
        super(const LavvaggioInitial()) {
    on<LavvaggiosLoadRequested>(_onLoad);
    on<LavvaggioDetailLoadRequested>(_onDetailLoad);
    on<LavvaggioUpdateRequested>(_onUpdate);
    on<LavvaggioRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
      LavvaggiosLoadRequested event,
      Emitter<LavvaggioState> emit,
      ) async {
    emit(const LavvaggioLoading());
    try {
      final list = await _repository.getLavvaggios();
      emit(LavvaggiosLoaded(list));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to load lavvaggios';
      emit(LavvaggioError(msg));
    } catch (_) {
      emit(const LavvaggioError('An unexpected error occurred'));
    }
  }

  Future<void> _onDetailLoad(
      LavvaggioDetailLoadRequested event,
      Emitter<LavvaggioState> emit,
      ) async {
    emit(const LavvaggioLoading());
    try {
      final lav = await _repository.getLavvaggio(event.lavvaggioId);
      emit(LavvaggioDetailLoaded(lav));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to load lavvaggio';
      emit(LavvaggioError(msg));
    } catch (_) {
      emit(const LavvaggioError('An unexpected error occurred'));
    }
  }

  Future<void> _onUpdate(
      LavvaggioUpdateRequested event,
      Emitter<LavvaggioState> emit,
      ) async {
    // Keep current lavvaggio for fallback
    final current = switch (state) {
      LavvaggioDetailLoaded  s => s.lavvaggio,
      LavvaggioUpdating      s => s.lavvaggio,
      LavvaggioUpdateSuccess s => s.lavvaggio,
      _                        => null,
    };
    if (current == null) return;

    emit(LavvaggioUpdating(current));
    try {
      final updated = await _repository.updateLavvaggio(
        event.lavvaggioId,
        event.data,
      );
      // Success then immediately settle into detail loaded
      emit(LavvaggioUpdateSuccess(updated));
      await Future.delayed(const Duration(milliseconds: 800));
      emit(LavvaggioDetailLoaded(updated));
    } on DioException catch (e) {
      final msg = e.response?.data?['errors']?[0] ?? 'Failed to update';
      emit(LavvaggioError(msg));
      await Future.delayed(const Duration(milliseconds: 800));
      emit(LavvaggioDetailLoaded(current));
    }
  }

  Future<void> _onRefresh(
      LavvaggioRefreshRequested event,
      Emitter<LavvaggioState> emit,
      ) async {
    try {
      final list = await _repository.getLavvaggios();
      emit(LavvaggiosLoaded(list));
    } catch (_) {}
  }
}