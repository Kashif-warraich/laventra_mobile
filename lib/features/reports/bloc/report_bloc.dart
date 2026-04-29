import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/repositories/report_repository.dart';
import '../data/models/report_model.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _repository;

  ReportBloc({required ReportRepository repository})
      : _repository = repository,
        super(const ReportInitial()) {
    on<ReportsLoadRequested>(_onLoad);
    on<ReportsRefreshRequested>(_onRefresh);
    on<ReportCreateRequested>(_onCreate);
    on<ReportDeleteRequested>(_onDelete);
    on<ReportPollRequested>(_onPoll);
  }

  Future<void> _onLoad(ReportsLoadRequested e, Emitter<ReportState> emit) async {
    emit(const ReportLoading());
    try {
      final res = await _repository.getReports(lavvaggioId: e.lavvaggioId, format: e.format, status: e.status);
      emit(ReportsLoaded(res.data, res.meta));
    } on DioException catch (e) {
      emit(ReportError(_msg(e, 'Failed to load reports')));
    } catch (_) {
      emit(const ReportError('An unexpected error occurred'));
    }
  }

  Future<void> _onRefresh(ReportsRefreshRequested e, Emitter<ReportState> emit) async {
    try {
      final res = await _repository.getReports(lavvaggioId: e.lavvaggioId, format: e.format, status: e.status);
      emit(ReportsLoaded(res.data, res.meta));
    } on DioException catch (e) {
      emit(ReportError(_msg(e, 'Failed to refresh reports')));
    } catch (_) {}
  }

  Future<void> _onCreate(ReportCreateRequested e, Emitter<ReportState> emit) async {
    try {
      final created = await _repository.createReport(
        format:      e.format,
        lavvaggioId: e.lavvaggioId,
        dateFrom:    e.dateFrom,
        dateTo:      e.dateTo,
        name:        e.name,
      );
      // Optimistically prepend to the current list. Caller is expected to
      // poll this report's id until it flips to ready.
      final s = state;
      if (s is ReportsLoaded) {
        emit(s.copyWith(
          reports:      [created, ...s.reports],
          flashMessage: 'Generating report…',
        ));
      } else {
        // Fall back to a fresh load if we have no list yet.
        add(const ReportsLoadRequested());
      }
    } on DioException catch (e) {
      emit(ReportError(_msg(e, 'Failed to create report')));
    }
  }

  Future<void> _onDelete(ReportDeleteRequested e, Emitter<ReportState> emit) async {
    final s = state;
    try {
      await _repository.deleteReport(e.id);
      if (s is ReportsLoaded) {
        emit(s.copyWith(
          reports:      s.reports.where((r) => r.id != e.id).toList(),
          flashMessage: 'Report deleted',
        ));
      }
    } on DioException catch (e) {
      emit(ReportError(_msg(e, 'Failed to delete report')));
    }
  }

  Future<void> _onPoll(ReportPollRequested e, Emitter<ReportState> emit) async {
    final s = state;
    if (s is! ReportsLoaded) return;
    try {
      final fresh = await _repository.getReport(e.id);
      final next  = s.reports.map<ReportModel>((r) => r.id == e.id ? fresh : r).toList();
      emit(s.copyWith(reports: next));
    } catch (_) {
      // Polling errors are non-fatal — the next tick may succeed.
    }
  }

  String _msg(DioException e, String fallback) =>
      (e.response?.data?['errors']?[0] as String?) ?? fallback;
}
