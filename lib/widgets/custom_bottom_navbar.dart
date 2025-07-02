import 'package:flutter/material.dart';
import 'package:booking_demo/screens/owner/owner_profile_screen.dart';
import 'package:booking_demo/screens/owner/owner_bookings_screen.dart';
import 'package:booking_demo/screens/owner/owner_home_screen.dart';
import 'package:booking_demo/screens/owner/owner_settings_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final int unreadBookingCount;
  final int ownerId;
  final Function(int)? onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.ownerId,
    this.unreadBookingCount = 0,
    this.onTap,
  }) : super(key: key);

  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;
    
    Widget screen;
    switch (index) {
      case 0:
        screen = OwnerSettingsScreen(ownerId: ownerId);
        break;
      case 1:
        screen = OwnerProfileScreen(ownerId: ownerId);
        break;
      case 2:
        screen = OwnerBookingsScreen(ownerId: ownerId);
        break;
      case 3:
      default:
        screen = OwnerHomeScreen(ownerId: ownerId);
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => onTap != null ? onTap!(index) : _handleNavigation(context, index),
      backgroundColor: const Color(0xFF1E2761),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'الإعدادات',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'حسابي',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.assignment_outlined),
              if (unreadBookingCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadBookingCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          label: 'الحجوزات',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'الرئيسية',
        ),
      ],
    );
  }
}