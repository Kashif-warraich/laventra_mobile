class LavvaggioModel {
  final int                id;
  final String             name;
  final String             address;
  final String             city;
  final String             country;
  final String             status;             // 'active' | 'inactive' (admin-controlled)
  final String             operationalStatus; // 'online' | 'offline' (device-derived)
  final int                aiCount;
  final int                cameraCount;
  final int                todayWashes;
  final int                monthlyWashes;
  final List<PartnerModel> partners;

  const LavvaggioModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.country,
    required this.status,
    required this.operationalStatus,
    required this.aiCount,
    required this.cameraCount,
    required this.todayWashes,
    required this.monthlyWashes,
    this.partners = const [],
  });

  bool get isActive => status == 'active';
  bool get isOnline => operationalStatus == 'online';

  String get fullAddress => '$address, $city, $country';

  String get partnersDisplay {
    if (partners.isEmpty) return '—';
    return partners.map((p) => p.fullName).join(', ');
  }

  factory LavvaggioModel.fromJson(Map<String, dynamic> json) => LavvaggioModel(
    id:                json['id'] as int,
    name:              json['name'] as String,
    address:           (json['address'] ?? '') as String,
    city:              (json['city']    ?? '') as String,
    country:           (json['country'] ?? '') as String,
    status:            (json['status']             ?? 'active')  as String,
    operationalStatus: (json['operational_status'] ?? 'offline') as String,
    aiCount:           (json['ai_count']            ?? 0) as int,
    cameraCount:       (json['camera_count']        ?? 0) as int,
    todayWashes:       (json['today_washes']        ?? 0) as int,
    monthlyWashes:     (json['monthly_washes']      ?? 0) as int,
    partners: (json['partners'] as List<dynamic>? ?? [])
        .map((p) => PartnerModel.fromJson(p as Map<String, dynamic>))
        .toList(),
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
    id:        json['id']         as int,
    firstName: json['first_name'] as String,
    lastName:  json['last_name']  as String,
    email:     (json['email'] ?? '') as String,
  );
}

