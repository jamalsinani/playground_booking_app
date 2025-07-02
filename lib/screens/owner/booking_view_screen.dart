import 'package:flutter/material.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';
import 'package:booking_demo/services/owner_service.dart';

class BookingViewScreen extends StatefulWidget {
  final Map booking;
  final int ownerId;

  const BookingViewScreen({
    super.key,
    required this.booking,
    required this.ownerId,
  });

  @override
  State<BookingViewScreen> createState() => _BookingViewScreenState();
}

class _BookingViewScreenState extends State<BookingViewScreen> {
  String? actionTaken;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // إذا الحجز تم تأكيده أو إلغاؤه مسبقًا، نخزنه في actionTaken
    final status = widget.booking['status'];
    if (status == 'confirmed' || status == 'canceled') {
      actionTaken = status;
    }
  }

  Future<void> confirmBooking() async {
    setState(() => isLoading = true);
    try {
      await OwnerService.confirmBooking(widget.booking['id']);
      setState(() {
        actionTaken = 'confirmed';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم تأكيد الحجز')),
      );
      Navigator.pop(context, true); // لتحديث القائمة
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل تأكيد الحجز: $e')),
      );
    }
  }

  Future<void> cancelBooking() async {
    setState(() => isLoading = true);
    try {
      await OwnerService.cancelBooking(widget.booking['id']);
      setState(() {
        actionTaken = 'canceled';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚫 تم إلغاء الحجز')),
      );
      Navigator.pop(context, true); // لتحديث القائمة
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل إلغاء الحجز: $e')),
      );
    }
  }

  Widget buildStatusMessage() {
    final isConfirmed = actionTaken == 'confirmed';
    return Center(
      child: Text(
        isConfirmed ? '✅ تم تأكيد هذا الحجز' : '🚫 تم إلغاء هذا الحجز',
        style: TextStyle(
          fontSize: 18,
          color: isConfirmed ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'تفاصيل الحجز',
      ownerId: widget.ownerId,
      currentIndex: 3,
      unreadBookingCount: 0,
      onTap: (_) {},
      onAddPressed: () {},
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏟️ الملعب: ${widget.booking['stadium']['name']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('📆 التاريخ: ${widget.booking['date']}'),
            Text('⏰ الوقت: ${widget.booking['start_time']}'),
            Text('⌛ المدة: ${widget.booking['duration']}'),
            Text('💰 السعر: ${widget.booking['total_price']} ريال'),
            const SizedBox(height: 16),
            const Divider(),
            Text('🙍‍♂️ اسم الحاجز: ${widget.booking['user']['name']}'),
            Text('📱 رقم الهاتف: ${widget.booking['user']['phone'] ?? "غير متوفر"}'),
            const SizedBox(height: 24),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (actionTaken != null)
              buildStatusMessage()
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: confirmBooking,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('تأكيد الحجز'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: cancelBooking,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('إلغاء الحجز'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 