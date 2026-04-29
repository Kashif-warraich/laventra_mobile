import 'package:equatable/equatable.dart';
import '../data/models/report_model.dart';
import '../../../../core/models/pagination_meta.dart';

abstract class ReportState extends Equatable {
  const ReportState();
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState { const ReportInitial(); }
class ReportLoading extends ReportState { const ReportLoading(); }

class ReportsLoaded extends ReportState {
  final List<ReportModel> reports;
  final PaginationMeta    meta;
  /// Set when an inline action (create/delete) succeeded — the UI can show
  /// a one-shot toast then keep using the same loaded list.
  final String? flashMessage;

  const ReportsLoaded(this.reports, this.meta, {this.flashMessage});

  ReportsLoaded copyWith({List<ReportModel>? reports, PaginationMeta? meta, String? flashMessage}) =>
      ReportsLoaded(reports ?? this.reports, meta ?? this.meta, flashMessage: flashMessage);

  @override
  List<Object?> get props => [reports, meta, flashMessage];
}

class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
  @override
  List<Object?> get props => [message];
}
