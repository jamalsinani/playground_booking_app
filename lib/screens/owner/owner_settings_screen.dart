import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';
import 'package:booking_demo/services/owner_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:booking_demo/screens/auth/login_screen.dart';
import 'package:booking_demo/screens/owner/owner_notification_settings_screen.dart';


class OwnerSettingsScreen extends StatelessWidget {
  final int ownerId;

  const OwnerSettingsScreen({super.key, required this.ownerId});

  void _logout(BuildContext context) {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.question,
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
      final success = await OwnerService.deleteAccount(ownerId);
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
    final number = await OwnerService.fetchWhatsAppNumber();
    final sanitized = number.replaceAll(RegExp(r'[^\d]'), '');
    final url = 'https://wa.me/$sanitized';
    print('🔗 رابط واتساب: $url');

    final launched = await launchUrlString(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ لا يمكن فتح تطبيق واتساب')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⚠️ خطأ: $e')),
    );
  }
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

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'الإعدادات',
      ownerId: ownerId,
      currentIndex: 0,
      unreadBookingCount: 0,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          settingItem(
            icon: Icons.lock,
            title: 'تعديل كلمة المرور',
            onTap: () => Navigator.pushNamed(context, '/auth/forgot-password'),
          ),

          settingItem(
          icon: Icons.notifications,
          title: 'الإشعارات',
           onTap: () => Navigator.push(
           context,
           MaterialPageRoute(
            builder: (_) => OwnerNotificationSettingsScreen(ownerId: ownerId),
           ),
         ),
       ),
       
          settingItem(
            icon: Icons.policy,
            title: "الشروط والأحكام",
            onTap: () => Navigator.pushNamed(context, '/owner/terms'),
          ),
          settingItem(
            icon: Icons.privacy_tip,
            title: "سياسة الخصوصية",
            onTap: () => Navigator.pushNamed(context, '/owner/privacy'),
          ),
          
          settingItem(
  icon: Icons.account_balance_wallet,
  title: "محفظتي",
  onTap: () => Navigator.pushNamed(
    context,
    '/owner/wallet',
    arguments: {
      'ownerId': ownerId,
    },
  ),
),

settingItem(
           icon: Icons.info,
           title: "عن التطبيق",
            onTap: () => Navigator.pushNamed(context, '/owner/about'),
          ),

          settingItem(
            icon: Icons.chat,
            title: 'تواصل معنا',
            onTap: () => _openWhatsApp(context),
          ),
        //  settingItem(
  //icon: Icons.campaign,
  //title: "أعلن معنا",
 // onTap: () => Navigator.pushNamed(
  //  context,
  //  '/owner/ADS',
  //  arguments: {
     // 'ownerId': ownerId,                 // تأكد أنه متوفر في الصفحة الحالية
    //  'unreadBookingCount': 0, // أو ضع القيمة مباشرة مثل 0
  //  },
 // ),
//),

          settingItem(
            icon: Icons.delete_forever,
            title: 'حذف الحساب',
            onTap: () => _deleteAccount(context),
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text("تسجيل الخروج",style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
