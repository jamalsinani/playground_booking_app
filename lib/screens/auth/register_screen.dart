import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:booking_demo/services/auth_service.dart';
import 'package:booking_demo/screens/auth/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isHajiz = true;
  bool hidePassword = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final TextStyle labelStyle = TextStyle(
    fontFamily: 'NotoKufiArabic',
    fontSize: 14,
    color: Colors.grey[600],
  );

  Future<void> registerStadiumOwner() async {
    print("📡 بدأ تسجيل صاحب الملعب");

    if (passwordController.text != confirmPasswordController.text) {
      showError('كلمتا المرور غير متطابقتين');
      return;
    }

    final result = await AuthService.registerStadiumOwner(
      name: nameController.text,
      email: emailController.text,
      phone: phoneController.text,
      password: passwordController.text,
      passwordConfirmation: confirmPasswordController.text,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم تسجيل صاحب الملعب بنجاح')),
      );
      clearFields();
    } else {
      handleRegisterError(result);
    }
  }

  Future<void> registerUser() async {
    print("📡 بدأ تسجيل المستخدم (حاجز)");

    if (passwordController.text != confirmPasswordController.text) {
      showError('كلمتا المرور غير متطابقتين');
      return;
    }

    final result = await AuthService.registerUser(
      name: nameController.text,
      email: emailController.text,
      phone: phoneController.text,
      password: passwordController.text,
      passwordConfirmation: confirmPasswordController.text,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم تسجيل المستخدم بنجاح')),
      );
      clearFields();
    } else {
      handleRegisterError(result);
    }
  }

  void handleRegisterError(result) {
    print('❌ فشل التسجيل: ${result['statusCode']}');
    print('Body: ${result['body']}');

    final body = json.decode(result['body']);
    if (body['errors'] != null) {
      final errors = body['errors'];
      if (errors.containsKey('email')) {
        showError(errors['email'][0]);
      } else if (errors.containsKey('phone')) {
        showError(errors['phone'][0]);
      } else {
        showError('حدث خطأ أثناء التسجيل.');
      }
    } else {
      showError('فشل في التسجيل. حاول مرة أخرى.');
    }
  }

  void clearFields() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.07),

          Image.asset('assets/images/signup.png', height: 200),
          SizedBox(height: 20),

          Text(
            'حساب جديد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoKufiArabic',
              color: Color(0xFF22235D),
            ),
          ),
          SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildUserTypeButton('صاحب ملعب', false),
              buildUserTypeButton('حاجز', true),
            ],
          ),
          SizedBox(height: 20),

          buildInputField('الاسم الكامل', Icons.person, nameController),
          buildInputField('الايميل', Icons.email, emailController),
          buildInputField('رقم الهاتف', Icons.phone, phoneController),
          buildInputField('كلمة المرور', Icons.lock, passwordController, isPassword: true),
          buildInputField('تأكيد كلمة المرور', Icons.lock_outline, confirmPasswordController, isPassword: true),

          SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {
              print("🚀 تم الضغط على زر إنشاء الحساب");
              if (isHajiz) {
                registerUser();
              } else {
                registerStadiumOwner();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF22235D),
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إنشاء حساب',
              style: TextStyle(fontFamily: 'NotoKufiArabic', fontSize: 16, color: Colors.white,),
            ),
          ),

          SizedBox(height: 20),

          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: Text(
                'هل لديك حساب بالفعل؟ تسجيل الدخول',
                style: TextStyle(
                  fontFamily: 'NotoKufiArabic',
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget buildUserTypeButton(String title, bool isCurrent) {
    bool isSelected = isCurrent == isHajiz;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isHajiz = isCurrent),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'NotoKufiArabic',
                fontSize: 15,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? hidePassword : false,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: labelStyle,
          border: UnderlineInputBorder(),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                )
              : null,
        ),
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $message')),
    );
  }
}
