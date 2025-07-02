import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:booking_demo/services/owner_stadium_service.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';

class ManageStadiumsScreen extends StatefulWidget {
  final int ownerId;

  const ManageStadiumsScreen({super.key, required this.ownerId});

  @override
  State<ManageStadiumsScreen> createState() => _ManageStadiumsScreenState();
}

class _ManageStadiumsScreenState extends State<ManageStadiumsScreen> {
  List stadiums = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStadiums();
  }

  Future<void> fetchStadiums() async {
    try {
      final data = await OwnerStadiumService.fetchStadiumsByOwner(widget.ownerId);
      setState(() {
        stadiums = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ فشل في جلب الملاعب: $e');
    }
  }

  Future<void> toggleAvailability(int stadiumId) async {
    final index = stadiums.indexWhere((s) => s['id'] == stadiumId);
    if (index == -1) return;

    final current = stadiums[index]['is_active'];
    final newStatus = current == 1 || current == '1' || current == true ? 0 : 1;

    setState(() {
      stadiums[index]['is_active'] = newStatus;
    });

    try {
      await OwnerStadiumService.toggleAvailability(stadiumId);
      showFlushMessage('تم تحديث حالة الملعب');
    } catch (e) {
      setState(() {
        stadiums[index]['is_active'] = current;
      });
      showFlushMessage('فشل في تبديل الحالة', color: Colors.red);
    }
  }

  Future<void> deleteStadium(int stadiumId) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'تأكيد الحذف',
      desc: 'هل تريد حذف هذا الملعب نهائيًا؟',
      btnCancelText: 'إلغاء',
      btnCancelOnPress: () {},
      btnOkText: 'حذف',
      btnOkColor: Colors.red,
      btnOkOnPress: () async {
        try {
          await OwnerStadiumService.deleteStadium(stadiumId);
          await fetchStadiums();
          showFlushMessage('✅ تم حذف الملعب');
        } catch (e) {
          showFlushMessage('فشل في حذف الملعب', color: Colors.red);
        }
      },
    ).show();
  }

  // ✅ رسالة أعلى الشاشة
  void showFlushMessage(String message, {Color color = Colors.green}) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 2),
      backgroundColor: color,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      icon: Icon(
        color == Colors.green ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'إدارة الملاعب',
      ownerId: widget.ownerId,
      currentIndex: 1,
      unreadBookingCount: 0,
      onTap: (index) {},
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stadiums.isEmpty
              ? const Center(child: Text('لا توجد ملاعب حالياً'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: stadiums.length,
                  itemBuilder: (context, index) {
                    final stadium = stadiums[index];
                    final isAvailable = stadium['is_active'] == 1 ||
                        stadium['is_active'] == true ||
                        stadium['is_active'] == '1';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(stadium['name']),
                        subtitle: Text(isAvailable ? '🟢 متاح' : '🔴 غير متاح'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: isAvailable,
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                                onChanged: (_) =>
                                    toggleAvailability(stadium['id']),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  deleteStadium(stadium['id']),
                              tooltip: 'حذف',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
