import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:booking_demo/services/user_service.dart';
import 'package:booking_demo/widgets/user_base_screen.dart';

class ContactScreen extends StatelessWidget {
  final int userId;

  const ContactScreen({super.key, required this.userId});

  Future<void> openWhatsApp(BuildContext context) async {
    try {
      final number = await UserService.fetchWhatsAppNumber();

      if (number.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم الواتساب غير متوفر حالياً')),
        );
        return;
      }

      final uri = Uri.parse('https://wa.me/$number');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح واتساب')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء محاولة فتح واتساب')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserBaseScreen(
      title: 'تواصل معنا',
      userId: userId,
      currentIndex: 0,
      body: Center(
        child: ElevatedButton.icon(
          icon: const FaIcon(FontAwesomeIcons.whatsapp),
          label: const Text('تواصل معنا عبر واتساب'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () => openWhatsApp(context),
        ),
      ),
    );
  }
}
