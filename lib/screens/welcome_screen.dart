import 'package:flutter/material.dart';
import 'package:booking_demo/screens/auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ الخلفية بيضاء بالكامل
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ الصورة التي تغطي الجزء العلوي
            Image.asset(
              'assets/images/playground.png', // ✅ تأكد من وضع الصورة في مجلد الصور            
              width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.55, // 40% من الشاشة 
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 30),

            // ✅ النصوص بعد الصورة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  Text(
                    'اهلاً بك في ملعبنا !',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '👋 مرحبًا بك في تطبيق ملعبنا! '
                    'يسعدنا انضمامك إلينا... اكتشف الملاعب، احجز بكل سهولة، وشارك تجربتك معنا.'
                    'نحن هنا لنمنحك تجربة رياضية مميزة وسلسة!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'دخول',
                      style: TextStyle(fontFamily: 'NotoKufiArabic', color: Colors.white,),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
