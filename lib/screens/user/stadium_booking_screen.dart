import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import '../../services/stadium_service.dart';
import '../../services/user_service.dart';
import '../../widgets/user_base_screen.dart';
import 'components/stadium_ratings_tab.dart';
import 'components/stadium_about_tab.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class StadiumBookingScreen extends StatefulWidget {
  final int userId;
  final String stadiumName;
  final String imageUrl;
  final String price;
  final int stadiumId;
  final String location;

  const StadiumBookingScreen({
    super.key,
    required this.stadiumName,
    required this.imageUrl,
    required this.price,
    required this.stadiumId,
    required this.location,
    required this.userId,
  });

  @override
  State<StadiumBookingScreen> createState() => _StadiumBookingScreenState();
}

class _StadiumBookingScreenState extends State<StadiumBookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String selectedTime = '';
  String duration = 'ساعة';
  bool isLoadingTimes = false;
  bool isLoadingRatings = true;

  List<String> availableTimes = [];
  List<String> rawAvailableTimes = [];
  Map<String, String> bookedTimes = {}; // ⬅️ hh:mm -> status

  List ratings = [];
  final List<String> durations = ['نصف ساعة', 'ساعة', 'ساعة ونصف', 'ساعتين'];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    fetchRatings();
    fetchAvailableTimes();
  }

  int _getDurationMinutes() {
    return {
      'نصف ساعة': 30,
      'ساعة': 60,
      'ساعة ونصف': 90,
      'ساعتين': 120,
    }[duration]!;
  }
   
  Future<void> fetchAvailableTimes() async {
  if (_selectedDay == null) return;

  final formattedDate =
      '${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}';

  final durationInMinutes = _getDurationMinutes(); // ✅ نستخدم الرقم بدلاً من النص

  final availableUrl =
      'https://darajaty.net/api/booking-plans/available/${widget.stadiumId}?date=$formattedDate&duration=$durationInMinutes';

  final bookedUrl =
      'https://darajaty.net/api/bookings/detailed/${widget.stadiumId}?date=$formattedDate';

  print("📡 رابط الأوقات المتاحة: $availableUrl");
  print("📡 رابط الأوقات المحجوزة: $bookedUrl");

  setState(() {
    isLoadingTimes = true;
    availableTimes = [];
    rawAvailableTimes = [];
    bookedTimes = {};
  });

  try {
    final availableRes = await http.get(Uri.parse(availableUrl));
    final bookedRes = await http.get(Uri.parse(bookedUrl));

    print('📛 Response status (available): ${availableRes.statusCode}, body: ${availableRes.body}');
    print('📛 Response status (booked): ${bookedRes.statusCode}, body: ${bookedRes.body}');

    if (availableRes.statusCode == 200 && bookedRes.statusCode == 200) {
      final result = json.decode(availableRes.body);
      final booked = json.decode(bookedRes.body);

      bookedTimes = {
        for (var item in booked) item['start_time']: item['status']
      };

      rawAvailableTimes = List<String>.from(result.map((item) => item['hour']));


      availableTimes = rawAvailableTimes.map<String>((slot) {
        final parts = slot.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final displayHour = hour.toString().padLeft(2, '0');
        final displayMinute = minute.toString().padLeft(2, '0');

        return '$displayHour:$displayMinute';
      }).toList();

      print("🟢 الأوقات المتاحة: $rawAvailableTimes");
      print("🟢 الأوقات المحجوزة: $bookedTimes");
    } else {
      throw Exception('فشل في جلب الأوقات أو الحجوزات');
    }
  } catch (e) {
    print('❌ خطأ في جلب الأوقات أو الحجوزات: $e');
  } finally {
    setState(() {
      isLoadingTimes = false;
    });
  }
}


  Future<void> submitBooking() async {
  if (_selectedDay == null || selectedTime.isEmpty || duration.isEmpty) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      title: 'تنبيه',
      desc: 'يرجى اختيار اليوم والوقت والمدة أولًا',
      btnOkText: 'موافق',
      btnOkOnPress: () {},
    ).show();
    return;
  }

  double basePrice = double.tryParse(widget.price) ?? 0;
  double multiplier = {
    'نصف ساعة': 0.5,
    'ساعة': 1.0,
    'ساعة ونصف': 1.5,
    'ساعتين': 2.0,
  }[duration]!;

  double totalPrice = basePrice * multiplier;

  try {
    final response = await http.post(
      Uri.parse('https://darajaty.net/api/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.userId,
        'stadium_id': widget.stadiumId,
        'date': _selectedDay!.toIso8601String().split("T")[0],
        'start_time': _formatTimeForServer(selectedTime),
        'duration': _getDurationMinutes(),
        'total_price': totalPrice,
      }),
    );

    if (response.statusCode == 200) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'شكرا لك',
        desc: '✅ تم ارسال طلبك بنجاح.. سيتم مراجعته من قبل المالك',
        btnOkText: 'حسنًا',
        btnOkOnPress: () {
          Navigator.pop(context);
        },
      ).show();
    } else if (response.statusCode == 409) {
      final decoded = jsonDecode(response.body);
      final message = decoded['message'] ?? '❌ الوقت متعارض مع حجز آخر';
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: 'خطأ',
        desc: message,
        btnOkText: 'إغلاق',
        btnOkOnPress: () {},
      ).show();
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: 'فشل الحجز',
        desc: '❌ فشل في تنفيذ الحجز. كود الحالة: ${response.statusCode}',
        btnOkText: 'إغلاق',
        btnOkOnPress: () {},
      ).show();
    }
  } catch (e) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      title: 'خطأ في الاتصال',
      desc: '❌ فشل الاتصال بالخادم: $e',
      btnOkText: 'إغلاق',
      btnOkOnPress: () {},
    ).show();
  }
}


  String _formatTimeForServer(String input) {
    final parts = input.split(' ');
    if (parts.length != 2) return input;

    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    final period = parts[1];

    if (period.contains('مساء') && hour < 12) hour += 12;
    if (period.contains('صباح') && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> fetchRatings() async {
    setState(() => isLoadingRatings = true);
    try {
      final result = await UserService.fetchRatingsForStadium(widget.stadiumId);
      setState(() {
        ratings = result;
        isLoadingRatings = false;
      });
    } catch (_) {
      setState(() => isLoadingRatings = false);
    }
  }

  Widget buildBookingTab() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🗓️ التقويم داخل بطاقة
        Padding(
  padding: const EdgeInsets.all(16),
  child: Card(
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Colors.green, width: 2),
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            selectedTime = '';
          });
          fetchAvailableTimes();
        },
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.green),
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_right, color: Colors.green),
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return Center(
              child: Text(
                '${day.day}',
                style: const TextStyle(color: Colors.black),
              ),
            );
          },
        ),
      ),
    ),
  ),
),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '⏰ اختر الوقت المتاح',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),

        // 🕒 التواقيت صف أفقي قابل للتمرير
        isLoadingTimes
            ? const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator()))
            : availableTimes.isEmpty
                ? const Center(child: Text('لا توجد أوقات متاحة لهذه المدة في هذا اليوم'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                          children: availableTimes.asMap().entries.map((entry) {
    final index = entry.key;
    final time = entry.value;
    final raw = rawAvailableTimes[index];
    final status = bookedTimes[raw];

    final isSelected = selectedTime == time;
    final isConfirmed = status == 'confirmed' || status == 'مؤكد';
    final isPending = status == 'بانتظار الموافقة';
    final isConflict = status == 'متضارب' || status == 'تضارب';
    final isCancelled = status == 'canceled' || status == 'ملغى';

    // ✅ الوقت الحالي والمنتهي
    final now = DateTime.now();
    final isToday = _selectedDay != null &&
        _selectedDay!.year == now.year &&
        _selectedDay!.month == now.month &&
        _selectedDay!.day == now.day;

    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    final slotTime = DateTime(now.year, now.month, now.day, hour, minute);
    final isExpired = isToday && slotTime.isBefore(now);

    final isDisabled = isConfirmed || isPending || isConflict || isExpired;

    final period = hour >= 12 ? 'مساءً' : 'صباحًا';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final displayTime = '$hour12:${minute.toString().padLeft(2, '0')}';

    final subtitle = isExpired
        ? 'متوفر'
        : isConfirmed
            ? 'مؤكد'
            : isPending
                ? 'بانتظار'
                : isConflict
                    ? 'تضارب'
                    : 'متوفر';

    final backgroundColor = isSelected
        ? Colors.green
        : isExpired
            ? Colors.grey.shade100
            : isPending
                ? Colors.orange[100]!
                : isConflict
                    ? Colors.grey.shade200
                    : Colors.white;

    final textColor = isExpired
        ? Colors.grey
        : isSelected
            ? Colors.white
            : isPending
                ? Colors.orange.shade800
                : isConflict
                    ? Colors.grey.shade700
                    : isConfirmed
                        ? Colors.grey
                        : Colors.black87;

    final borderColor = isSelected
        ? Colors.green.shade700
        : isPending
            ? Colors.orange
            : isConflict
                ? Colors.grey.shade400
                : Colors.grey.shade300;

    final box = GestureDetector(
      onTap: isDisabled ? null : () => setState(() => selectedTime = time),
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayTime,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              period,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: subtitle == 'متوفر'
                    ? Colors.green
                    : subtitle == 'تضارب'
                        ? Colors.grey
                        : textColor.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    // ✅ إذا منتهي، نضعه داخل Stack مع خط أحمر
    if (isExpired) {
      return Stack(
        children: [
          Opacity(opacity: 0.5, child: box),
          Positioned.fill(
            child: CustomPaint(
              painter: _StrikeThroughPainter(),
            ),
          ),
        ],
      );
    }

    // ✅ تضارب ومؤكد نعرضها باهتة فقط
    return isConfirmed || isConflict
        ? Opacity(opacity: 0.4, child: box)
        : box;
  }).toList(),
)
                ),

        const SizedBox(height: 20),

        // 📏 اختيار المدة الزمنية
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.green),
              onPressed: () {
                final index = durations.indexOf(duration);
                if (index > 0) {
                  setState(() {
                    duration = durations[index - 1];
                    selectedTime = ''; 
                  });
                  fetchAvailableTimes();
                }
              },
            ),
            Text(
              '$duration',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.green),
              onPressed: () {
                final index = durations.indexOf(duration);
                if (index < durations.length - 1) {
                  setState(() {
                    duration = durations[index + 1];
                    selectedTime = ''; 
                  });
                  fetchAvailableTimes();
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ✅ زر الحجز
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: submitBooking,
              icon: const Icon(Icons.check_circle),
              label: const Text('احجز الآن', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return UserBaseScreen(
      title: widget.stadiumName,
      userId: widget.userId,
      currentIndex: 2,
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: 'أوقات الحجز'),
                Tab(text: 'التقييمات'),
                Tab(text: 'عن الملعب'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  buildBookingTab(),
                  StadiumRatingsTab(ratings: ratings, isLoading: isLoadingRatings),
                  StadiumAboutTab(stadiumId: widget.stadiumId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 

class _StrikeThroughPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    // ✳️ نضيف هامش صغير من الأطراف (5 بكسل مثلاً)
    const margin = 6.0;

    // ↘ الخط الأول (من أعلى اليسار إلى أسفل اليمين داخل الحدود)
    canvas.drawLine(
      const Offset(margin, margin),
      Offset(size.width - margin, size.height - margin),
      paint,
    );

    // ↙ الخط الثاني (من أعلى اليمين إلى أسفل اليسار داخل الحدود)
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(margin, size.height - margin),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 