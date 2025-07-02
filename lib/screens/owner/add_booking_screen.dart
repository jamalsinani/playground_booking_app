import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:booking_demo/services/owner_service.dart';
import 'package:another_flushbar/flushbar.dart';

class BookingPlanScreen extends StatefulWidget {
  final int stadiumId;
  const BookingPlanScreen({super.key, required this.stadiumId});

  @override
  State<BookingPlanScreen> createState() => _BookingPlanScreenState();
}

class _BookingPlanScreenState extends State<BookingPlanScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String selectedDuration = 'ساعة';
  final List<String> durations = ['نصف ساعة', 'ساعة', 'ساعة ونصف', 'ساعتين'];

  Map<String, List<String>> bookingMap = {};
  List<String> selectedSlots = [];

  @override
  void initState() {
    super.initState();
    loadPlansFromServer();
  }

  Future<void> loadPlansFromServer() async {
    try {
      final result = await OwnerService.getAllBookingPlans(
        widget.stadiumId,
        duration: _getDurationMinutes(),
      );

      if (result['success'] == true) {
        final data = result['plans'];
        setState(() {
          bookingMap.clear();
          for (var plan in data) {
            final key = plan['date'];
            final slots = List<String>.from(plan['slots'])
                .map(_formatSlotFrom24Hour)
                .toList();
            bookingMap[key] = slots;
          }
        });
      }
    } catch (e) {
      print('❌ فشل تحميل الخطط: $e');
    }
  }

  void showFlushMessage(String message, {bool success = true}) {
    Flushbar(
      message: message,
      icon: Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
      duration: const Duration(seconds: 2),
      backgroundColor: success ? Colors.green : Colors.red,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  int _getDurationMinutes() {
    return {
      'نصف ساعة': 30,
      'ساعة': 60,
      'ساعة ونصف': 90,
      'ساعتين': 120,
    }[selectedDuration]!;
  }

  List<String> getTimeSlots() {
    final step = _getDurationMinutes();
    final List<String> slots = [];
    DateTime now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day, 8, 0);
    DateTime end = DateTime(now.year, now.month, now.day, 23, 0);

    while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
      final hour = (start.hour % 12 == 0 ? 12 : start.hour % 12);
      final minute = start.minute.toString().padLeft(2, '0');
      final period = start.hour < 12 ? 'صباحًا' : 'مساءً';
      slots.add('$hour:$minute\n$period');

      final next = start.add(Duration(minutes: step));
      if (next.isAfter(end)) break;
      start = next;
    }

    return slots;
  }

  bool isEditable(DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isAtSameMomentAs(today) || selected.isAfter(today);
  }
    Future<void> _saveBookingPlan() async {
    try {
      final dateKey = _selectedDay!.toIso8601String().split('T')[0];
      final formattedSlots = (bookingMap[dateKey] ?? []).map(_formatSlotTo24Hour).toList();

      final result = await OwnerService.saveBookingPlan(
        stadiumId: widget.stadiumId,
        date: dateKey,
        slots: formattedSlots,
        duration: _getDurationMinutes(),
      );

      if (result['success'] == true) {
        showFlushMessage("✅ تم حفظ الخطة بنجاح", success: true);
      } else {
        showFlushMessage('❌ حدث خطأ أثناء الحفظ: ${result['statusCode']}', success: false);
      }
    } catch (e) {
      showFlushMessage('❌ حدث استثناء أثناء الحفظ: $e', success: false);
    }
  }

  String _formatSlotTo24Hour(String input) {
    try {
      final parts = input.split('\n');
      if (parts.length != 2) return input;

      final time = parts[0].trim();
      final period = parts[1].trim();

      final timeParts = time.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (period.contains('مساء') && hour < 12) hour += 12;
      if (period.contains('صباح') && hour == 12) hour = 0;

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return input;
    }
  }

  String _formatSlotFrom24Hour(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      final period = hour < 12 ? 'صباحًا' : 'مساءً';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');

      return '$displayHour:$displayMinute\n$period';
    } catch (_) {
      return time24;
    }
  }

  void _showCopyDialog() {
    List<DateTime> selectedDates = [];

    showDialog(
      context: context,
      builder: (context) {
        DateTime _dialogFocusedDay = _focusedDay;

        return AlertDialog(
          title: const Text("حدد التواريخ التي تريد نسخ الخطة إليها"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                height: 400,
                width: 350,
                child: TableCalendar(
                  firstDay: DateTime.utc(2022, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _dialogFocusedDay,
                  selectedDayPredicate: (day) => selectedDates.any((d) => isSameDay(d, day)),
                  onDaySelected: (selectedDay, focusedDay) {
                    setDialogState(() {
                      if (selectedDates.any((d) => isSameDay(d, selectedDay))) {
                        selectedDates.removeWhere((d) => isSameDay(d, selectedDay));
                      } else {
                        selectedDates.add(selectedDay);
                      }
                    });
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                final baseKey = _selectedDay!.toIso8601String().split('T')[0];
                final baseSlots = List<String>.from(bookingMap[baseKey] ?? []);

                for (var date in selectedDates) {
                  final key = date.toIso8601String().split('T')[0];
                  bookingMap[key] = List<String>.from(baseSlots);

                  await OwnerService.saveBookingPlan(
                    stadiumId: widget.stadiumId,
                    date: key,
                    slots: baseSlots.map(_formatSlotTo24Hour).toList(),
                    duration: _getDurationMinutes(),
                  );
                }

                showFlushMessage('✅ تم نسخ الخطة إلى ${selectedDates.length} يومًا');
                Navigator.of(context).pop();
              },
              child: const Text("تأكيد النسخ"),
            ),
          ],
        );
      },
    );
  }
  void _showCopyAllDialog() {
    if (_selectedDay == null) return;

    List<DateTime> selectedDates = [];

    showDialog(
      context: context,
      builder: (context) {
        DateTime _dialogFocusedDay = _focusedDay;

        return AlertDialog(
          title: const Text("حدد التواريخ لنسخ كل خطة اليوم إليها"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                height: 400,
                width: 350,
                child: TableCalendar(
                  firstDay: DateTime.utc(2022, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _dialogFocusedDay,
                  selectedDayPredicate: (day) => selectedDates.any((d) => isSameDay(d, day)),
                  onDaySelected: (selectedDay, focusedDay) {
                    setDialogState(() {
                      if (selectedDates.any((d) => isSameDay(d, selectedDay))) {
                        selectedDates.removeWhere((d) => isSameDay(d, selectedDay));
                      } else {
                        selectedDates.add(selectedDay);
                      }
                    });
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("إلغاء")),
            ElevatedButton(
              onPressed: () async {
                final dateKey = _selectedDay!.toIso8601String().split('T')[0];
                final url = Uri.parse('https://darajaty.net/api/booking-plans/stadium/${widget.stadiumId}/full-day?date=$dateKey');
                final response = await http.get(url);

                if (response.statusCode == 200) {
                  final json = jsonDecode(response.body);
                  final allPlans = List<Map<String, dynamic>>.from(json['plans']);

                  for (var date in selectedDates) {
                    final key = date.toIso8601String().split('T')[0];

                    for (var plan in allPlans) {
                      final duration = plan['duration'];
                      final slots = List<String>.from(plan['slots']);

                      await OwnerService.saveBookingPlan(
                        stadiumId: widget.stadiumId,
                        date: key,
                        slots: slots,
                        duration: duration,
                      );
                    }
                  }

                  showFlushMessage("✅ تم نسخ كل خطة يوم $dateKey إلى ${selectedDates.length} يومًا");
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pop();
                  showFlushMessage("❌ فشل في جلب خطة اليوم: $dateKey", success: false);
                }
              },
              child: const Text("تأكيد النسخ"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = getTimeSlots();

    return Scaffold(
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2022, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
                final key = selected.toIso8601String().split('T')[0];
                selectedSlots = List<String>.from(bookingMap[key] ?? []);
              });

              if (selectedSlots.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  showFlushMessage("✅ تم تحميل الخطة السابقة لهذا اليوم");
                });
              }
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final key = day.toIso8601String().split('T')[0];
                final hasPlan = bookingMap.containsKey(key);

                if (hasPlan) {
                  return Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.green),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.green),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: selectedDuration,
              decoration: InputDecoration(
                labelText: 'مدة الحجز',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: durations
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  selectedDuration = value!;
                  selectedSlots.clear();
                });

                await loadPlansFromServer();
              },
            ),
          ),
          const SizedBox(height: 10),
          if (_selectedDay != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: slots.map((slot) {
                  final isSaved = selectedSlots.contains(slot);
                  return GestureDetector(
                    onTap: () {
                      if (!isEditable(_selectedDay!)) {
                        showFlushMessage('لا يمكن تعديل هذا اليوم، لقد انتهى', success: false);
                        return;
                      }
                      setState(() {
                        if (isSaved) {
                          selectedSlots.remove(slot);
                        } else {
                          selectedSlots.add(slot);
                        }
                        final key = _selectedDay!.toIso8601String().split('T')[0];
                        bookingMap[key] = List<String>.from(selectedSlots);
                      });
                    },
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSaved ? Colors.green : Colors.white,
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot.split('\n')[0],
                            style: TextStyle(
                              color: isSaved ? Colors.white : Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            slot.split('\n')[1],
                            style: TextStyle(
                              color: isSaved ? Colors.white70 : Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'عدد الأوقات المحددة: ${selectedSlots.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ الخطة'),
                onPressed: () {
                  if (_selectedDay == null || selectedSlots.isEmpty) {
                    showFlushMessage('يرجى تحديد يوم وأوقات أولاً', success: false);
                    return;
                  }
                  if (!isEditable(_selectedDay!)) {
                    showFlushMessage('لا يمكن حفظ يوم مضى بالفعل', success: false);
                    return;
                  }
                  _saveBookingPlan();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          if (_selectedDay != null && bookingMap.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showCopyDialog,
                      icon: const Icon(Icons.copy),
                      label: const Text("نسخ المدة الحالية"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B7BBA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showCopyAllDialog,
                      icon: const Icon(Icons.library_add),
                      label: const Text("نسخ كل الخطة"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
