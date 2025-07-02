import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../widgets/owner_base_screen.dart';
import 'package:booking_demo/screens/owner/owner_home_screen.dart';
import 'package:booking_demo/screens/owner/owner_profile_screen.dart';
import 'package:booking_demo/screens/owner/booking_view_screen.dart';

class OwnerBookingsScreen extends StatefulWidget {
  final int ownerId;

  const OwnerBookingsScreen({super.key, required this.ownerId});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  List bookings = [];
  List filteredBookings = [];
  bool isLoading = true;
  DateTime? selectedDate;
  String selectedStatus = 'الكل';
  int _selectedIndex = 2;

  final List<String> statusOptions = ['الكل', 'مؤكد', 'ملغى', 'قيد المراجعة'];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchBookings();
    markBookingsAsSeen();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchBookings() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('https://darajaty.net/api/owner/${widget.ownerId}/bookings');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bookings = data;
          applyFilters();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('❌ فشل في جلب الحجوزات: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ خطأ أثناء جلب الحجوزات: $e');
    }
  }

  Future<void> markBookingsAsSeen() async {
    try {
      final url = Uri.parse('https://darajaty.net/api/owner/${widget.ownerId}/bookings/mark-as-seen');
      await http.post(url);
    } catch (e) {
      print('⚠️ لم يتم تحديث حالة المشاهدة: $e');
    }
  }

  void applyFilters() {
  setState(() {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    filteredBookings = bookings.where((b) {
      final matchesDate = selectedDate == null
          || b['date'].toString().substring(0, 10) == selectedDate!.toIso8601String().split('T')[0];

      final matchesStatus = selectedStatus == 'الكل'
          || getStatusText(b['status'] ?? 'pending') == selectedStatus;

      return matchesDate && matchesStatus;
    }).toList();

    // ✅ هنا نرتب النتائج قيد المراجعة أولاً (مباشرة بعد الفلترة)
    filteredBookings.sort((a, b) {
      int priority(String? status) {
        if (status == 'pending' || status == null) return 0;
        if (status == 'confirmed') return 1;
        if (status == 'canceled') return 2;
        return 3;
      }

      return priority(a['status']).compareTo(priority(b['status']));
    });
  });
}

  Future<void> showDateSelector() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        applyFilters();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OwnerHomeScreen(ownerId: widget.ownerId)),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OwnerProfileScreen(ownerId: widget.ownerId)),
      );
    }
  }

  void _onAddPressed() {}

  Color getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'مؤكد';
      case 'canceled':
        return 'ملغى';
      default:
        return 'قيد المراجعة';
    }
  }

List _todayBookings() {
  final today = DateTime.now().toIso8601String().split('T')[0];
  final List allToday = filteredBookings.where((b) => b['date'] == today).toList();

  // ✅ نرتب يدويًا: قيد المراجعة أولاً
  allToday.sort((a, b) {
    String statusA = a['status'] ?? 'pending';
    String statusB = b['status'] ?? 'pending';

    int priority(String status) {
      if (status == 'pending') return 0;
      if (status == 'confirmed') return 1;
      if (status == 'canceled') return 2;
      return 3;
    }

    return priority(statusA).compareTo(priority(statusB));
  });

  return allToday;
}

  List _previousBookings() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return filteredBookings.where((b) => b['date'].compareTo(today) < 0).toList();
  }

  List _upcomingBookings() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return filteredBookings.where((b) => b['date'].compareTo(today) > 0).toList();
  }

  Widget _buildBookingCard(dynamic booking) {
  final stadium = booking['stadium'];
  final stadiumName = (stadium is Map && stadium['name'] != null)
      ? stadium['name']
      : 'غير معروف';

  final status = booking['status'] ?? 'pending';

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingViewScreen(
              booking: booking,
              ownerId: widget.ownerId,
            ),
          ),
        );
        if (updated == true) fetchBookings();
      },
      leading: const Icon(Icons.sports_soccer, color: Colors.blue),
      title: Text('ملعب: $stadiumName', style: const TextStyle(fontSize: 14)),
      subtitle: Text('التاريخ: ${booking['date']}\nالوقت: ${booking['start_time']}', style: const TextStyle(fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: getStatusColor(status).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          getStatusText(status),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: getStatusColor(status)),
        ),
      ),
    ),
  );
}

  Widget buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'حجوزات ملاعبي',
      ownerId: widget.ownerId,
      currentIndex: _selectedIndex,
      unreadBookingCount: 0,
      onTap: _onItemTapped,
      onAddPressed: _onAddPressed,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // ✅ واجهة الفلاتر + شريط عدد النتائج
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: showDateSelector,
                            icon: const Icon(Icons.event_note, size: 16, color: Colors.white),
                            label: const Text('فلترة بالتاريخ', style: TextStyle(fontSize: 13, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF269F49),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            items: statusOptions.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedStatus = value;
                                  applyFilters();
                                });
                              }
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.deepPurple, width: 1.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedDate != null || selectedStatus != 'الكل') ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                            selectedStatus = 'الكل';
                            applyFilters();
                          });
                        },
                        icon: const Icon(Icons.clear_all, color: Colors.grey, size: 16),
                        label: const Text('مسح الكل', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'عدد النتائج: ${filteredBookings.length} ${filteredBookings.length == 1 ? "حجز" : "حجوزات"}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ عرض الحجوزات
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredBookings.isEmpty
                      ? const Center(child: Text('لا توجد حجوزات'))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (_todayBookings().isNotEmpty) ...[
                              buildSectionHeader("حجوزات اليوم", Icons.today, Colors.green),
                              const SizedBox(height: 8),
                              ..._todayBookings().map(_buildBookingCard).toList(),
                              const SizedBox(height: 16),
                            ],
                            if (_upcomingBookings().isNotEmpty) ...[
                              buildSectionHeader("حجوزات قادمة", Icons.schedule, Colors.blue),
                              const SizedBox(height: 8),
                              ..._upcomingBookings().map(_buildBookingCard),
                              const SizedBox(height: 16),
                            ],
                            if (_previousBookings().isNotEmpty) ...[
                              buildSectionHeader("حجوزات سابقة", Icons.history, Colors.grey),
                              const SizedBox(height: 8),
                              ..._previousBookings().map(_buildBookingCard),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}