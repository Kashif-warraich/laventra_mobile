/// Backend device_type values: 'mini_pc' | 'camera'.
/// We expose the friendlier 'AI' / 'Camera' labels via [typeLabel].
class DeviceType {
  static const miniPc = 'mini_pc';
  static const camera = 'camera';
}

class DeviceStatus {
  static const active  = 'active';   // == online in UI
  static const offline = 'offline';
  static const revoked = 'revoked';
}

class DeviceModel {
  final int       id;
  final String?   name;            // friendly display name; may be null → fall back to serial
  final String    serialNumber;
  final String?   ipAddress;
  final String    deviceType;      // raw enum value
  final String    status;          // raw enum value
  final String?   firmwareVersion;
  final DateTime? lastSeenAt;
  final int?      lavvaggioId;
  final String?   lavvaggioName;

  const DeviceModel({
    required this.id,
    this.name,
    required this.serialNumber,
    this.ipAddress,
    required this.deviceType,
    required this.status,
    this.firmwareVersion,
    this.lastSeenAt,
    this.lavvaggioId,
    this.lavvaggioName,
  });

  // ── Helpers ────────────────────────────────────────────────────────────
  bool get isOnline => status == DeviceStatus.active;
  bool get isAi     => deviceType == DeviceType.miniPc;
  bool get isCamera => deviceType == DeviceType.camera;

  String get displayName  => name?.isNotEmpty == true ? name! : serialNumber;
  String get typeLabel    => isAi ? 'AI' : 'Camera';
  String get statusLabel  => isOnline ? 'Online' : 'Offline';

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    final lav = json['lavvaggio'] as Map<String, dynamic>?;
    return DeviceModel(
      id:              json['id'] as int,
      name:            json['name'] as String?,
      serialNumber:    json['serial_number'] as String,
      ipAddress:       json['ip_address'] as String?,
      deviceType:      json['device_type'] as String,
      status:          json['status'] as String,
      firmwareVersion: json['firmware_version'] as String?,
      lastSeenAt:      json['last_seen_at'] != null ? DateTime.parse(json['last_seen_at'] as String) : null,
      lavvaggioId:     lav?['id'] as int?,
      lavvaggioName:   lav?['name'] as String?,
    );
  }
}
