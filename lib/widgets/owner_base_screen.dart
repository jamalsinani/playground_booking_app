import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../screens/owner/owner_bookings_screen.dart';
import '../screens/owner/owner_profile_screen.dart';
import '../screens/owner/owner_settings_screen.dart';
import '../screens/owner/Owner_Home_Screen.dart';
import '../screens/common/notifications_screen.dart';
import 'custom_bottom_navbar.dart';

class OwnerBaseScreen extends StatefulWidget {
  final String title;
  final Widget body;
  final int ownerId;
  final int currentIndex;
  final int unreadBookingCount;
  final Function(int)? onTap;
  final VoidCallback? onAddPressed;

  const OwnerBaseScreen({
    super.key,
    required this.title,
    required this.body,
    required this.ownerId,
    required this.currentIndex,
    this.unreadBookingCount = 0,
    this.onTap,
    this.onAddPressed,
  });

  @override
  State<OwnerBaseScreen> createState() => _OwnerBaseScreenState();
}

class _OwnerBaseScreenState extends State<OwnerBaseScreen> {
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    fetchUnreadNotifications();
  }

  Future<void> fetchUnreadNotifications() async {
    final url = Uri.parse('https://darajaty.net/api/notifications?owner_id=${widget.ownerId}&unread=1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded['data'];
        setState(() {
          unreadNotifications = data.length;
        });
      }
    } catch (e) {
      print('❌ فشل في جلب عدد إشعارات المالك: $e');
    }
  }

  void _handleTap(int index) {
    // منع فتح نفس الصفحة إذا كان المؤشر الحالي هو نفسه الجديد
    if (index == widget.currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerSettingsScreen(ownerId: widget.ownerId),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerProfileScreen(ownerId: widget.ownerId),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerBookingsScreen(ownerId: widget.ownerId),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerHomeScreen(ownerId: widget.ownerId),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2761),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                tooltip: 'الإشعارات',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerBaseScreen(
                        title: 'الإشعارات',
                        ownerId: widget.ownerId,
                        currentIndex: widget.currentIndex,
                        unreadBookingCount: widget.unreadBookingCount,
                        body: NotificationsScreen(ownerId: widget.ownerId),
                      ),
                    ),
                  ).then((_) => fetchUnreadNotifications());
                },
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        )
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: widget.body,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: widget.currentIndex > 3 ? 0 : widget.currentIndex,
        ownerId: widget.ownerId,
        unreadBookingCount: widget.unreadBookingCount,
        onTap: _handleTap, // تمرير الدالة المحسنة
      ),
    );
  }
}