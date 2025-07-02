import 'package:flutter/material.dart';
import 'package:booking_demo/screens/auth/forgot_password_screen.dart';
import 'package:booking_demo/screens/auth/reset_password_screen.dart';
import 'package:booking_demo/services/user_service.dart';
import 'package:booking_demo/services/owner_service.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  final bool isOwner;

  const VerifyCodeScreen({
    super.key,
    required this.email,
    this.isOwner = false,
  });

  @override
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

  @override
  void dispose() {
    _focusNodes.forEach((node) => node.dispose());
    _controllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();

    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال جميع الأرقام الأربعة')),
      );
      return;
    }

    bool success = false;

    if (widget.isOwner) {
      success = await OwnerService.verifyCode(widget.email, code);
    } else {
      success = await UserService.verifyCode(widget.email, code);
    }

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            code: code,
            isOwner: widget.isOwner,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرمز غير صحيح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ✅ الخلفية الزرقاء المائلة
            ClipPath(
              clipper: TopDiagonalClipper(),
              child: Container(
                height: 280, // يغطي أعلى الشاشة بشكل جيد
                color: const Color(0xFF22235D),
              ),
            ),

            SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ForgotPasswordScreen(isOwner: widget.isOwner),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      'assets/images/verify.png',
                      height: 160,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'إدخال الرقم السري',
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
                    'يرجى إدخال الرقم السري المرسل إلى البريد الإلكتروني لتغيير كلمة المرور',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      final reversedIndex = 3 - index;
                      return SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _controllers[reversedIndex],
                          focusNode: _focusNodes[reversedIndex],
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          maxLength: 1,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 20),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && reversedIndex < 3) {
                              FocusScope.of(context)
                                  .requestFocus(_focusNodes[reversedIndex + 1]);
                            } else if (value.isEmpty && reversedIndex > 0) {
                              FocusScope.of(context)
                                  .requestFocus(_focusNodes[reversedIndex - 1]);
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22235D),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'تأكيد',
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
          ],
        ),
      ),
    );
  }
}

class TopDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60); // الجزء المائل
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
