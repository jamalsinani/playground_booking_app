import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../widgets/user_base_screen.dart';
import '../../services/user_service.dart';
import 'stadium_rating_screen.dart';

class UserBookingsScreen extends StatefulWidget {
  final int userId;

  const UserBookingsScreen({super.key, required this.userId});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> with SingleTickerProviderStateMixin {
  List bookings = [];
  List filteredBookings = [];
  bool isLoading = true;
  DateTime? selectedDate;
  String selectedStatus = 'الكل';
  int? expandedIndex;

  final List<String> statusOptions = ['الكل', 'تم التأكيد', 'ملغي', 'بانتظار الموافقة'];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchUserBookings();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchUserBookings() async {
    try {
      final data = await UserService.fetchUserBookings(widget.userId);
      for (var booking in data) {
        final originalStatus = booking['status'];
        if (originalStatus == 'بانتظار الموافقة') {
          booking['status'] = 'pending';
        } else if (originalStatus == 'تم التأكيد') {
          booking['status'] = 'confirmed';
        } else if (originalStatus == 'ملغي') {
          booking['status'] = 'canceled';
        }
      }

      data.sort((a, b) {
        const order = {'confirmed': 0, 'pending': 1, 'canceled': 2};
        return (order[a['status']] ?? 3).compareTo(order[b['status']] ?? 3);
      });

      setState(() {
        bookings = data;
        applyFilters();
        isLoading = false;
        expandedIndex = null;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    setState(() {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      filteredBookings = bookings.where((b) {
        final matchesDate = selectedDate == null || b['date'] == selectedDate!.toIso8601String().split('T')[0];
        final matchesStatus = selectedStatus == 'الكل' || _translateStatus(b['status']) == selectedStatus;
        return matchesDate && matchesStatus;
      }).toList();
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

  Future<void> confirmCancelBooking(BuildContext context, int bookingId) async {
    try {
      await UserService.cancelBooking(bookingId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚫 تم إلغاء الحجز بنجاح')));
      await fetchUserBookings();
      setState(() => expandedIndex = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ فشل الإلغاء: $e')));
    }
  }

  DateTime _getBookingEndTime(Map booking) {
  final date = booking['date'];
  String time = booking['start_time'];
  bool isPM = time.contains('مساء');

  time = time.replaceAll(RegExp(r'صباحًا|مساءً|صباح|مساء'), '').trim();
  final parts = time.split(':');
  int hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);

  if (isPM && hour < 12) hour += 12;
  if (!isPM && hour == 12) hour = 0;

  final startDateTime = DateTime.parse('$date ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');

  // ✅ دعم القيم النصية والعددية
  int minutesToAdd;
  final duration = booking['duration'].toString().trim();

  if (duration == 'نصف ساعة') {
    minutesToAdd = 30;
  } else if (duration == 'ساعة') {
    minutesToAdd = 60;
  } else if (duration == 'ساعة ونصف') {
    minutesToAdd = 90;
  } else if (duration == 'ساعتين') {
    minutesToAdd = 120;
  } else {
    minutesToAdd = int.tryParse(duration) ?? 60; // fallback
  }

  return startDateTime.add(Duration(minutes: minutesToAdd));
}

  String _translateStatus(String? status) {
    switch (status) {
      case 'confirmed': return 'تم التأكيد';
      case 'canceled': return 'ملغي';
      case 'pending':
      default: return 'بانتظار الموافقة';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'canceled': return Colors.red;
      case 'pending':
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle;
      case 'canceled': return Icons.cancel;
      case 'pending':
      default: return Icons.hourglass_bottom;
    }
  }

  List _todayBookings() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return filteredBookings.where((b) => b['date'] == today).toList();
  }

  List _previousBookings() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return filteredBookings.where((b) => b['date'].compareTo(today) < 0).toList();
  }

  List _upcomingBookings() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return filteredBookings.where((b) => b['date'].compareTo(today) > 0).toList();
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

  Widget buildBookingCard(dynamic booking, int index) {
    final status = booking['status'] ?? 'pending';
    final isExpanded = expandedIndex == index;
    final bookingEndTime = _getBookingEndTime(booking);
    final now = DateTime.now();
    final hasEnded = now.isAfter(bookingEndTime);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => expandedIndex = isExpanded ? null : index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.stadium, size: 24, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(child: Text('ملعب: ${booking['stadium']['name']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.15),
                      border: Border.all(color: _getStatusColor(status)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 16),
                        const SizedBox(width: 4),
                        Text(_translateStatus(status), style: TextStyle(fontSize: 12, color: _getStatusColor(status))),
                      ],
                    ),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const Divider(height: 20),
                Text('📅 التاريخ: ${booking['date']}', style: const TextStyle(fontSize: 13)),
                Text('⏰ الوقت: ${booking['start_time']}', style: const TextStyle(fontSize: 13)),
                Text('⏳ المدة: ${booking['duration']}', style: const TextStyle(fontSize: 13)),
                Text('💰 السعر: ${booking['total_price']} ريال', style: const TextStyle(fontSize: 13)),
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => confirmCancelBooking(context, booking['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text('إلغاء الحجز'),
                  ),
                ],
                if (hasEnded && status == 'confirmed' && booking['is_rated'] != true) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StadiumRatingScreen(
                            userId: widget.userId,
                            stadiumId: booking['stadium']['id'],
                            bookingId: booking['id'],
                          ),
                        ),
                      );
                      await fetchUserBookings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.star),
                    label: const Text('قيّم الملعب'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UserBaseScreen(
      title: 'حجوزاتي',
      userId: widget.userId,
      currentIndex: 2,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: showDateSelector,
              icon: const Icon(Icons.date_range, size: 16, color: Colors.white),
              label: const Text('فلترة بالتاريخ', style: TextStyle(fontSize: 13, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF269F49),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
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
                isDense: true,
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
        ],
      ),

      // ✅ هنا مكان زر "مسح الكل"
      if (selectedDate != null || selectedStatus != 'الكل') ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
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
    ],
  ),
),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredBookings.isEmpty
                      ? const Center(child: Text('لا توجد حجوزات'))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (_todayBookings().isNotEmpty) ...[
                              buildSectionHeader('حجوزات اليوم', Icons.today, Colors.green),
                              const SizedBox(height: 8),
                              ..._todayBookings().asMap().entries.map((e) => buildBookingCard(e.value, bookings.indexOf(e.value))),
                            ],
                            if (_upcomingBookings().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              buildSectionHeader('حجوزات قادمة', Icons.schedule, Colors.blue),
                              const SizedBox(height: 8),
                              ..._upcomingBookings().asMap().entries.map((e) => buildBookingCard(e.value, bookings.indexOf(e.value))),
                            ],
                            if (_previousBookings().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              buildSectionHeader('حجوزات سابقة', Icons.history, Colors.grey),
                              const SizedBox(height: 8),
                              ..._previousBookings().asMap().entries.map((e) => buildBookingCard(e.value, bookings.indexOf(e.value))),
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
