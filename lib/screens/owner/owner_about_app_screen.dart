import 'package:flutter/material.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';

class OwnerAboutAppScreen extends StatelessWidget {
  final int ownerId;
  final String appVersion;

  const OwnerAboutAppScreen({
    super.key, 
    required this.ownerId,
    this.appVersion = '1.0.0',
  });

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'عن التطبيق',
      ownerId: ownerId,
      currentIndex: 0,
      unreadBookingCount: 0,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // بطاقة المعلومات المرفوعة لأعلى
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.zero, // إزالة الهوامش الافتراضية للبطاقة
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // شعار التطبيق داخل البطاقة
                    Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // عنوان التطبيق
                    const Text(
                      'حجوزات الملاعب الذكية',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // وصف التطبيق
                    const Text(
                      'منصة متكاملة تقدم حلولاً ذكية لإدارة وحجز الملاعب الرياضية. '
                      'نسعى لتوفير تجربة فريدة لأصحاب الملاعب واللاعبين من خلال:'
                      '\n\n• واجهة سهلة الاستخدام'
                      '\n• إدارة حجوزات ذكية'
                      '\n• تقارير وأدوات تحليلية'
                      '\n• دعم فني متكامل',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // معلومات المطور
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'تصميم وتطوير: jamal sinani',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // معلومات الإصدار
            Text(
              'إصدار التطبيق: $appVersion',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // حقوق النشر
            const Text(
              '© 2023 جميع الحقوق محفوظة',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}