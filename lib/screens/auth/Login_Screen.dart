import 'package:flutter/material.dart';
import 'package:booking_demo/screens/auth/register_screen.dart';
import 'package:booking_demo/screens/auth/forgot_password_screen.dart';
import 'package:booking_demo/screens/owner/owner_home_screen.dart';
import 'package:booking_demo/screens/home_screen.dart'; // ✅ صفحة اليوزر
import 'package:booking_demo/services/auth_service.dart';
import 'package:booking_demo/services/user_service.dart';
import 'package:booking_demo/services/owner_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscureText = true;
  bool isHajiz = true; // ✅ نوع المستخدم (افتراضيًا حاجز)
  bool isLoading = false; // ✅ للحالة أثناء التحميل

  // ✅ زر لاختيار نوع المستخدم (صاحب ملعب / حاجز)
  Widget buildUserTypeButton(String title, bool value) {
    bool selected = isHajiz == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isHajiz = value),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 6),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.green : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'NotoKufiArabic',
                color: selected ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> login() async {
  setState(() => isLoading = true);
  print("🚀 تسجيل الدخول كـ ${isHajiz ? "حاجز" : "صاحب ملعب"}");

  final result = isHajiz
      ? await AuthService.loginUser(
          phone: phoneController.text,
          password: passwordController.text,
        )
      : await AuthService.loginOwner(
          phone: phoneController.text,
          password: passwordController.text,
        );

  setState(() => isLoading = false);

  if (result['success']) {
    final userId = result['data']['id'];
    print('✅ تسجيل دخول ناجح. ID: $userId');
    try {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('📲 FCM Token الحالي: $fcmToken');
} catch (e) {
  print('⚠️ فشل في توليد FCM Token: $e');
}


    // ✅ حفظ بيانات الدخول
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setString('role', isHajiz ? 'user' : 'owner');

    // ✅ محاولة حفظ FCM Token بدون تعطيل التنقل
    try {
      if (isHajiz) {
        await UserService.saveFcmToken(userId);
      } else {
        await OwnerService.saveOwnerFcmToken(userId);
      }
    } catch (e) {
      print('⚠️ فشل حفظ FCM Token: $e');
    }

    // ✅ تأخير بسيط لإتاحة رؤية الإشعار
    await Future.delayed(Duration(seconds: 1));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isHajiz
            ? HomeScreen(userId: userId)
            : OwnerHomeScreen(ownerId: userId),
      ),
    );
  } else {
    print('❌ خطأ في تسجيل الدخول: ${result['statusCode']}');
    print('Body: ${result['body']}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ فشل تسجيل الدخول. تحقق من البيانات')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
          child: Column(
            children: [
              Image.asset('assets/images/login.png', height: 250),
              const SizedBox(height: 10),
              const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoKufiArabic',
                  color: Color(0xFF22235D),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ اختيار نوع المستخدم
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildUserTypeButton('صاحب ملعب', false),
                  buildUserTypeButton('حاجز', true),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  hintText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(isOwner: !isHajiz),
                      ),
                    );
                  },
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                      fontFamily: 'NotoKufiArabic',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22235D),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontFamily: 'NotoKufiArabic',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'إنشاء حساب',
                      style: TextStyle(
                        fontFamily: 'NotoKufiArabic',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    'لا تملك حساب؟',
                    style: TextStyle(fontFamily: 'NotoKufiArabic'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
