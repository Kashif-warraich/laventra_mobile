import 'package:equatable/equatable.dart';
import '../data/models/device_model.dart';
import '../../../../core/models/pagination_meta.dart';

abstract class DeviceState extends Equatable {
  const DeviceState();
  @override
  List<Object?> get props => [];
}

class DeviceInitial extends DeviceState  { const DeviceInitial();  }
class DeviceLoading extends DeviceState  { const DeviceLoading();  }

class DevicesLoaded extends DeviceState {
  final List<DeviceModel> devices;
  final PaginationMeta    meta;
  const DevicesLoaded(this.devices, this.meta);
  @override
  List<Object?> get props => [devices, meta];
}

class DeviceError extends DeviceState {
  final String message;
  const DeviceError(this.message);
  @override
  List<Object?> get props => [message];
}
