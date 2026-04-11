import 'package:equatable/equatable.dart';

class DeviceLogModel extends Equatable {
  final int      id;
  final int?     deviceId;
  final String?  deviceSerial;
  final int      lavvaggioId;
  final String?  lavvaggioName;
  final String   eventType; // 'online' or 'offline'
  final String?  message;
  final DateTime occurredAt;

  const DeviceLogModel({
    required this.id,
    this.deviceId,
    this.deviceSerial,
    required this.lavvaggioId,
    this.lavvaggioName,
    required this.eventType,
    this.message,
    required this.occurredAt,
  });

  bool get isOnline  => eventType == 'online';
  bool get isOffline => eventType == 'offline';

  String get formattedTime {
    final h = occurredAt.hour.toString().padLeft(2, '0');
    final m = occurredAt.minute.toString().padLeft(2, '0');
    final s = occurredAt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formattedDate =>
      '${occurredAt.day.toString().padLeft(2, '0')}/'
      '${occurredAt.month.toString().padLeft(2, '0')}/'
      '${occurredAt.year}';

  factory DeviceLogModel.fromJson(Map<String, dynamic> json) => DeviceLogModel(
        id:             json['id']            as int,
        deviceId:       json['device_id']     as int?,
        deviceSerial:   json['device_serial'] as String?,
        lavvaggioId:    json['lavvaggio_id']  as int,
        lavvaggioName:  json['lavvaggio_name'] as String?,
        eventType:      json['event_type']    as String,
        message:        json['message']       as String?,
        occurredAt:     DateTime.parse(json['occurred_at'] as String),
      );

  @override
  List<Object?> get props => [
        id, deviceId, deviceSerial, lavvaggioId, lavvaggioName,
        eventType, message, occurredAt,
      ];
}
