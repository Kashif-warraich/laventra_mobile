import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/models/pagination_meta.dart';
import '../models/device_model.dart';

class DeviceRepository {
  final _dio = ApiClient.instance.dio;

  /// `status` accepts the friendly UI values 'online' / 'offline'.
  /// `deviceType` accepts the raw enum values 'mini_pc' / 'camera'.
  Future<PaginatedResponse<DeviceModel>> getDevices({
    int?    lavvaggioId,
    String? status,
    String? deviceType,
    int     page    = 1,
    int     perPage = 50,
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
    };
    if (lavvaggioId != null)              params['lavvaggio_id'] = lavvaggioId;
    if (status      != null)              params['status']       = status;
    if (deviceType  != null)              params['device_type']  = deviceType;

    final res  = await _dio.get(ApiConstants.devices, queryParameters: params);
    final list = (res.data['data'] as List)
        .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(res.data['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: list, meta: meta);
  }

  Future<DeviceModel> getDevice(int id) async {
    final res = await _dio.get('${ApiConstants.devices}/$id');
    return DeviceModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
