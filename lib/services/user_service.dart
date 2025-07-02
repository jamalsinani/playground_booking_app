import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

const String baseUrl = 'https://darajaty.net/api';

class UserService {
  static final Map<int, Map<String, dynamic>> _stadiumDetailsCache = {};
  static final Map<int, DateTime> _cacheTimestamps = {};

  // جلب حجوزات المستخدم
  static Future<List<dynamic>> fetchUserBookings(int userId) async {
    final url = Uri.parse('$baseUrl/user/$userId/bookings');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في جلب الحجوزات');
    }
  }

  // إلغاء حجز
  static Future<void> cancelBooking(int bookingId) async {
    final url = Uri.parse('$baseUrl/user/bookings/$bookingId/cancel');
    final response = await http.post(url);
    if (response.statusCode != 200) {
      throw Exception('فشل في إلغاء الحجز');
    }
  }

  // إرسال تقييم
  static Future<void> submitRating({
    required int userId,
    required int stadiumId,
    required int bookingId,
    required int rating,
    required String comment,
  }) async {
    final url = Uri.parse('$baseUrl/ratings');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'stadium_id': stadiumId,
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('فشل في إرسال التقييم');
    }
  }

  // جلب التقييمات الخاصة بملعب
  static Future<List<dynamic>> fetchRatingsForStadium(int stadiumId) async {
    final url = Uri.parse('$baseUrl/ratings/stadium/$stadiumId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      throw Exception('فشل في جلب التقييمات');
    }
  }

  // جلب تفاصيل الملعب مع الصور
//static Future<Map<String, dynamic>> fetchStadiumDetails(int stadiumId) async {
 // final detailsUrl = Uri.parse('$baseUrl/stadiums/$stadiumId/details');
 // final imagesUrl = Uri.parse('$baseUrl/stadiums/$stadiumId/images');

 // final detailsResponse = await http.get(detailsUrl);
 // final imagesResponse = await http.get(imagesUrl);

 // if (detailsResponse.statusCode == 200 && imagesResponse.statusCode == 200) {
 //   final details = jsonDecode(detailsResponse.body);
  //  final imageList = jsonDecode(imagesResponse.body);
  //  final images = List<String>.from(imageList['images']);
  //  return {
  //    'details': details,
  //    'images': images,
  //  };
  //} else {
  //  throw Exception('فشل في تحميل تفاصيل الملعب أو صوره');
  //}
  //

  // 🔹 جلب بيانات المستخدم
  static Future<Map<String, dynamic>> fetchUserById(int userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في جلب بيانات المستخدم');
    }
  }

  // 🔹 تحديث حقل (الاسم، الهاتف، البريد)
  static Future<void> updateUserField(int userId, String field, String value) async {
    final url = Uri.parse('$baseUrl/users/$userId/update');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({field: value}),
    );
    if (response.statusCode != 200) {
      throw Exception('فشل في تحديث $field');
    }
  }

  // 🔹 رفع صورة البروفايل
  static Future<bool> uploadProfileImage(int userId, File file) async {
    final url = Uri.parse('$baseUrl/users/$userId/upload-image');
    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', file.path));

    final response = await request.send();
    return response.statusCode == 200;
  }

  // 🔹 تسجيل الخروج (فارغة حالياً)
  static void logout() {
    // يمكنك إضافة SharedPreferences.clear() هنا إن استخدمت توكنات
  }

  static Future<Map<String, dynamic>> fetchUserBookingCount(int userId) async {
  final url = Uri.parse('$baseUrl/user/$userId/booking-count');
  final res = await http.get(url);
  if (res.statusCode == 200) {
    return jsonDecode(res.body); // ✅ ترجع JSON فيه total, confirmed, ...
  } else {
    throw Exception('فشل في جلب عدد الحجوزات');
  }
}


static Future<int> fetchUserRatingCount(int userId) async {
  final url = Uri.parse('$baseUrl/user/$userId/ratings-count');
  final res = await http.get(url);
  if (res.statusCode == 200) {
    final json = jsonDecode(res.body);
    return json['count'] ?? 0;
  } else {
    return 0;
  }
}

static Future<bool> deleteAccount(int userId) async {
  final url = Uri.parse('$baseUrl/user/$userId/delete');
  final response = await http.delete(url);

  if (response.statusCode == 200) {
    return true;
  } else {
    print('فشل في حذف الحساب: ${response.body}');
    return false;
  }
}


static Future<String> fetchPrivacyPolicy() async {
  final url = Uri.parse('https://darajaty.net/api/privacy-policy');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['text'] ?? 'لا توجد سياسة خصوصية حالياً.';
  } else {
    throw Exception('فشل في تحميل سياسة الخصوصية');
  }
}

static Future<String> fetchTerms() async {
  final url = Uri.parse('https://darajaty.net/api/terms');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['text'] ?? 'لا توجد شروط وأحكام حالياً.';
  } else {
    throw Exception('فشل في تحميل الشروط والأحكام');
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
  final url = Uri.parse('https://darajaty.net/api/forgot-password/send-code');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode != 200) {
    throw Exception('فشل في إرسال رمز التحقق');
  }
}

static Future<bool> verifyCode(String email, String code) async {
  final url = Uri.parse('https://darajaty.net/api/verify-reset-code');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'code': code}),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

static Future<void> resetPassword(String email, String code, String password, String passwordConfirmation) async {
  final url = Uri.parse('https://darajaty.net/api/reset-password'); // ✅ هذا الصحيح للمستخدم

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
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



static Future<Map<String, dynamic>> fetchStadiumDetails(int stadiumId) async {
  final response = await http.get(Uri.parse('$baseUrl/stadium/details/$stadiumId'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('فشل في تحميل بيانات الملعب');
  }
}

static Future<void> saveFcmToken(int userId) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null || token.isEmpty) {
    print('⚠️ لم يتم الحصول على FCM Token');
    return;
  }

  final url = Uri.parse('$baseUrl/save-fcm-token');
  final response = await http.post(url, body: {
    'user_id': userId.toString(),
    'fcm_token': token,
  });

  print('📤 حفظ FCM Token تم بنجاح: ${response.statusCode}');
}


static Future<bool> getNotificationStatus(int userId) async {
  final response = await http.get(Uri.parse('$baseUrl/user/$userId/notification-status'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['enabled'] == true;
  }
  return true;
}

static Future<void> updateNotificationStatus(int userId, bool enabled) async {
  await http.post(
    Uri.parse('$baseUrl/user/update-notification'),
    body: {
      'id': userId.toString(),
      'enabled': enabled ? '1' : '0',
    },
  );
}


}
