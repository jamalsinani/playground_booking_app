import 'package:flutter/material.dart';
import 'package:booking_demo/widgets/user_base_screen.dart';
import 'package:booking_demo/services/user_service.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final int userId;
  const PrivacyPolicyScreen({super.key, required this.userId});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String policyText = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPolicy();
  }

  Future<void> fetchPolicy() async {
    try {
      final text = await UserService.fetchPrivacyPolicy();
      setState(() {
        policyText = text;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        policyText = 'حدث خطأ أثناء تحميل سياسة الخصوصية.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserBaseScreen(
      title: 'سياسة الخصوصية',
      userId: widget.userId,
      currentIndex: 0,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
                  const Text(
                    '',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    policyText,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
    );
  }
}
