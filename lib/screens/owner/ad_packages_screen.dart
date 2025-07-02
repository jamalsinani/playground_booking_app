import 'package:flutter/material.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';

class AdPackagesScreen extends StatelessWidget {
  final int ownerId;
  final int unreadBookingCount;

  const AdPackagesScreen({
    super.key,
    required this.ownerId,
    this.unreadBookingCount = 0,
  });

  void navigateToForm(BuildContext context, String type) {
    Navigator.pushNamed(
      context,
      '/owner/newAdForm',
      arguments: {'type': type, 'ownerId': ownerId},
    );
  }

  Widget buildPackageCard({
    required BuildContext context,
    required String title,
    required String description,
    required String duration,
    required String price,
    required Color color,
    required String type,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(2, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.local_offer, color: color, size: 48),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text("⏱️ $duration", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("💰 $price", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => navigateToForm(context, type),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text("اختر هذه الباقة"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: "اختر باقة الإعلان",
      ownerId: ownerId,
      currentIndex: 2, // اختر الرقم المناسب حسب مكان الصفحة
      unreadBookingCount: unreadBookingCount,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildPackageCard(
              context: context,
              title: "باقة التمييز",
              description: "ظهور الملعب في أول القائمة + شارة مميزة",
              duration: "7 أيام",
              price: "2.000 ريال",
              color: Colors.orange,
              type: "highlight",
            ),
            buildPackageCard(
              context: context,
              title: "باقة السلايدر",
              description: "إعلان بصري يظهر في الصفحة الرئيسية",
              duration: "5 أيام",
              price: "3.000 ريال",
              color: Colors.blue,
              type: "slider",
            ),
            buildPackageCard(
              context: context,
              title: "الباقة الذهبية",
              description: "تشمل السلايدر + التمييز + تقارير الأداء",
              duration: "10 أيام",
              price: "5.000 ريال",
              color: Colors.purple,
              type: "full",
            ),
          ],
        ),
      ),
    );
  }
}
