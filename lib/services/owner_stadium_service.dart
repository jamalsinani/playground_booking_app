import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class OwnerStadiumService {
  static const String baseUrl = 'https://darajaty.net/api';

  static Future<List<dynamic>> fetchStadiumsByOwner(int ownerId) async {
    final url = Uri.parse('$baseUrl/stadiums/owner/$ownerId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('فشل في جلب الملاعب');
    }
  }

  static Future<Map<String, dynamic>> fetchOwnerData(int ownerId) async {
    final url = Uri.parse('$baseUrl/owner/$ownerId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في جلب بيانات المالك');
    }
  }

  static Future<Map<String, dynamic>> addStadium(Map<String, dynamic> data) async {
  final url = Uri.parse('$baseUrl/stadium/register');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': data['name'],
      'price_per_hour': data['price_per_hour'],
      'location': data['location'],
      'type': data['type'],
      'latitude': data['latitude'],
      'longitude': data['longitude'],
      'address': data['address'], // ✅ تم الإضافة هنا
      'owner_id': data['owner_id'],
    }),
  );

  if (response.statusCode == 201) {
    return {'success': true};
  } else {
    return {
      'success': false,
      'statusCode': response.statusCode,
      'body': response.body,
    };
  }
}


  static Future<bool> updateStadium(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/stadiums/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getStadiumById(int stadiumId) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في جلب بيانات الملعب');
    }
  }

  static Future<bool> updateStadiumBasicData({
    required int stadiumId,
    required String type,
    required String location,
    required double pricePerHour,
  }) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'location': location,
        'price_per_hour': pricePerHour,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> updateStadiumDetails({
    required int stadiumId,
    String? surface,
    String? size,
    String? players,
    String? openTime,
    String? closeTime,
    List<String>? services,
    String? rules,
    String? paymentRules, 
  }) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId/details');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'surface': surface,
        'size': size,
        'players': players,
        'open_time': openTime,
        'close_time': closeTime,
        'services': services,
        'rules': rules,
        'payment_rules': paymentRules,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getStadiumDetailsById(int stadiumId) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId/details');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في تحميل التفاصيل');
    }
  }

  static Future<bool> uploadMultipleImages({
    required int stadiumId,
    required List<XFile> files,
  }) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId/upload-images');
    final request = http.MultipartRequest('POST', url);

    for (var file in files) {
      request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('📦 Status Code: ${response.statusCode}');
      print('📦 Response Body: $responseBody');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Upload Exception: $e');
      return false;
    }
  }

  static Future<bool> deleteImage({
    required int stadiumId,
    required String imageUrl,
  }) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId/images/delete');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_url': imageUrl}),
    );

    print('🧨 حذف الصورة status: ${response.statusCode}');
    print('🧨 body: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<List<String>> fetchStadiumImages(int stadiumId) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId/images');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['images']);
    } else {
      throw Exception('فشل في جلب صور الملعب');
    }
  }

  /// ✅ جديد: تبديل حالة الملعب
  static Future<void> toggleAvailability(int stadiumId) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId/toggle-availability');
    final response = await http.post(url);

    if (response.statusCode != 200) {
      throw Exception('فشل في تبديل الحالة');
    }
  }

  /// ✅ جديد: حذف الملعب
  static Future<void> deleteStadium(int stadiumId) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('فشل في حذف الملعب');
    }
  }

  static Future<bool> updateStadiumLocation({
    required int stadiumId,
    required double? latitude,
    required double? longitude,
    required String address,
  }) async {
    final url = Uri.parse('$baseUrl/stadiums/$stadiumId/update-location');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      }),
    );

    return response.statusCode == 200;
  }
}


