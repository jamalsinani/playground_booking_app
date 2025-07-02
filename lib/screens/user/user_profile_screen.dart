import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../widgets/user_base_screen.dart';
import '../../services/user_service.dart';
import 'user_bookings_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = true;
  int bookingsCount = 0;
  int ratingsCount = 0;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    fetchImage(); // 🔹 تحميل الصورة أولًا
    loadData();   // 🔹 تحميل البيانات الأخرى
  }

  Future<void> fetchImage() async {
    try {
      final user = await UserService.fetchUserById(widget.userId);
      final imageFileName = user['profile_image'];

      if (imageFileName != null && imageFileName.toString().isNotEmpty) {
        setState(() {
          profileImageUrl = 'https://darajaty.net/images/profile_images/$imageFileName';
        });
      }
    } catch (e) {
      debugPrint("❌ خطأ في تحميل الصورة: $e");
    }
  }

  Future<void> loadData() async {
    try {
      final user = await UserService.fetchUserById(widget.userId);
      final bookingData = await UserService.fetchUserBookingCount(widget.userId);
      final ratingData = await UserService.fetchUserRatingCount(widget.userId);

      setState(() {
        nameController.text = user['name'] ?? '';
        phoneController.text = user['phone'] ?? '';
        emailController.text = user['email'] ?? '';
        bookingsCount = bookingData['total'] ?? 0;
        ratingsCount = ratingData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('التقاط صورة بالكاميرا'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromSource(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('اختيار من المعرض'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromSource(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      final file = File(picked.path);
      final success = await UserService.uploadProfileImage(widget.userId, file);
      if (success) {
        await fetchImage(); // ✅ تحديث الصورة فورًا
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم رفع الصورة بنجاح")),
        );
      }
    }
  }

  Future<void> updateAll() async {
    try {
      await UserService.updateUserField(widget.userId, "name", nameController.text);
      await UserService.updateUserField(widget.userId, "phone", phoneController.text);
      await UserService.updateUserField(widget.userId, "email", emailController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم تحديث البيانات بنجاح")),
      );
    } catch (e) {
      debugPrint("❌ خطأ أثناء التحديث: $e");

      String errorMessage = "❌ فشل في تحديث البيانات";

      if (e.toString().contains('422')) {
        errorMessage = "📛 البريد الإلكتروني أو رقم الهاتف مستخدم بالفعل.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Widget infoCard({required String title, required IconData icon, required String count, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, size: 30, color: Colors.green),
                const SizedBox(height: 8),
                Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UserBaseScreen(
      title: "الملف الشخصي",
      userId: widget.userId,
      currentIndex: 1,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: profileImageUrl != null
                                ? FadeInImage.assetNetwork(
                                    placeholder: 'assets/images/user.png',
                                    image: profileImageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/images/user.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 16,
                          child: Icon(Icons.edit, color: Colors.green, size: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(nameController.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(phoneController.text, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      infoCard(
                        title: "الحجوزات",
                        icon: Icons.calendar_month,
                        count: bookingsCount.toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserBookingsScreen(userId: widget.userId),
                            ),
                          );
                        },
                      ),
                      infoCard(
                        title: "تقييماتي",
                        icon: Icons.star,
                        count: ratingsCount.toString(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  buildEditableField("الاسم", Icons.person, nameController),
                  buildEditableField("رقم الهاتف", Icons.phone, phoneController),
                  buildEditableField("البريد الإلكتروني", Icons.email, emailController),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      "تحديث البيانات",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: updateAll,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget buildEditableField(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: Colors.green),
          title: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
