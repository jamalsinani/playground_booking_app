import 'package:flutter/material.dart';
import 'package:booking_demo/screens/auth/login_screen.dart';
import 'package:booking_demo/screens/auth/verify_code_screen.dart';
import 'package:booking_demo/services/user_service.dart';
import 'package:booking_demo/services/owner_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final bool isOwner; // ✅ لتحديد نوع المستخدم

  const ForgotPasswordScreen({super.key, this.isOwner = false});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;

  void _sendCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال بريد إلكتروني صالح')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ التبديل بين اليوزر والأونر
      if (widget.isOwner) {
        await OwnerService.sendResetCode(email);
      } else {
        await UserService.sendResetCode(email);
      }

      setState(() => isLoading = false);

      // ✅ تمرير isOwner أيضًا إلى شاشة التحقق
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(email: email, isOwner: widget.isOwner),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في ارسال الرمز - تحقق من البريد الالكتروني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Image.asset('assets/images/forgot.png', height: 220),
              const SizedBox(height: 30),
              const Text(
                'تغيير كلمة المرور',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoKufiArabic',
                  color: Color(0xFF22235D),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'أدخل الإيميل الخاص بك لتغيير كلمة المرور',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'NotoKufiArabic',
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'الإيميل',
                  hintStyle: const TextStyle(fontFamily: 'NotoKufiArabic'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22235D),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'إرسال',
                        style: TextStyle(
                          fontFamily: 'NotoKufiArabic',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
