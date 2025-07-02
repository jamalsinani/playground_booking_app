import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../screens/home_screen.dart';
import '../screens/user/user_bookings_screen.dart';
import '../screens/user/user_profile_screen.dart'; // ✅ إضافة استيراد صفحة الحساب
import '../screens/user/user_settings_screen.dart'; // ✅ استيراد صفحة الإعدادات

class UserBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int userId;

  const UserBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserBottomNavBar> createState() => _UserBottomNavBarState();
}

class _UserBottomNavBarState extends State<UserBottomNavBar> {
  int bookingCount = 0;

  @override
  void initState() {
    super.initState();
    fetchBookingCount();
  }

  Future<void> fetchBookingCount() async {
    try {
      final url = Uri.parse('https://darajaty.net/api/user/${widget.userId}/booking-count');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bookingCount = data['count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('فشل في جلب عدد الحجوزات: $e');
    }
  }

  Future<void> clearBookingCount() async {
    try {
      final url = Uri.parse('https://darajaty.net/api/user/${widget.userId}/clear-booking-count');
      final response = await http.post(url);
      if (response.statusCode == 200) {
        setState(() {
          bookingCount = 0;
        });
      }
    } catch (e) {
      debugPrint('فشل في تصفير عدد الحجوزات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UserSettingsScreen(userId: widget.userId),
      ),
    );
    break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: widget.userId),
              ),
            );
            break;
          case 2:
            clearBookingCount();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => UserBookingsScreen(userId: widget.userId),
              ),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomeScreen(userId: widget.userId),
              ),
            );
            break;
        }
        widget.onTap(index);
      },
      backgroundColor: const Color(0xFF22235D),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'الإعدادات',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'حسابي',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.calendar_month_outlined),
              if (bookingCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      bookingCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'الحجوزات',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'الرئيسية',
        ),
      ],
    );
  }
}
