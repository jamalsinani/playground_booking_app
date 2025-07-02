import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class OwnerService {
  static const String baseUrl = 'https://darajaty.net/api';

  static Future<Map<String, dynamic>> fetchOwnerData(int ownerId) async {
    final url = Uri.parse('$baseUrl/owner/$ownerId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'name': data['name'],
        'phone': data['phone'],
        'email': data['email'],
        'profile_image': data['profile_image_url'],
      };
    } else {
      throw Exception('فشل في جلب بيانات المالك');
    }
  }

  static Future<bool> updateOwnerData({
    required int ownerId,
    required String name,
    required String phone,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/owner/update/$ownerId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<String?> uploadProfileImage(int ownerId, File imageFile) async {
    final uri = Uri.parse('$baseUrl/owner/$ownerId/upload-profile-image');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('profile_image', imageFile.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['profile_image_url'];
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> saveBookingPlan({
    required int stadiumId,
    required String date,
    required List<String> slots,
    required int duration,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking-plans'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'stadium_id': stadiumId,
        'date': date,
        'slots': slots,
        'duration': duration,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true};
    } else {
      return {'success': false, 'statusCode': response.statusCode};
    }
  }

  static Future<Map<String, dynamic>> getAllBookingPlans(int stadiumId, {int? duration}) async {
  String url = '$baseUrl/booking-plans/stadium/$stadiumId';
  if (duration != null) {
    url += '?duration=$duration';
  }

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    return {
      'success': true,
      'plans': decoded['plans'],
    };
  } else {
    return {'success': false};
  }
}


  static Future<void> confirmBooking(int bookingId) async {
    final url = Uri.parse('$baseUrl/bookings/$bookingId/confirm');
    final response = await http.post(url);

    print('📥 Response: ${response.statusCode}');
    print('📥 Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('فشل تأكيد الحجز: ${response.body}');
    }
  }

  static Future<void> cancelBooking(int bookingId) async {
    final url = Uri.parse('$baseUrl/bookings/$bookingId/cancel');
    final response = await http.post(url);
    if (response.statusCode != 200) {
      throw Exception('فشل في إلغاء الحجز');
    }
  }

  static Future<int> fetchUnreadBookingsCount(int ownerId) async {
    final url = Uri.parse('$baseUrl/owner/$ownerId/unread-bookings');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('فشل في جلب عدد الحجوزات الجديدة');
    }
  }

  static Future<void> logout(BuildContext context) async {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  static Future<bool> deleteAccount(int ownerId) async {
    final url = Uri.parse('$baseUrl/owner/$ownerId/delete');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      print('فشل في حذف الحساب: ${response.body}');
      return false;
    }
  }

  static Future<String> fetchWhatsAppNumber() async {
  final url = Uri.parse('https://darajaty.net/api/contact-whatsapp');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['number'] ?? '';
  } else {
    throw Exception('فشل في جلب رقم الواتساب');
  }
}



  static Future<void> sendResetCode(String email) async {
    final url = Uri.parse('$baseUrl/owner/forgot-password/send-code');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      print('❌ فشل إرسال الرمز: ${response.body}');
      throw Exception('فشل في إرسال رمز التحقق');
    }
  }

  static Future<bool> verifyCode(String email, String code) async {
    final url = Uri.parse('$baseUrl/owner/verify-reset-code');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    print('✅ تحقق الرمز status: ${response.statusCode}');
    print('✅ body: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<void> resetPassword(String email, String code, String password, String passwordConfirmation) async {
  final url = Uri.parse('https://darajaty.net/api/owner/reset-password');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json', // ✅ مهم جدًا لمنع رجوع HTML
    },
    body: jsonEncode({
      'email': email,
      'code': code,
      'password': password,
      'password_confirmation': passwordConfirmation,
    }),
  );

  print('🔐 Reset status: ${response.statusCode}');
  print('🔐 body: ${response.body}');

  if (response.statusCode != 200) {
    throw Exception('فشل في إعادة تعيين كلمة المرور');
  }
}


  static Future<Map<String, dynamic>> fetchWalletData(
  int ownerId, {
  DateTime? from,
  DateTime? to,
}) async {
  String url = '$baseUrl/owner/$ownerId/wallet';

  // ✅ إضافة باراميترات التاريخ في الرابط إذا تم تحديدها
  if (from != null || to != null) {
    final queryParams = <String, String>{};
    if (from != null) queryParams['from'] = from.toIso8601String().split('T').first;
    if (to != null) queryParams['to'] = to.toIso8601String().split('T').first;

    final queryString = Uri(queryParameters: queryParams).query;
    url += '?$queryString';
  }

  final response = await http.get(Uri.parse(url));

  print('🔵 Response Status: ${response.statusCode}');
  print('📦 Response Body: ${response.body}');

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    return {
      'total_profit': (data['total_profit'] as num).toDouble(),
      'month_profit': (data['month_profit'] as num).toDouble(),
      'percent_change': data['percent_change'] ?? 0,
      'monthly_stats': List<Map<String, dynamic>>.from(
        (data['monthly_stats'] as List).map((item) => {
          'month': item['month'],
          'value': (item['value'] as num).toDouble(),
        }),
      ),
      'weekly_stats': List<Map<String, dynamic>>.from(
        (data['weekly_stats'] as List).map((item) => {
          'week': item['week'],
          'value': (item['value'] as num).toDouble(),
        }),
      ),

      // ✅ إضافات مهمة للتقرير
      'stadium_profits': List<Map<String, dynamic>>.from(
        (data['stadium_profits'] as List).map((item) => {
          'stadium': item['stadium'],
          'amount': (item['amount'] as num).toDouble(),
        }),
      ),
      'bookings': List<Map<String, dynamic>>.from(
        (data['bookings'] as List).map((item) => {
          'date': item['date'],
          'stadium': item['stadium'],
          'time': item['time'],
          'price': double.tryParse(item['price'].toString()) ?? 0.0,
        }),
      ),
      'owner_name': data['owner_name'] ?? 'غير معروف',
      'owner_phone': data['owner_phone'] ?? '---',
    };
  } else {
    throw Exception('فشل في تحميل بيانات المحفظة\n${response.body}');
  }
}

static Future<void> saveOwnerFcmToken(int ownerId) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null || token.isEmpty) {
    print('⚠️ لم يتم توليد FCM Token لصاحب الملعب');
    return;
  }

  final url = Uri.parse('$baseUrl/owner/save-fcm-token');
  final response = await http.post(url, body: {
    'owner_id': ownerId.toString(),
    'fcm_token': token,
  });

  print('📤 حفظ FCM Token لصاحب الملعب: ${response.statusCode}');
}


static Future<bool> getNotificationStatus(int ownerId) async {
  final response = await http.get(Uri.parse('$baseUrl/owner/$ownerId/notification-status'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['enabled'] == true;
  }
  return true;
}

static Future<void> updateNotificationStatus(int ownerId, bool enabled) async {
  await http.post(
    Uri.parse('$baseUrl/owner/update-notification'),
    body: {
      'id': ownerId.toString(),
      'enabled': enabled ? '1' : '0',
    },
  );
}


} 
