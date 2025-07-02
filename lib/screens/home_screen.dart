import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../services/stadium_service.dart';
import '../services/favorite_service.dart';
import '../widgets/user_bottom_navbar.dart';
import 'user/stadium_booking_screen.dart';
import 'user/components/favorite_share_buttons.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'common/notifications_screen.dart';
import 'user/stadium_rating_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<int> favoriteStadiumIds = {};
  final PageController _pageController = PageController();
  Timer? _sliderTimer;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> stadiums = [];
  List<Map<String, dynamic>> filteredStadiums = [];
  List<Map<String, dynamic>> topRatedStadiums = [];
  List<Map<String, dynamic>> mostBookedStadiums = [];
  List<String> adImages = [];
  
  int unreadCount = 0; 
  int totalBookings = 0;
  int totalVisitors = 0;
  bool isLoading = true;
  
  void checkPendingRating() async {
  print('🚀 بدء فحص الحجوزات غير المقيمة...');

  final url = Uri.parse('https://darajaty.net/api/user/${widget.userId}/bookings');

  try {
    final response = await http.get(url);
    print('📡 Status: ${response.statusCode}');
    print('📥 Response: ${response.body}');

    if (response.statusCode == 200) {
      final List bookings = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      bool foundPending = false;

      for (var booking in bookings) {
        final bookingId = booking['id']?.toString() ?? 'غير معروف';

        // تحقق من الحالة والتقييم
        if (booking['status'] != 'تم التأكيد' || booking['is_rated'] == true) {
          print('⏩ تجاوز الحجز $bookingId (الحالة: ${booking['status']}, is_rated: ${booking['is_rated']})');
          continue;
        }

        final dateStr = booking['date'];
        final timeStr = booking['start_time'];
        final duration = int.tryParse(booking['duration'].toString()) ?? 60;

        final startDateTime = _parseBookingDateTime(dateStr, timeStr);
        if (startDateTime == null) {
          print('❌ لا يمكن تحليل وقت الحجز $bookingId');
          continue;
        }

        final endTime = startDateTime.add(Duration(minutes: duration));
        final now = DateTime.now();
        final diff = now.difference(endTime).inMinutes;

        print('🧪 حجز $bookingId:');
        print('    - التاريخ: $dateStr');
        print('    - الوقت: $timeStr');
        print('    - المدة: $duration دقيقة');
        print('    - وقت البداية: $startDateTime');
        print('    - وقت النهاية: $endTime');
        print('    - الآن: $now');
        print('    - الفرق بين الآن والنهاية: $diff دقيقة');

        if (now.isAfter(endTime.subtract(const Duration(minutes: 5)))) {
          final key = 'rated_prompt_$bookingId';

          // للتجربة فقط: أزل هذا المفتاح مؤقتًا
          await prefs.remove(key);

          if (prefs.getBool(key) == true) {
            print('🔕 الرسالة لهذا الحجز $bookingId عُرضت من قبل');
            continue;
          }

          print('✅ الحجز $bookingId مؤهل لعرض رسالة التقييم');
          _showRatingDialog(booking);
          await prefs.setBool(key, true);
          foundPending = true;
        } else {
          print('⏳ الحجز $bookingId لم ينتهِ بعد');
        }
      }

      if (!foundPending) {
        print('ℹ️ لا يوجد أي حجز مؤهل حاليًا لعرض رسالة التقييم.');
      }
    }
  } catch (e) {
    print('❌ فشل في التحقق من التقييمات: $e');
  }
}


    DateTime? _parseBookingDateTime(String dateStr, String timeStr) {
    try {
      final date = DateTime.parse(dateStr);

      final isPM = timeStr.contains('مساء');
      final cleanTime = timeStr.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = cleanTime.split(':');
      if (parts.length < 2) return null;

      int hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      print('❌ خطأ في تحليل التاريخ والوقت: $e');
      return null;
    }
  }



