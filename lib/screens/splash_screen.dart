import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart'; // للوصول إلى HomePage
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  //const SplashScreen({super.key}); 
  
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // الانتقال بعد 3 ثوانٍ
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/الشعار.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 280,
          ),
        ),
      ),
    );
  }
}   