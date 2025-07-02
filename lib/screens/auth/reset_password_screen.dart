import 'package:flutter/material.dart';
import 'package:booking_demo/screens/auth/login_screen.dart';
import 'package:booking_demo/services/user_service.dart';
import 'package:booking_demo/services/owner_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;
  final bool isOwner;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
    this.isOwner = false,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool _obscureText = true;
  bool isLoading = false;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _submitReset() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.length < 6) {
      showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    if (password != confirmPassword) {
      showError('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (widget.isOwner) {
        await OwnerService.resetPassword(widget.email, widget.code, password, confirmPassword);
      } else {
        await UserService.resetPassword(widget.email, widget.code, password, confirmPassword);
      }

      setState(() => isLoading = false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => isLoading = false);
      showError('❗ فشل في تغيير كلمة المرور: $e');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: Colors.white,

      // ✅ AppBar رسمي يغطي الشريط العلوي بالكامل
      appBar: AppBar(
        backgroundColor: const Color(0xFF22235D),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'إعادة تعيين كلمة السر',
          style: TextStyle(
            fontFamily: 'NotoKufiArabic',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'أدخل كلمة المرور الجديدة',
              style: TextStyle(
                fontFamily: 'NotoKufiArabic',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  buildLabel('كلمة المرور الجديدة'),
                  buildPasswordField(_passwordController),
                  const SizedBox(height: 20),
                  buildLabel('تأكيد كلمة المرور'),
                  buildPasswordField(_confirmPasswordController),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'تعيين',
                        style: TextStyle(
                          fontFamily: 'NotoKufiArabic',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'NotoKufiArabic',
        fontSize: 14,
        color: Colors.grey[700],
      ),
    );
  }

  Widget buildPasswordField(TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
