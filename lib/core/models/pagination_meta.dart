class PaginationMeta {
  final int currentPage;
  final int? nextPage;
  final int? prevPage;
  final int totalPages;
  final int totalCount;

  const PaginationMeta({
    required this.currentPage,
    this.nextPage,
    this.prevPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        currentPage: json['current_page'] as int,
        nextPage: json['next_page'] as int?,
        prevPage: json['prev_page'] as int?,
        totalPages: json['total_pages'] as int,
        totalCount: json['total_count'] as int,
      );

  bool get hasNextPage => nextPage != null;
}
