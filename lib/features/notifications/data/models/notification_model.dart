class NotificationType {
  static const success = 'success';
  static const error   = 'error';
  static const alert   = 'alert';
}

class NotificationModel {
  final int       id;
  final String    type;          // 'success' | 'error' | 'alert'
  final String    title;
  final String?   body;
  final bool      read;
  final DateTime? readAt;
  final String?   relatedType;
  final int?      relatedId;
  final Map<String, dynamic> data;
  final DateTime  createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.read,
    this.readAt,
    this.relatedType,
    this.relatedId,
    this.data = const {},
    required this.createdAt,
  });

  bool get isSuccess => type == NotificationType.success;
  bool get isError   => type == NotificationType.error;
  bool get isAlert   => type == NotificationType.alert;

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id:          json['id'] as int,
    type:        json['type'] as String,
    title:       json['title'] as String,
    body:        json['body'] as String?,
    read:        json['read'] as bool? ?? false,
    readAt:      json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
    relatedType: json['related_type'] as String?,
    relatedId:   json['related_id'] as int?,
    data:        (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    createdAt:   DateTime.parse(json['created_at'] as String),
  );

  NotificationModel copyWith({bool? read, DateTime? readAt}) => NotificationModel(
    id:          id,
    type:        type,
    title:       title,
    body:        body,
    read:        read ?? this.read,
    readAt:      readAt ?? this.readAt,
    relatedType: relatedType,
    relatedId:   relatedId,
    data:        data,
    createdAt:   createdAt,
  );
}
