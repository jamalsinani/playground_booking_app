import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:booking_demo/screens/owner/add_stadium_screen.dart';
import 'package:booking_demo/screens/owner/owner_profile_screen.dart';
import 'package:booking_demo/screens/owner/stadium_detail_screen.dart';
import 'package:booking_demo/screens/owner/owner_bookings_screen.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';
import 'package:booking_demo/services/owner_service.dart';
import 'package:booking_demo/services/owner_stadium_service.dart';
import 'package:booking_demo/services/notification_service.dart';

class OwnerHomeScreen extends StatefulWidget {
  final int ownerId;

  const OwnerHomeScreen({super.key, required this.ownerId});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  List stadiums = [];
  int _selectedIndex = 3;
  String ownerName = '';
  bool isLoading = true;
  String? profileImageUrl;
  int unreadBookingCount = 0;
  int totalBookingCount = 0;

  @override
  void initState() {
    super.initState();
    fetchOwnerData();
    fetchStadiums();
    fetchUnreadBookings();
    fetchBookingCount();
  }

  Future<void> fetchOwnerData() async {
  try {
    final response = await http.get(
      Uri.parse('https://darajaty.net/api/owner/${widget.ownerId}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      print('📦 بيانات المالك: $data');

      setState(() {
        ownerName = data['name'] ?? '';

        if (data['profile_image'] != null &&
            data['profile_image'].toString().isNotEmpty) {
          profileImageUrl = data['profile_image'];
        } else {
          profileImageUrl = null;
        }

        isLoading = false;
      });
    } else {
      print('❌ فشل في جلب البيانات: ${response.statusCode}');
      setState(() => isLoading = false);
    }
  } catch (e) {
    print('❌ خطأ في الجلب: $e');
    setState(() => isLoading = false);
  }
}

  Future<void> fetchStadiums() async {
    try {
      final data = await OwnerStadiumService.fetchStadiumsByOwner(widget.ownerId);
      setState(() {
        stadiums = data;
      });
    } catch (e) {
      print('❌ فشل في جلب الملاعب: $e');
    }
  }

  Future<void> fetchUnreadBookings() async {
  try {
    final count = await NotificationService.fetchUnreadBookingCount(widget.ownerId);
    print('📬 عدد الحجوزات غير المقروءة: $count');
    setState(() {
      unreadBookingCount = count;
    });
  } catch (e) {
    print('❌ فشل في جلب عدد الحجوزات غير المقروءة: $e');
  }
}


  Future<void> fetchBookingCount() async {
    try {
      final url = Uri.parse(
          'https://darajaty.net/api/owner/${widget.ownerId}/bookings/count');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          totalBookingCount = result['count'] ?? 0;
        });
      }
    } catch (e) {
      print('❌ فشل في جلب عدد الحجوزات: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) return;

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerProfileScreen(ownerId: widget.ownerId),
        ),
      );
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerBookingsScreen(ownerId: widget.ownerId),
        ),
      ).then((_) {
        fetchUnreadBookings();
        fetchBookingCount();
      });
    }
  }

  void _onAddPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStadiumScreen(ownerId: widget.ownerId),
      ),
    ).then((_) => fetchStadiums());
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'الصفحة الرئيسية',
      ownerId: widget.ownerId,
      currentIndex: _selectedIndex,
      unreadBookingCount: unreadBookingCount,
      //onTap: _onItemTapped,
      onAddPressed: _onAddPressed,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
  radius: 30,
  backgroundColor: Colors.grey.shade200,
  backgroundImage: profileImageUrl != null
      ? NetworkImage(profileImageUrl!)
      : const AssetImage('assets/images/owner.png') as ImageProvider,
  child: profileImageUrl == null
      ? const Icon(Icons.person, size: 40, color: Colors.grey)
      : null,
),


                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('أهلاً بك،',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey)),
                        Text(
                          ownerName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _onAddPressed,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('إضافة ملعب جديد',  style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: buildStatCard('عدد الحجوزات', '$totalBookingCount',
                          Icons.bar_chart, Colors.deepPurple),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildStatCard(
                          'عدد الملاعب المعتمدة',
                          '${stadiums.length}',
                          Icons.sports_soccer,
                          Colors.indigo),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text('ملاعبك المعتمدة',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (stadiums.isEmpty)
                  const Text("لا توجد ملاعب معتمدة حتى الآن.")
                else
                  SizedBox(
  height: 190,
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: stadiums.map((stadium) {
        final String imageUrl = stadium['image'] ?? '';
        final bool isActive = stadium['is_active'] == 1;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StadiumDetailScreen(
                  stadiumId: stadium['id'],
                  stadiumName: stadium['name'],
                  ownerId: widget.ownerId,
                ),
              ),
            );
          },
          child: Container(
            width: 160,
            height: 190,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(2, 4),
                ),
              ],
              image: DecorationImage(
                image: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const AssetImage('assets/images/stadium_default.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'مفعل ✅' : 'غير مفعل ❌',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
  bottom: 12,
  left: 12,
  right: 12,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 👈 اسم الملعب
          Expanded(
            child: Text(
              stadium['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          // ⭐ التقييم وعدد التقييمات (يظهر دائمًا حتى لو صفر)
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                '${stadium['average_rating'] ?? 0.0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${stadium['rating_count'] ?? 0})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 3),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
),

              ],
            ),
          ),
        );
      }).toList(),
    ),
  ),
),
              ],
          ),
    );
  }

  Widget buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} 