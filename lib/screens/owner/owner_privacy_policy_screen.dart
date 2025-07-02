import 'package:flutter/material.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';
import 'package:booking_demo/services/user_service.dart';

class OwnerPrivacyPolicyScreen extends StatefulWidget {
  final int ownerId;

  const OwnerPrivacyPolicyScreen({super.key, required this.ownerId});

  @override
  State<OwnerPrivacyPolicyScreen> createState() => _OwnerPrivacyPolicyScreenState();
}

class _OwnerPrivacyPolicyScreenState extends State<OwnerPrivacyPolicyScreen> {
  String policyText = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPolicy();
  }

  Future<void> fetchPolicy() async {
    try {
      final response = await UserService.fetchPrivacyPolicy();
      setState(() {
        policyText = response ?? '❌ لم يتم العثور على النص.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        policyText = '⚠️ حدث خطأ أثناء جلب البيانات';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'سياسة الخصوصية',
      ownerId: widget.ownerId,
      currentIndex: 0,
      unreadBookingCount: 0,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Text(policyText, style: const TextStyle(fontSize: 16)),
              ),
      ),
    );
  }
}
