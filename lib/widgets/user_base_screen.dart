import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'user_bottom_navbar.dart';
import '../screens/common/notifications_screen.dart';

class UserBaseScreen extends StatefulWidget {
  final String title;
  final Widget body;
  final int userId;
  final int currentIndex;

  const UserBaseScreen({
    Key? key,
    required this.title,
    required this.body,
    required this.userId,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<UserBaseScreen> createState() => _UserBaseScreenState();
}

class _UserBaseScreenState extends State<UserBaseScreen> {
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUnreadNotificationCount();
  }

  Future<void> fetchUnreadNotificationCount() async {
    final url = Uri.parse('https://darajaty.net/api/notifications?user_id=${widget.userId}&unread=1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded['data'];
        setState(() {
          unreadCount = data.length;
        });
      }
    } catch (e) {
      print('❌ فشل في جلب عدد الإشعارات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2761),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                      builder: (_) => UserBaseScreen(
                        title: 'الإشعارات',
                        userId: widget.userId,
                        currentIndex: 0,
                        body: NotificationsScreen(userId: widget.userId),
                      ),
                    ),
                  ).then((_) => fetchUnreadNotificationCount());
                },
              ),
              if (unreadCount > 0)
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
                      '$unreadCount',
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
      bottomNavigationBar: UserBottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: (i) {},
        userId: widget.userId,
      ),
    );
  }
}
