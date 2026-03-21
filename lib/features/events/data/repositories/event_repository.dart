import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/event_model.dart';

class EventRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<EventModel>> getEvents({
    int?    lavvaggioId,
    String? from,
    String? to,
  }) async {
    final params = <String, dynamic>{};
    if (lavvaggioId != null) params['lavvaggio_id'] = lavvaggioId;
    if (from        != null) params['from']         = from;
    if (to          != null) params['to']           = to;

    final res  = await _dio.get(ApiConstants.events, queryParameters: params);
    final list = res.data['data'] as List;
    return list.map((e) => EventModel.fromJson(e)).toList();
  }
}