import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://darajaty.net/api';

  // ✅ تسجيل دخول صاحب الملعب
  static Future<Map<String, dynamic>> loginOwner({
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/owner/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone.trim(),
        'password': password.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'data': data['data'],
      };
    } else {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'body': response.body,
      };
    }
  }

  // ✅ تسجيل صاحب الملعب
  // ✅ تعديل دالة registerUser
static Future<Map<String, dynamic>> registerUser({
  required String name,
  required String email,
  required String phone,
  required String password,
  required String passwordConfirmation, // ⬅️ الجديد
}) async {
  final url = Uri.parse('$baseUrl/users/register');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation, // ⬅️ الجديد
    }),
  );

  return {
    'success': response.statusCode == 201,
    'statusCode': response.statusCode,
    'body': response.body,
  };
}

// ✅ تعديل دالة registerStadiumOwner
static Future<Map<String, dynamic>> registerStadiumOwner({
  required String name,
  required String email,
  required String phone,
  required String password,
  required String passwordConfirmation, // ⬅️ الجديد
}) async {
  final url = Uri.parse('$baseUrl/owner/register');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation, // ⬅️ الجديد
    }),
  );

  return {
    'success': response.statusCode == 201,
    'statusCode': response.statusCode,
    'body': response.body,
  };
}
static Future<Map<String, dynamic>> loginUser({
  required String phone,
  required String password,
}) async {
  final url = Uri.parse('$baseUrl/users/login');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'phone': phone.trim(),
      'password': password.trim(),
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'success': true,
      'data': data['data'],
    };
  } else {
    return {
      'success': false,
      'statusCode': response.statusCode,
      'body': response.body,
    };
  }
}

}
