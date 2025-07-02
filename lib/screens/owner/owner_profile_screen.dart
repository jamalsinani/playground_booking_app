// 👇 الكود الكامل بعد التعديلات
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:another_flushbar/flushbar.dart';

import 'package:booking_demo/widgets/owner_base_screen.dart';
import 'package:booking_demo/screens/owner/owner_bookings_screen.dart';
import 'package:booking_demo/screens/owner/owner_home_screen.dart';
import 'package:booking_demo/screens/owner/manage_stadiums_screen.dart';
import 'package:booking_demo/screens/owner/owner_wallet_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  final int ownerId;
  const OwnerProfileScreen({super.key, required this.ownerId});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  String? profileImageUrl;
  File? selectedImage;
  int stadiumCount = 0;
  int confirmedCount = 0;
  int cancelledCount = 0;
  int totalCount = 0;
  double walletBalance = 0.0;
  bool isLoading = true;
  bool isSaving = false; 

  void showTopMessage(String message, {bool isSuccess = true}) {
    Flushbar(
      message: message,
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      flushbarPosition: FlushbarPosition.TOP,
      duration: const Duration(seconds: 3),
      icon: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() => isLoading = true);
    await fetchOwnerData();
    await fetchStadiums();
    await fetchBookingStats();
    await fetchWalletBalance();
    setState(() => isLoading = false);
  }

  Future<void> fetchOwnerData() async {
    final url = Uri.parse('https://darajaty.net/api/owner/${widget.ownerId}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      nameController.text = data['name'] ?? '';
      phoneController.text = data['phone'] ?? '';
      emailController.text = data['email'] ?? '';
      final image = data['profile_image'];
      if (image != null && !image.toString().startsWith('http')) {
        profileImageUrl = 'https://darajaty.net/$image';
      } else {
        profileImageUrl = image;
      }
    }
  }

  Future<void> fetchStadiums() async {
    final url = Uri.parse('https://darajaty.net/api/stadiums/owner/${widget.ownerId}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      stadiumCount = data['data'].length;
    }
  }

  Future<void> fetchBookingStats() async {
    final url = Uri.parse('https://darajaty.net/api/owner/${widget.ownerId}/bookings/stats');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      confirmedCount = data['confirmed'] ?? 0;
      cancelledCount = data['cancelled'] ?? 0;
      totalCount = confirmedCount + cancelledCount;
    }
  }

  Future<void> fetchWalletBalance() async {
    final url = Uri.parse('https://darajaty.net/api/owner/${widget.ownerId}/wallet');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      walletBalance = double.tryParse(data['total_profit'].toString()) ?? 0.0;
    }
  }

  Future<void> updateSingleField(String field, String value) async {
    final url = Uri.parse('https://darajaty.net/api/owner/update/${widget.ownerId}');
    await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({field: value}),
    );
  }

  Future<void> _handleSaveAllFields() async {
  String name = nameController.text.trim();
  String phone = phoneController.text.trim();
  String email = emailController.text.trim();

  final checkUrl = Uri.parse('https://darajaty.net/api/owner/${widget.ownerId}/check-duplicate');
  final response = await http.post(
    checkUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'phone': phone,
      'email': email,
    }),
  );

  if (response.statusCode == 200) {
    // ✅ لا يوجد تكرار ← تابع التحديث
    await updateSingleField("name", name);
    await updateSingleField("phone", phone);
    await updateSingleField("email", email);
    showTopMessage("✅ تم حفظ التعديلات بنجاح");
    await fetchOwnerData();
  } else if (response.statusCode == 409) {
    // ❌ يوجد تكرار في الهاتف أو البريد
    final result = jsonDecode(response.body);
    showTopMessage("❌ ${result['message']}", isSuccess: false);
  } else {
    showTopMessage("❌ حدث خطأ غير متوقع أثناء التحقق من البيانات", isSuccess: false);
  }
}

  Future<void> pickAndUploadImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("اختيار صورة البروفايل", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("اختيار من المعرض"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("التقاط بالكاميرا"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    setState(() => selectedImage = File(picked.path));

    final uri = Uri.parse('https://darajaty.net/api/owner/${widget.ownerId}/upload-profile-image');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('profile_image', picked.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => profileImageUrl = data['profile_image_url']);
      showTopMessage("✅ تم رفع الصورة بنجاح");
    }
  }

  void _handleBottomTap(int index) {
    if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerBookingsScreen(ownerId: widget.ownerId)));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OwnerHomeScreen(ownerId: widget.ownerId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'الملف الشخصي',
      ownerId: widget.ownerId,
      currentIndex: 1,
      unreadBookingCount: 0,
      onTap: _handleBottomTap,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : (profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : const AssetImage('assets/images/owner.png')) as ImageProvider,
                      ),
                      IconButton(icon: const Icon(Icons.camera_alt, color: Colors.blue), onPressed: pickAndUploadImage),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(nameController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(phoneController.text, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

                  // البطاقات العلوية
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _smallStatCard("عدد الملاعب", "$stadiumCount", Icons.sports_soccer, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ManageStadiumsScreen(ownerId: widget.ownerId)));
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: _smallStatCard("عدد الحجوزات", "$totalCount", Icons.calendar_today, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerBookingsScreen(ownerId: widget.ownerId)));
                        })),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _smallStatCard("المحفظة", "${walletBalance.toStringAsFixed(2)} ر.ع", Icons.account_balance_wallet, null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // إحصائيات
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("إحصائيات الحجوزات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildBookingStat("الإجمالي", totalCount, Icons.bar_chart, Colors.blue),
                                _buildBookingStat("المؤكدة", confirmedCount, Icons.check_circle, Colors.green),
                                _buildBookingStat("الملغية", cancelledCount, Icons.cancel, Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // الحقول القابلة للتعديل
                  _editableCard(label: "الاسم", icon: Icons.person, controller: nameController),
                  _editableCard(label: "رقم الهاتف", icon: Icons.phone, controller: phoneController),
                  _editableCard(label: "البريد الإلكتروني", icon: Icons.email, controller: emailController),

                  const SizedBox(height: 20),
                  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: SizedBox(
    width: 200,
    child: ElevatedButton(
      onPressed: isSaving
          ? null
          : () async {
              setState(() => isSaving = true);
              await _handleSaveAllFields();
              setState(() => isSaving = false);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF22235D),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: isSaving
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              "حفظ التعديلات",
              style: TextStyle(color: Colors.white),
            ),
    ),
  ),
),
const SizedBox(height: 30),


                ],
              ),
            ),
    );
  }

  Widget _buildBookingStat(String title, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 13)),
        Text("$count", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _smallStatCard(String title, String value, IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: const Color(0xFF22235D),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.white)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editableCard({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFDDDDDD), width: 1)),
            ),
            child: Icon(icon, color: const Color(0xFF22235D), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
