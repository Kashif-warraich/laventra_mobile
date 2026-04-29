import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/models/pagination_meta.dart';
import '../models/notification_model.dart';

/// A list page also carries the global unread_count in its meta — bundled
/// so the UI can update its bell badge in the same response.
class NotificationListPage {
  final PaginatedResponse<NotificationModel> page;
  final int unreadCount;
  const NotificationListPage(this.page, this.unreadCount);
}

class NotificationRepository {
  final _dio = ApiClient.instance.dio;

  Future<NotificationListPage> getNotifications({
    String? type,            // 'success' | 'error' | 'alert'
    bool?   unreadOnly,
    int     page    = 1,
    int     perPage = 25,
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
    };
    if (type       != null) params['type']   = type;
    if (unreadOnly == true) params['unread'] = true;

    final res  = await _dio.get(ApiConstants.notifications, queryParameters: params);
    final list = (res.data['data'] as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta        = PaginationMeta.fromJson(res.data['meta'] as Map<String, dynamic>);
    final unreadCount = (res.data['meta']?['unread_count'] ?? 0) as int;
    return NotificationListPage(PaginatedResponse(data: list, meta: meta), unreadCount);
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get(ApiConstants.notificationsUnreadCount);
    return (res.data['data']?['unread_count'] ?? 0) as int;
  }

  Future<NotificationModel> markRead(int id) async {
    final res = await _dio.patch(ApiConstants.notificationRead(id));
    return NotificationModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> markAllRead() async {
    await _dio.post(ApiConstants.notificationsMarkAllRead);
  }

  Future<void> delete(int id) async {
    await _dio.delete('${ApiConstants.notifications}/$id');
  }
}
