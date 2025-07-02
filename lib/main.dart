import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user/stadium_booking_screen.dart';
import 'screens/user/about_app_screen.dart';
import 'screens/user/privacy_policy_screen.dart';
import 'screens/user/terms_screen.dart';
import 'screens/owner/owner_privacy_policy_screen.dart';
import 'screens/owner/owner_terms_screen.dart';
import 'screens/owner/owner_about_app_screen.dart';
import 'screens/owner/owner_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/favorite_stadiums_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/owner/ad_packages_screen.dart';
import 'screens/owner/owner_wallet_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 رسالة في الخلفية: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'الإشعارات المهمة',
  description: 'تُستخدم للإشعارات ذات الأهمية العالية',
  importance: Importance.high,
);

await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);


  // 🔔 جلب التوكن
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('✅ FCM Token: $fcmToken');

  // 📥 الرسائل في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔔 إعداد التنبيهات المحلية
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'الإشعارات المهمة',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'حجوزات الملاعب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Tajawal',
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      routes: {
        '/user/home': (context) => HomeScreen(userId: 1),
        '/user/bookings': (context) => StadiumBookingScreen(
              stadiumName: '',
              imageUrl: '',
              price: '',
              stadiumId: 0,
              location: '',
              userId: 1,
            ),
        '/login': (context) => LoginScreen(),
        '/auth/forgot-password': (context) => ForgotPasswordScreen(),
        '/owner/privacy': (context) => OwnerPrivacyPolicyScreen(ownerId: 1),
        '/owner/terms': (context) => OwnerTermsScreen(ownerId: 1),
        '/owner/about': (context) => OwnerAboutAppScreen(ownerId: 1),
        '/owner/wallet': (context) => const OwnerWalletScreen(),
        '/about': (context) => const AboutAppScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(userId: 1),
        '/terms': (context) => const TermsScreen(userId: 1),
        '/favorites': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return FavoriteStadiumsScreen(userId: args);
        },
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/owner/ADS':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AdPackagesScreen(
                ownerId: args['ownerId'],
                unreadBookingCount: args['unreadBookingCount'] ?? 0,
              ),
            );
          default:
            return null;
        }
      },
      home: const LandingScreen(), // ✅ شاشة البداية المحدثة
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final bookingId = data['booking_id'];

    if (type == 'booking_confirmed' && bookingId != null) {
      navigatorKey.currentState?.pushNamed(
        '/user/bookings',
        arguments: {'bookingId': int.parse(bookingId)},
      );
    } else if (type == 'booking_request') {
      navigatorKey.currentState?.pushNamed(
        '/owner/ADS',
        arguments: {
          'ownerId': 1,
          'unreadBookingCount': 0,
        },
      );
    }
  }
}

// ✅ كلاس جديد لتحديد الصفحة المناسبة عند التشغيل
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<Widget> _determineStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final role = prefs.getString('role');

    if (userId != null && role != null) {
      if (role == 'owner') {
        return OwnerHomeScreen(ownerId: userId);
      } else {
        return HomeScreen(userId: userId);
      }
    }

    return LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        } else {
          return snapshot.data ?? LoginScreen();
        }
      },
    );
  }
}