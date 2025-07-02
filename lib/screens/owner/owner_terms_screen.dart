import 'package:flutter/material.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';
import 'package:booking_demo/services/user_service.dart';

class OwnerTermsScreen extends StatefulWidget {
  final int ownerId;

  const OwnerTermsScreen({super.key, required this.ownerId});

  @override
  State<OwnerTermsScreen> createState() => _OwnerTermsScreenState();
}

class _OwnerTermsScreenState extends State<OwnerTermsScreen> {
  String termsText = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTerms();
  }

  Future<void> fetchTerms() async {
    try {
      final response = await UserService.fetchTerms();
      setState(() {
        termsText = response ?? '❌ لم يتم العثور على النص.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        termsText = '⚠️ حدث خطأ أثناء جلب البيانات';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'الشروط والأحكام',
      ownerId: widget.ownerId,
      currentIndex: 0,
      unreadBookingCount: 0,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Text(termsText, style: const TextStyle(fontSize: 16)),
              ),
      ),
    );
  }
}
