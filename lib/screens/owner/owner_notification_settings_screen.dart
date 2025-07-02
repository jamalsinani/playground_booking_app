import 'package:flutter/material.dart';
import 'package:booking_demo/services/owner_service.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';

class OwnerNotificationSettingsScreen extends StatefulWidget {
  final int ownerId;

  const OwnerNotificationSettingsScreen({super.key, required this.ownerId});

  @override
  State<OwnerNotificationSettingsScreen> createState() => _OwnerNotificationSettingsScreenState();
}

class _OwnerNotificationSettingsScreenState extends State<OwnerNotificationSettingsScreen> {
  bool isEnabled = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await OwnerService.getNotificationStatus(widget.ownerId);
    setState(() {
      isEnabled = status;
      isLoading = false;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() => isEnabled = value);
    await OwnerService.updateNotificationStatus(widget.ownerId, value);
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'إعدادات الإشعارات',
      ownerId: widget.ownerId,
      currentIndex: 0, // يمكنك تغييره حسب الصفحة المفتوحة في الـ BottomNav
      unreadBookingCount: 0, // أو جلب العدد الفعلي إن أردت
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
