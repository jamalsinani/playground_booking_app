import 'dart:convert';
import 'package:http/http.dart' as http;

class StadiumService {
  static const String baseUrl = 'https://darajaty.net/api';

  // ✅ جلب كل الملاعب
  static Future<List<Map<String, dynamic>>> fetchAllStadiums() async {
  final url = Uri.parse('$baseUrl/stadiums/available'); // بدون owner_id
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data']);
  } else {
    throw Exception('فشل في جلب الملاعب المتاحة');
  }
}


  // ✅ جلب معدل تقييم ملعب معين
  static Future<Map<String, dynamic>> fetchTopRatedStadium(int stadiumId) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId/top-rated');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('فشل في جلب تقييم الملعب');
    }
  }

  // ✅ جلب عدد مرات حجز ملعب معين
  static Future<Map<String, dynamic>> fetchMostBookedStadium(int stadiumId) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId/most-booked');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('فشل في جلب عدد الحجوزات للملعب');
    }
  }

  // ✅ جلب خطة الحجز حسب التاريخ والمدة
  

  static Future<List<String>> fetchAdImages() async {
  final url = Uri.parse('$baseUrl/ads');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    
    return data.map<String>((ad) {
      final fileName = ad['image'].toString(); // مثلاً: ads/banner1.jpg
      return 'https://darajaty.net/images/$fileName'; // تعديل الرابط
    }).toList();
  } else {
    throw Exception('فشل في تحميل الإعلانات');
  }
}

// ✅ جلب عدد الحجوزات الكلي
static Future<int> fetchTotalBookings() async {
  final url = Uri.parse('$baseUrl/stats/bookings');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['total_bookings'] ?? 0;
  } else {
    throw Exception('فشل في جلب عدد الحجوزات');
  }
}

// ✅ جلب عدد المستخدمين (الزوار)
static Future<int> fetchTotalUsers() async {
  final url = Uri.parse('$baseUrl/stats/users');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['total_users'] ?? 0;
  } else {
    throw Exception('فشل في جلب عدد الزوار');
  }
}

static Future<List<String>> fetchBookingPlan({
  required int stadiumId,
  required String date,
  required int duration,
}) async {
  final url = Uri.parse('$baseUrl/stadiums/$stadiumId/available-slots?date=$date&duration=$duration');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    return List<String>.from(jsonDecode(response.body));
  } else {
    throw Exception('فشل في جلب الأوقات المتاحة');
  }
}

static Future<List<Map<String, dynamic>>> fetchStadiumsWithStats() async {
  final response = await http.get(Uri.parse('https://darajaty.net/api/stadiums-with-stats'));

  if (response.statusCode == 200) {
    final jsonData = json.decode(utf8.decode(response.bodyBytes));
    return List<Map<String, dynamic>>.from(jsonData['data']);
  } else {
    throw Exception('فشل في تحميل الملاعب مع الإحصائيات');
  }
}

  static Future<List<Map<String, dynamic>>> fetchAvailableSlots({
  required int stadiumId,
  required String date,
  required int duration,
}) async {
  final url = Uri.parse(
      '$baseUrl/booking-plans/available/$stadiumId?date=$date&duration=$duration');
  final res = await http.get(url);

  if (res.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  } else {
    throw Exception('Failed to fetch available slots');
  }
}


static Future<List<Map<String, String>>> fetchBookedTimes(int stadiumId, String date) async {
  final url = Uri.parse('https://darajaty.net/api/booked-times/$stadiumId?date=$date');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map<Map<String, String>>((e) => {
      'time': e['time'],
      'status': e['status'],
    }).toList();
  } else {
    throw Exception('فشل في جلب الأوقات المحجوزة');
  }
}

static Future<List<Map<String, dynamic>>> fetchBookedDetailedTimes({
  required int stadiumId,
  required String date,
}) async {
  final url = Uri.parse("https://darajaty.net/api/bookings/detailed/$stadiumId?date=$date");
  print('📡 رابط حجز مفصل: $url');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List decoded = jsonDecode(response.body);
    return decoded.map<Map<String, dynamic>>((e) => {
      'start_time': e['start_time'],
      'status': e['status'],
    }).toList();
  } else {
    throw Exception("فشل في تحميل أوقات الحجز المفصل");
  }
}

}
