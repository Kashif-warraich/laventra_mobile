import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/lavvaggio_model.dart';

class LavvaggioRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<LavvaggioModel>> getLavvaggios() async {
    final res = await _dio.get(ApiConstants.lavvaggios);
    final list = res.data['data'] as List;
    return list.map((e) => LavvaggioModel.fromJson(e)).toList();
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
}