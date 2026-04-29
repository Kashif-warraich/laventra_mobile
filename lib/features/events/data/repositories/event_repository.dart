import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/models/pagination_meta.dart';
import '../models/event_model.dart';

class EventRepository {
  final _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<EventModel>> getEvents({
    int?    lavvaggioId,
    String? from,
    String? to,
    String? status,         // 'success' | 'error'
    String? search,         // plate substring
    String? vehicleType,
    int     page    = 1,
    int     perPage = 25,
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
    };
    if (lavvaggioId != null) params['lavvaggio_id'] = lavvaggioId;
    if (from        != null) params['from']         = from;
    if (to          != null) params['to']           = to;
    if (status      != null) params['status']       = status;
    if (search != null && search.isNotEmpty)       params['search']       = search;
    if (vehicleType != null && vehicleType.isNotEmpty) params['vehicle_type'] = vehicleType;

    final res  = await _dio.get(ApiConstants.events, queryParameters: params);
    final list = (res.data['data'] as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(res.data['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: list, meta: meta);
  }

  Future<EventModel> getEvent(int id) async {
    final res = await _dio.get('${ApiConstants.events}/$id');
    return EventModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
