class LavvaggioStats {
  final int totalWashes;
  final int completedWashes;
  final int inProgress;
  final int? avgDurationSeconds;
  final double completionRate;

  const LavvaggioStats({
    required this.totalWashes,
    required this.completedWashes,
    required this.inProgress,
    this.avgDurationSeconds,
    required this.completionRate,
  });

  factory LavvaggioStats.fromJson(Map<String, dynamic> json) => LavvaggioStats(
        totalWashes:        json['total_washes']        as int,
        completedWashes:    json['completed_washes']    as int,
        inProgress:         json['in_progress']         as int,
        avgDurationSeconds: json['avg_duration_seconds'] as int?,
        completionRate:     (json['completion_rate']    as num).toDouble(),
      );

  String get formattedAvgDuration {
    if (avgDurationSeconds == null) return '—';
    final m = avgDurationSeconds! ~/ 60;
    final s = avgDurationSeconds! % 60;
    return '${m}m ${s}s';
  }
}
