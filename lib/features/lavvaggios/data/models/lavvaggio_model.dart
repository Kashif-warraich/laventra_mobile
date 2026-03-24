class LavvaggioModel {
  final int              id;
  final String           name;
  final String           address;
  final String           city;
  final String           country;
  final String           status;
  final List<PartnerModel> partners;
  final DeviceSummary?   device;

  const LavvaggioModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.country,
    required this.status,
    this.partners = const [],
    this.device,
  });

  bool get isActive => status == 'active';

  String get fullAddress => '$address, $city, $country';

  String get partnersDisplay {
    if (partners.isEmpty) return '—';
    return partners.map((p) => p.fullName).join(', ');
  }

  factory LavvaggioModel.fromJson(Map<String, dynamic> json) => LavvaggioModel(
    id:       json['id'],
    name:     json['name'],
    address:  json['address'],
    city:     json['city'],
    country:  json['country'],
    status:   json['status'],
    partners: (json['partners'] as List<dynamic>? ?? [])
        .map((p) => PartnerModel.fromJson(p as Map<String, dynamic>))
        .toList(),
    device:   json['device'] != null ? DeviceSummary.fromJson(json['device']) : null,
  );
}

class PartnerModel {
  final int    id;
  final String firstName;
  final String lastName;
  final String email;

  const PartnerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName';

  factory PartnerModel.fromJson(Map<String, dynamic> json) => PartnerModel(
    id:        json['id'],
    firstName: json['first_name'],
    lastName:  json['last_name'],
    email:     json['email'],
  );
}

class DeviceSummary {
  final int    id;
  final String serialNumber;
  final String status;
  final String firmwareVersion;
  final String? lastSeenAt;

  const DeviceSummary({
    required this.id,
    required this.serialNumber,
    required this.status,
    required this.firmwareVersion,
    this.lastSeenAt,
  });

  bool get isOnline => status == 'active';

  factory DeviceSummary.fromJson(Map<String, dynamic> json) => DeviceSummary(
    id:              json['id'],
    serialNumber:    json['serial_number'],
    status:          json['status'],
    firmwareVersion: json['firmware_version'],
    lastSeenAt:      json['last_seen_at'],
  );
}