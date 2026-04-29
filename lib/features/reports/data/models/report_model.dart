class ReportFormat {
  static const pdf  = 'pdf';
  static const csv  = 'csv';
  static const xlsx = 'xlsx';
}

class ReportStatus {
  static const generating = 'generating';
  static const ready      = 'ready';
  static const failed     = 'failed';
}

class ReportModel {
  final int       id;
  final String    name;
  final String    format;          // 'pdf' | 'csv' | 'xlsx'
  final String    status;          // 'generating' | 'ready' | 'failed'
  final int?      lavvaggioId;
  final String?   lavvaggioName;   // null/empty → "All Lavaggi"
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int?      sizeBytes;
  final int?      pages;
  final String?   downloadUrl;     // backend-provided, only when ready
  final String?   error;
  final DateTime  createdAt;

  const ReportModel({
    required this.id,
    required this.name,
    required this.format,
    required this.status,
    this.lavvaggioId,
    this.lavvaggioName,
    this.dateFrom,
    this.dateTo,
    this.sizeBytes,
    this.pages,
    this.downloadUrl,
    this.error,
    required this.createdAt,
  });

  bool get isReady      => status == ReportStatus.ready;
  bool get isGenerating => status == ReportStatus.generating;
  bool get isFailed     => status == ReportStatus.failed;

  /// Human-friendly file size — "284 KB", "1.2 MB", or "—" when missing.
  String get formattedSize {
    final b = sizeBytes;
    if (b == null) return '—';
    if (b < 1024)        return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formatLabel => format.toUpperCase();
  String get scopeLabel  => lavvaggioName?.isNotEmpty == true ? lavvaggioName! : 'All Lavaggi';

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final lav = json['lavvaggio'] as Map<String, dynamic>?;
    return ReportModel(
      id:            json['id'] as int,
      name:          json['name'] as String,
      format:        json['format'] as String,
      status:        json['status'] as String,
      lavvaggioId:   lav?['id'] as int?,
      lavvaggioName: lav?['name'] as String?,
      dateFrom:      json['date_from'] != null ? DateTime.tryParse(json['date_from'] as String) : null,
      dateTo:        json['date_to']   != null ? DateTime.tryParse(json['date_to']   as String) : null,
      sizeBytes:     json['size_bytes'] as int?,
      pages:         json['pages']      as int?,
      downloadUrl:   json['download_url'] as String?,
      error:         json['error'] as String?,
      createdAt:     DateTime.parse(json['created_at'] as String),
    );
  }
}
