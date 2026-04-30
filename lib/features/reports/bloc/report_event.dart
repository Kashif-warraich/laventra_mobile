import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

class ReportsLoadRequested extends ReportEvent {
  final int?    lavvaggioId;
  final String? format;
  final String? status;
  const ReportsLoadRequested({this.lavvaggioId, this.format, this.status});
  @override
  List<Object?> get props => [lavvaggioId, format, status];
}

class ReportsRefreshRequested extends ReportEvent {
  final int?    lavvaggioId;
  final String? format;
  final String? status;
  const ReportsRefreshRequested({this.lavvaggioId, this.format, this.status});
  @override
  List<Object?> get props => [lavvaggioId, format, status];
}

class ReportCreateRequested extends ReportEvent {
  final String   format;
  final int?     lavvaggioId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String?  name;
  const ReportCreateRequested({
    required this.format,
    this.lavvaggioId,
    this.dateFrom,
    this.dateTo,
    this.name,
  });
  @override
  List<Object?> get props => [format, lavvaggioId, dateFrom, dateTo, name];
}

class ReportDeleteRequested extends ReportEvent {
  final int id;
  const ReportDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

/// Re-fetches a single report so a generating row can flip to ready/failed
/// in the UI without reloading the whole page.
class ReportPollRequested extends ReportEvent {
  final int id;
  const ReportPollRequested(this.id);
  @override
  List<Object?> get props => [id];
}
