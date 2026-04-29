import 'package:equatable/equatable.dart';

abstract class DeviceEvent extends Equatable {
  const DeviceEvent();
  @override
  List<Object?> get props => [];
}

class DevicesLoadRequested extends DeviceEvent {
  final int?    lavvaggioId;
  final String? status;       // 'online' | 'offline'
  final String? deviceType;   // 'mini_pc' | 'camera'

  const DevicesLoadRequested({this.lavvaggioId, this.status, this.deviceType});

  @override
  List<Object?> get props => [lavvaggioId, status, deviceType];
}

class DevicesRefreshRequested extends DeviceEvent {
  final int?    lavvaggioId;
  final String? status;
  final String? deviceType;

  const DevicesRefreshRequested({this.lavvaggioId, this.status, this.deviceType});

  @override
  List<Object?> get props => [lavvaggioId, status, deviceType];
}
