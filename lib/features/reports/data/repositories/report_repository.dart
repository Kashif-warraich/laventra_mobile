import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/models/pagination_meta.dart';
import '../models/report_model.dart';

class ReportRepository {
  final _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<ReportModel>> getReports({
    int?    lavvaggioId,
    String? format,
    String? status,
    int     page    = 1,
    int     perPage = 25,
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
    };
    if (lavvaggioId != null) params['lavvaggio_id'] = lavvaggioId;
    if (format      != null) params['format']       = format;
    if (status      != null) params['status']       = status;

    final res  = await _dio.get(ApiConstants.reports, queryParameters: params);
    final list = (res.data['data'] as List)
        .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(res.data['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: list, meta: meta);
  }

  Future<ReportModel> getReport(int id) async {
    final res = await _dio.get('${ApiConstants.reports}/$id');
    return ReportModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ReportModel> createReport({
    required String   format,
    int?              lavvaggioId,
    DateTime?         dateFrom,
    DateTime?         dateTo,
    String?           name,
  }) async {
    final body = <String, dynamic>{
      'format': format,
      if (lavvaggioId != null) 'lavvaggio_id': lavvaggioId,
      if (dateFrom    != null) 'date_from':    dateFrom.toIso8601String(),
      if (dateTo      != null) 'date_to':      dateTo.toIso8601String(),
      if (name != null && name.isNotEmpty) 'name': name,
    };
    final res = await _dio.post(ApiConstants.reports, data: {'report': body});
    return ReportModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteReport(int id) async {
    await _dio.delete('${ApiConstants.reports}/$id');
  }

  /// Downloads the report to the temp cache dir and returns the [File].
  /// Caller decides what to do — open for preview or share for saving.
  Future<File> fetchReportFile(ReportModel report) async {
    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/${_safeFilename(report.name)}.${report.format}';
    await _dio.download(
      ApiConstants.reportDownload(report.id),
      path,
      options: Options(responseType: ResponseType.bytes, followRedirects: true),
    );
    return File(path);
  }

  String _safeFilename(String name) =>
      name.replaceAll(RegExp(r'[^\w\-. ]'), '_').replaceAll(RegExp(r'\s+'), '_');
}
