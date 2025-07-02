import 'package:flutter/material.dart';
import 'package:booking_demo/services/user_service.dart';
import 'package:booking_demo/widgets/user_base_screen.dart';

class UserNotificationSettingsScreen extends StatefulWidget {
  final int userId;

  const UserNotificationSettingsScreen({super.key, required this.userId});

  @override
  State<UserNotificationSettingsScreen> createState() => _UserNotificationSettingsScreenState();
}

class _UserNotificationSettingsScreenState extends State<UserNotificationSettingsScreen> {
  bool isEnabled = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await UserService.getNotificationStatus(widget.userId);
    setState(() {
      isEnabled = status;
      isLoading = false;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() => isEnabled = value);
    await UserService.updateNotificationStatus(widget.userId, value);
  }

 @override
Widget build(BuildContext context) {
  return UserBaseScreen(
    title: 'إعدادات الإشعارات',
    userId: widget.userId, // ✅ هذا السطر هو المفتاح لحل الخطأ
    currentIndex: 0,
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: SwitchListTile(
                title: const Text("تفعيل الإشعارات"),
                value: isEnabled,
                onChanged: _toggleNotification,
              ),
            ),
          ),
  );
}
}