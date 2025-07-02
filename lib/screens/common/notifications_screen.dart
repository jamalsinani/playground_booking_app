import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/app_notification.dart';
import 'package:booking_demo/screens/owner/owner_home_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final int? userId;
  final int? ownerId;

  const NotificationsScreen({super.key, this.userId, this.ownerId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _futureNotifications;
  bool showUnreadOnly = false;
  bool showTodayOnly = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  void fetchNotifications() {
    print('🔄 بدأ جلب الإشعارات...');
    setState(() {
      _futureNotifications = NotificationService.fetchNotifications(
        userId: widget.userId,
        ownerId: widget.ownerId,
        unreadOnly: showUnreadOnly,
        todayOnly: showTodayOnly,
      ).then((notifications) {
        print('📦 تم جلب ${notifications.length} إشعار(ات)');
        for (var n in notifications) {
          print('🔔 إشعار: ${n.title} | النوع: ${n.type} | الهدف: ${n.targetId}');
        }
        return notifications;
      }).catchError((error) {
        print('❌ خطأ أثناء جلب الإشعارات: $error');
        throw error;
      });
    });
  }

  @override
Widget build(BuildContext context) {
  return Material(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
          child: Row(
            children: [
              FilterChip(
                label: const Text('غير المقروءة فقط', style: TextStyle(fontSize: 12),),
                selected: showUnreadOnly,
                onSelected: (value) {
                  setState(() {
                    showUnreadOnly = value;
                    fetchNotifications();
                  });
                },
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('اليوم فقط', style: TextStyle(fontSize: 12),),
                selected: showTodayOnly,
                onSelected: (value) {
                  setState(() {
                    showTodayOnly = value;
                    fetchNotifications();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<AppNotification>>(
            future: _futureNotifications,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('حدث خطأ أثناء جلب الإشعارات'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('لا توجد إشعارات في الوقت الحالي'));
              }

              final notifications = snapshot.data!;
              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];

                  // ✅ تجاهل الإشعارات غير الصالحة
                  if (notif.title.isEmpty && notif.body.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: notif.isRead ? Colors.black : Colors.green,
                    ),
                    title: Text( notif.title, style: const TextStyle(fontSize: 12),),
                    subtitle: Text( notif.body, style: const TextStyle(fontSize: 10),),
                    trailing: Text(
                      '${notif.createdAt.year}-${notif.createdAt.month.toString().padLeft(2, '0')}-${notif.createdAt.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    onTap: () async {
                      try {
                        if (!notif.isRead) {
                          await NotificationService.markAsRead(notif.id);
                          fetchNotifications();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تعليم الإشعار كمقروء')),
                        );
                      } catch (e) {
                        print('❌ خطأ عند فتح الإشعار: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('فشل في فتح الإشعار')),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
}