void _showRatingDialog(Map<String, dynamic> booking) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final bookingId = booking['id'] is int 
        ? booking['id'] 
        : int.tryParse(booking['id'].toString()) ?? 0;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.leftSlide,
      title: '⭐ حان وقت التقييم!',
      desc: 'هل ترغب بتقييم ملعب "${booking['stadium']['name']}"؟',
      btnCancelText: 'لاحقًا',
      btnCancelOnPress: () {},
      btnOkText: 'قيّم الآن',
      btnOkOnPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StadiumRatingScreen(
              userId: widget.userId,
              stadiumId: booking['stadium']['id'],
              bookingId: bookingId,
            ),
          ),
        );
      },
    ).show();
  });
}
  @override
  void initState() {
    super.initState();

    fetchUnreadNotificationCount(); 
      FirebaseMessaging.instance.getToken().then((token) {
    print('📱 FCM Token: $token');
  });
  
    fetchStadiumData();
    fetchAds();
    _fetchStats();
    loadFavorites();
    checkPendingRating();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.notification != null) {
    final title = message.notification!.title;
    final body = message.notification!.body;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title ?? 'تنبيه'),
        content: Text(body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }
});

    _searchController.addListener(() {
      setState(() {});
    });
  }
  
  Future<void> fetchUnreadNotificationCount() async {
  final url = Uri.parse('https://darajaty.net/api/notifications?user_id=${widget.userId}&unread=1');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'];
      setState(() {
        unreadCount = data.length;
      });
    }
  } catch (e) {
    print('❌ فشل في جلب عدد الإشعارات: \$e');
  }
}

  Future<void> loadFavorites() async {
    try {
      final favorites = await FavoriteService.fetchFavorites(widget.userId);
      final ids = favorites.map<int>((s) => s['id'] as int).toSet();

      setState(() {
        favoriteStadiumIds
          ..clear()
          ..addAll(ids);
      });
    } catch (e) {
      print('❌ فشل تحميل المفضلة: $e');
    }
  }

  void _fetchStats() async {
    try {
      final bookings = await StadiumService.fetchTotalBookings();
      final visitors = await StadiumService.fetchTotalUsers();
      setState(() {
        totalBookings = bookings;
        totalVisitors = visitors;
      });
    } catch (e) {
      print('❌ فشل تحميل الإحصائيات: $e');
    }
  }

  Future<void> fetchAds() async {
    try {
      final images = await StadiumService.fetchAdImages();

      setState(() => adImages = images);

      if (adImages.isNotEmpty) {
        _sliderTimer?.cancel();
        _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
          if (_pageController.hasClients) {
            int nextPage = (_pageController.page?.round() ?? 0) + 1;
            if (nextPage >= adImages.length) nextPage = 0;
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e) {
      print('❌ فشل تحميل الإعلانات: $e');
    }
  }

  Future<void> fetchStadiumData() async {
  try {
    final all = await StadiumService.fetchStadiumsWithStats();

    // ✅ فلترة الملاعب المعتمدة والمتاحة فقط
    final filtered = all.where((s) {
      final isAvailable = s['is_available'];
      final isApproved = s['is_approved'];

      final available = isAvailable != null &&
          (isAvailable.toString() == '1' || isAvailable == 1 || isAvailable == true);
      final approved = isApproved != null &&
          (isApproved.toString() == '1' || isApproved == 1 || isApproved == true);

      return available && approved;
    }).toList();

    setState(() {
      stadiums = filtered;
      filteredStadiums = filtered;

      // ✅ الملاعب الأعلى تقييمًا (مع الشروط)
      topRatedStadiums = [
        ...all.where((s) {
          final isAvailable = s['is_available'];
          final isApproved = s['is_approved'];

          final available = isAvailable != null &&
              (isAvailable.toString() == '1' || isAvailable == 1 || isAvailable == true);
          final approved = isApproved != null &&
              (isApproved.toString() == '1' || isApproved == 1 || isApproved == true);

          final rating = s['average_rating'];
          final parsed = rating is num ? rating : num.tryParse(rating.toString()) ?? 0;

          return available && approved && parsed > 0;
        })
      ]..sort((a, b) {
          final aRating = a['average_rating'] is num
              ? a['average_rating']
              : num.tryParse(a['average_rating'].toString()) ?? 0;
          final bRating = b['average_rating'] is num
              ? b['average_rating']
              : num.tryParse(b['average_rating'].toString()) ?? 0;
          return bRating.compareTo(aRating);
        });

      // ✅ الملاعب الأعلى حجزًا (مع الشروط)
      mostBookedStadiums = [
        ...all.where((s) {
          final isAvailable = s['is_available'];
          final isApproved = s['is_approved'];

          final available = isAvailable != null &&
              (isAvailable.toString() == '1' || isAvailable == 1 || isAvailable == true);
          final approved = isApproved != null &&
              (isApproved.toString() == '1' || isApproved == 1 || isApproved == true);

          final count = s['booking_count'];
          final parsed = count is int ? count : int.tryParse(count.toString()) ?? 0;

          return available && approved && parsed > 0;
        })
      ]..sort((a, b) {
          final aCount = a['booking_count'] is int
              ? a['booking_count']
              : int.tryParse(a['booking_count'].toString()) ?? 0;
          final bCount = b['booking_count'] is int
              ? b['booking_count']
              : int.tryParse(b['booking_count'].toString()) ?? 0;
          return bCount.compareTo(aCount);
        });

      isLoading = false;
    });
  } catch (e) {
    print('❌ Error fetching stadiums with stats: $e');
    setState(() => isLoading = false);
  }
}





  void filterStadiums(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      setState(() => filteredStadiums = stadiums);
      return;
    }

    final results = stadiums.where((stadium) {
      final name = (stadium['name'] ?? '').toString().toLowerCase();
      return name.contains(normalizedQuery);
    }).toList();

    setState(() => filteredStadiums = results);
  }

  void handleNavTap(int index) {}

  @override
  void dispose() {
    _pageController.dispose();
    _sliderTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22235D),
      body: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    children: [
      Expanded(
        child: TextField(
          controller: _searchController,
          onChanged: filterStadiums,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ابحث عن ملعب...',
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white12,
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _searchController.clear();
                      setState(() => filteredStadiums = stadiums);
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            tooltip: 'الإشعارات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('الإشعارات'),
                      centerTitle: true, 
                      backgroundColor: const Color(0xFF22235D),
                      foregroundColor: Colors.white,
                    ),
                    body: NotificationsScreen(userId: widget.userId),
                    bottomNavigationBar: UserBottomNavBar(
                      currentIndex: 3,
                      onTap: (_) {},
                      userId: widget.userId,
                    ),
                  ),
                ),
              );
            },
          ),
          if (unreadCount > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    ],
  ),
),


          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        if (_searchController.text.trim().isEmpty) ...[
                          if (adImages.isNotEmpty) _buildAdSlider(),
                          if (adImages.isNotEmpty)
                            Center(
                              child: SmoothPageIndicator(
                                controller: _pageController,
                                count: adImages.length,
                                effect: const ExpandingDotsEffect(
                                  dotHeight: 8,
                                  dotWidth: 8,
                                  activeDotColor: Colors.green,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(child: buildCompactStatsCard(Icons.sports_soccer, 'الحجوزات', totalBookings.toString())),
                                const SizedBox(width: 10),
                                Expanded(child: buildCompactStatsCard(Icons.stadium, 'الملاعب', stadiums.length.toString())),
                                const SizedBox(width: 10),
                                Expanded(child: buildCompactStatsCard(Icons.person, 'الزوار', totalVisitors.toString())),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildHorizontalStadiumList(topRatedStadiums, 'الملاعب الأعلى تقييمًا'),
                          if (mostBookedStadiums.isNotEmpty)
  _buildHorizontalStadiumList(mostBookedStadiums, 'الملاعب الأعلى حجزًا')
else
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      'لا توجد ملاعب عليها حجوزات حتى الآن',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey[600]),
    ),
  ),

                          _buildHorizontalStadiumList(stadiums, 'كل الملاعب'),
                        ] else ...[
                          _buildHorizontalStadiumList(filteredStadiums, 'نتائج البحث'),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: UserBottomNavBar(
        currentIndex: 3,
        onTap: handleNavTap,
        userId: widget.userId,
      ),
    );
  }

  Widget _buildAdSlider() {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _pageController,
        itemCount: adImages.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = (_pageController.page! - index).abs();
                value = (1 - (value * 0.3)).clamp(0.0, 1.0);
              }
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: value,
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                adImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalStadiumList(List<Map<String, dynamic>> list, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 8),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Divider(thickness: 1.5, endIndent: 10, color: Colors.blue),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF22235D)),
              ),
              const Expanded(
                child: Divider(thickness: 1.5, indent: 10, color: Colors.purple),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final stadium = list[index];
              final rating = stadium['average_rating'] ?? 0.0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StadiumBookingScreen(
                        stadiumName: stadium['name'] ?? 'ملعب بدون اسم',
                        imageUrl: '',
                        price: stadium['price_per_hour']?.toString() ?? '',
                        stadiumId: stadium['id'],
                        location: stadium['location'] ?? 'موقع غير محدد',
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stadium['name'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'السعر: ${stadium['price_per_hour']} ريال / ساعة',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        '📍 ${stadium['location'] ?? 'غير محدد'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < rating.round() ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '(${stadium['rating_count'] ?? 0} تقييم)',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (rating >= 4.5)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('🏅 TOP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          const Spacer(),
                          FavoriteShareButtons(
                            userId: widget.userId,
                            stadiumId: stadium['id'],
                            onFavoriteToggle: () async => await loadFavorites(),
                            shareText: 'شاهد هذا الملعب الرائع: ${stadium['name'] ?? ''}!',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildCompactStatsCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22235D),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}