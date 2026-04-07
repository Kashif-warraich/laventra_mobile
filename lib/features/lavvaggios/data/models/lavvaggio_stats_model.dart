class LavvaggioStats {
  final int totalWashes;
  final int? avgDurationSeconds;

  const LavvaggioStats({
    required this.totalWashes,
    this.avgDurationSeconds,
  });

  factory LavvaggioStats.fromJson(Map<String, dynamic> json) => LavvaggioStats(
        totalWashes:        json['total_washes']         as int,
        avgDurationSeconds: json['avg_duration_seconds'] as int?,
      );

  String get formattedAvgDuration {
    if (avgDurationSeconds == null) return '—';
    final m = avgDurationSeconds! ~/ 60;
    final s = avgDurationSeconds! % 60;
    return '${m}m ${s}s';
  }
}
