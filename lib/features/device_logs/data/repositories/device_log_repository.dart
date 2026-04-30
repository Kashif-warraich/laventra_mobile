import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/models/pagination_meta.dart';
import '../models/device_log_model.dart';

class DeviceLogRepository {
  final _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<DeviceLogModel>> fetchLogs({
    int?      lavvaggioId,
    DateTime? since,
    int       page    = 1,
    int       perPage = 25,
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
    };
    if (lavvaggioId != null) params['lavvaggio_id'] = lavvaggioId;
    if (since       != null) params['since']        = since.toUtc().toIso8601String();

    final res = await _dio.get(ApiConstants.deviceLogs, queryParameters: params);
    final list = (res.data['data'] as List)
        .map((e) => DeviceLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(
        res.data['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: list, meta: meta);
  }
}
