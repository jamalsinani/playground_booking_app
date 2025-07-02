import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../screens/user/stadium_booking_screen.dart';

Future<void> openStadiumFromDeepLink(BuildContext context, int stadiumId, int userId) async {
  try {
    final response = await http.get(
      Uri.parse('https://darajaty.net/api/stadiums/$stadiumId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final name = data['name'] ?? 'اسم غير معروف';
      final image = data['image'] ?? '';
      final price = data['price']?.toString() ?? '0';
      final location = data['location'] ?? 'غير محدد';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StadiumBookingScreen(
            stadiumId: stadiumId,
            stadiumName: name,
            imageUrl: image,
            price: price,
            location: location,
            userId: userId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ لم يتم العثور على بيانات الملعب')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ خطأ أثناء فتح الملعب: $e')),
    );
  }
}
