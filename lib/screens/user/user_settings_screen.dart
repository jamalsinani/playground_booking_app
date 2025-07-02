import 'package:flutter/material.dart';
import 'package:booking_demo/widgets/user_base_screen.dart';
import 'package:booking_demo/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:booking_demo/screens/user/favorite_stadiums_screen.dart';
import 'package:booking_demo/screens/auth/login_screen.dart';
import 'package:booking_demo/screens/user/user_notification_settings_screen.dart';


class UserSettingsScreen extends StatelessWidget {
  final int userId;

  const UserSettingsScreen({super.key, required this.userId});

  void _logout(BuildContext context) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.info,
    animType: AnimType.scale,
    title: 'تأكيد تسجيل الخروج',
    desc: 'هل تريد تسجيل الخروج من التطبيق؟',
    btnCancelText: 'إلغاء',
    btnOkText: 'خروج',
    btnCancelOnPress: () {},
    btnOkOnPress: () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    },
  ).show();
}

  void _deleteAccount(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: '⚠️ تأكيد الحذف',
      desc: 'سيتم حذف حسابك وجميع البيانات المرتبطة به نهائيًا.\nهل تريد المتابعة؟',
      btnCancelText: 'إلغاء',
      btnOkText: 'حذف نهائي',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        final success = await UserService.deleteAccount(userId);
        if (success) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.bottomSlide,
            title: '✔️ تم الحذف',
            desc: 'تم حذف حسابك بنجاح.',
            btnOkOnPress: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ).show();
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            title: '❌ فشل العملية',
            desc: 'حدث خطأ أثناء حذف الحساب. حاول مرة أخرى.',
            btnOkOnPress: () {},
          ).show();
        }
      },
    ).show();
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      final number = await UserService.fetchWhatsAppNumber();
      final sanitized = number.replaceAll(RegExp(r'[^\d]'), '');
      final url = 'https://wa.me/$sanitized';
      final launched = await launchUrlString(url, mode: LaunchMode.externalApplication);

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❗ فشل في فتح تطبيق واتساب')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserBaseScreen(
      title: "الإعدادات",
      userId: userId,
      currentIndex: 0,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          settingItem(
            icon: Icons.lock,
            title: "تعديل كلمة المرور",
            onTap: () => Navigator.pushNamed(context, '/auth/forgot-password'),
          ),
          settingItem(
           icon: Icons.notifications,
           title: 'الإشعارات',
            onTap: () => Navigator.push(
           context,
            MaterialPageRoute(
              builder: (_) => UserNotificationSettingsScreen(userId: userId),
            ),
          ),
        ),

          settingItem(
            icon: Icons.favorite,
            title: "الملاعب المفضلة",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoriteStadiumsScreen(userId: userId),
                ),
              );
            },
          ),
          settingItem(
            icon: Icons.description,
            title: "الشروط والأحكام",
            onTap: () => Navigator.pushNamed(context, '/terms'),
          ),
          settingItem(
            icon: Icons.privacy_tip_outlined,
            title: "سياسة الخصوصية",
            onTap: () => Navigator.pushNamed(context, '/privacy'),
          ),
          settingItem(
            icon: Icons.support_agent,
            title: "تواصل معنا",
            onTap: () => _openWhatsApp(context),
          ),
          settingItem(
            icon: Icons.info,
            title: "عن التطبيق",
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          settingItem(
            icon: Icons.delete_forever,
            title: "حذف الحساب",
            onTap: () => _deleteAccount(context),
            color: Colors.red,
          ),
          const SizedBox(height: 20),
ElevatedButton.icon(
  icon: const Icon(Icons.logout, color: Colors.white), // ✅ أيقونة بيضاء
  label: const Text(
    "تسجيل الخروج",
    style: TextStyle(color: Colors.white), // ✅ نص أبيض
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,         // ✅ لون الزر
    foregroundColor: Colors.white,       // ✅ لون النص والأيقونة عند الضغط
  ),
  onPressed: () => _logout(context),
),

        ],
      ),
    );
  }

  Widget settingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
