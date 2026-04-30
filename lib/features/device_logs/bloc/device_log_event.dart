import 'package:equatable/equatable.dart';

abstract class DeviceLogEvent extends Equatable {
  const DeviceLogEvent();

  @override
  List<Object?> get props => [];
}

class DeviceLogsFetchRequested extends DeviceLogEvent {
  final int? lavvaggioId;
  const DeviceLogsFetchRequested({this.lavvaggioId});

  @override
  List<Object?> get props => [lavvaggioId];
}

class DeviceLogsRefreshRequested extends DeviceLogEvent {
  final int? lavvaggioId;
  const DeviceLogsRefreshRequested({this.lavvaggioId});

  @override
  List<Object?> get props => [lavvaggioId];
}
