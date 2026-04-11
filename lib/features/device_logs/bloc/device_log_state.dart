import 'package:equatable/equatable.dart';
import '../data/models/device_log_model.dart';
import '../../../../core/models/pagination_meta.dart';

abstract class DeviceLogState extends Equatable {
  const DeviceLogState();

  @override
  List<Object?> get props => [];
}

class DeviceLogsInitial extends DeviceLogState {
  const DeviceLogsInitial();
}

class DeviceLogsLoading extends DeviceLogState {
  const DeviceLogsLoading();
}

class DeviceLogsLoaded extends DeviceLogState {
  final List<DeviceLogModel> logs;
  final bool                 hasMore;
  final PaginationMeta       meta;

  const DeviceLogsLoaded(this.logs, this.meta, {this.hasMore = false});

  @override
  List<Object?> get props => [logs, hasMore, meta];
}

class DeviceLogsError extends DeviceLogState {
  final String message;
  const DeviceLogsError(this.message);

  @override
  List<Object?> get props => [message];
}
