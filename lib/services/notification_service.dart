import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_notification.dart';

const String baseUrl = 'https://darajaty.net/api'; 

class NotificationService {
  /// 📥 جلب قائمة الإشعارات للمالك أو المستخدم
  static Future<List<AppNotification>> fetchNotifications({
  int? userId,
  int? ownerId,
  bool unreadOnly = false,
  bool todayOnly = false,
}) async {
  final queryParams = <String, String>{};

  if (userId != null) queryParams['user_id'] = userId.toString();
  if (ownerId != null) queryParams['owner_id'] = ownerId.toString();
  if (unreadOnly) queryParams['unread'] = '1';
  if (todayOnly) queryParams['today'] = '1';

  final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    // ✅ استخراج البيانات من داخل 'data'
    if (decoded is Map && decoded.containsKey('data')) {
      final dataList = decoded['data'] as List;
      return dataList
          .map((item) => AppNotification.fromJson(item))
          .toList();
    } else {
      throw Exception('الاستجابة لا تحتوي على بيانات إشعارات');
    }
  } else {
    throw Exception('فشل في تحميل الإشعارات');
  }
}




  /// 🔢 جلب عدد الإشعارات (غير المقروءة عادة) للمالك أو المستخدم
  static Future<int> fetchNotificationCount({int? userId, int? ownerId}) async {
    final queryParams = <String, String>{};

    if (userId != null) queryParams['user_id'] = userId.toString();
    if (ownerId != null) queryParams['owner_id'] = ownerId.toString();

    final uri = Uri.parse('$baseUrl/notifications/count')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('فشل في جلب عدد الإشعارات');
    }
  }
  static Future<int> fetchUnreadBookingCount(int ownerId) async {
  final uri = Uri.parse('$baseUrl/owner/$ownerId/bookings/unread');
  final response = await http.get(uri);

  print("📨 رد السيرفر: ${response.body}");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is Map && data.containsKey('count')) {
      return data['count'];
    } else {
      throw Exception('الرد غير متوقع: ${response.body}');
    }
  } else {
    throw Exception('فشل في جلب عدد الحجوزات غير المقروءة');
  }
}

static Future<void> markAsRead(int notificationId) async {
  final url = Uri.parse('$baseUrl/notifications/mark-read/$notificationId');
  final response = await http.get(url); // ✅ تعديل هنا

  print('📡 استدعاء API: ${url.toString()}');
  print('📥 الاستجابة: ${response.statusCode} - ${response.body}');

  if (response.statusCode != 200) {
    throw Exception('فشل في تحديث حالة الإشعار');
  }
}



}
