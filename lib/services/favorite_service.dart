import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://darajaty.net/api';

class FavoriteService {
  // ✅ تبديل التفضيل (إضافة أو إزالة)
  static Future<bool> toggleFavorite(int userId, int stadiumId) async {
    final url = Uri.parse('$baseUrl/favorite/toggle');
    final response = await http.post(url, body: {
      'user_id': userId.toString(),
      'stadium_id': stadiumId.toString(),
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['favorited']; // true or false
    } else {
      throw Exception('فشل في تبديل التفضيل');
    }
  }

  // ✅ هل الملعب مفضل؟
  static Future<bool> isFavorite(int userId, int stadiumId) async {
    final url = Uri.parse('$baseUrl/favorite/check?user_id=$userId&stadium_id=$stadiumId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['favorited'];
    } else {
      throw Exception('فشل في جلب حالة التفضيل');
    }
  }

  // ✅ جلب كل الملاعب المفضلة لمستخدم معيّن
  static Future<List<dynamic>> fetchFavorites(int userId) async {
    final url = Uri.parse('$baseUrl/user/$userId/favorites');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // يتوقع أن ترجع List
    } else {
      throw Exception('فشل في جلب الملاعب المفضلة');
    }
  }
}
