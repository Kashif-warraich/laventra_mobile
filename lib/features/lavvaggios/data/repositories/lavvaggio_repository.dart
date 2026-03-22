import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/models/pagination_meta.dart';
import '../models/lavvaggio_model.dart';
import '../models/lavvaggio_stats_model.dart';

class LavvaggioRepository {
  final _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<LavvaggioModel>> getLavvaggios({
    int page    = 1,
    int perPage = 25,
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
    };
    final res  = await _dio.get(ApiConstants.lavvaggios, queryParameters: params);
    final list = (res.data['data'] as List)
        .map((e) => LavvaggioModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(
        res.data['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: list, meta: meta);
  }

  Future<LavvaggioModel> getLavvaggio(int id) async {
    final res = await _dio.get('${ApiConstants.lavvaggios}/$id');
    return LavvaggioModel.fromJson(res.data['data']);
  }

  Future<LavvaggioModel> updateLavvaggio(
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch(
      '${ApiConstants.lavvaggios}/$id',
      data: {'lavvaggio': data},
    );
    return LavvaggioModel.fromJson(res.data['data']);
  }

  Future<LavvaggioStats> getStats(int id, {DateTime? from, DateTime? to}) async {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from.toIso8601String();
    if (to   != null) params['to']   = to.toIso8601String();
    final response = await _dio.get(
      '${ApiConstants.lavvaggios}/$id/stats',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return LavvaggioStats.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
