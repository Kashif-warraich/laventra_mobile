class EventModel {
  final int     id;
  final int     lavvaggioId;
  final int?    deviceId;
  final String  vehiclePlate;
  final String  vehicleType;
  final DateTime  startedAt;
  final DateTime? endedAt;
  final num?    durationSeconds;
  final String? lavvaggioName;
  final String? deviceSerial;

  const EventModel({
    required this.id,
    required this.lavvaggioId,
    this.deviceId,
    required this.vehiclePlate,
    required this.vehicleType,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.lavvaggioName,
    this.deviceSerial,
  });

  String get formattedDuration {
    if (durationSeconds == null) return '—';
    final totalSecs = durationSeconds!.toDouble();
    final m = (totalSecs / 60).floor();
    final s = (totalSecs % 60).round();
    return '${m}m ${s}s';
  }

  String get formattedStartTime {
    final h = startedAt.hour.toString().padLeft(2, '0');
    final m = startedAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedEndTime {
    if (endedAt == null) return '—';
    final h = endedAt!.hour.toString().padLeft(2, '0');
    final m = endedAt!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDate {
    return '${startedAt.day.toString().padLeft(2, '0')}/'
        '${startedAt.month.toString().padLeft(2, '0')}/'
        '${startedAt.year}';
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // API returns nested lavvaggio/device objects, not flat IDs
    final lavvaggio = json['lavvaggio'] as Map<String, dynamic>?;
    final device    = json['device']    as Map<String, dynamic>?;

    return EventModel(
      id:              json['id']               as int,
      // Prefer nested object id, fall back to top-level field
      lavvaggioId:     (lavvaggio?['id'] ?? json['lavvaggio_id']) as int,
      deviceId:        (device?['id']    ?? json['device_id'])    as int?,
      vehiclePlate:    (json['vehicle_plate'] ?? '') as String,
      vehicleType:     (json['vehicle_type']  ?? '') as String,
      startedAt:       DateTime.parse(json['started_at'] as String),
      endedAt:         json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as num?,
      lavvaggioName:   lavvaggio?['name']         as String?,
      deviceSerial:    device?['serial_number']   as String?,
    );
  }
}
