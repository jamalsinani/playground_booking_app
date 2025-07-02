import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:booking_demo/services/owner_stadium_service.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';
import 'package:booking_demo/widgets/stadium_info_tab.dart';
import 'package:booking_demo/screens/owner/add_booking_screen.dart';
import 'package:booking_demo/widgets/owner_stadium_ratings_tab.dart';

class StadiumDetailScreen extends StatefulWidget {
  final int stadiumId;
  final String stadiumName;
  final int ownerId;

  const StadiumDetailScreen({
    super.key,
    required this.stadiumId,
    required this.stadiumName,
    required this.ownerId,
  });

  @override
  State<StadiumDetailScreen> createState() => _StadiumDetailScreenState();
}

class _StadiumDetailScreenState extends State<StadiumDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 4;

  List<String> stadiumImages = [];
  List<XFile> pendingUploads = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchStadiumImages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) Navigator.pop(context);
  }

  Future<void> fetchStadiumImages() async {
    try {
      final images = await OwnerStadiumService.fetchStadiumImages(widget.stadiumId);
      if (!mounted) return;
      setState(() => stadiumImages = images);
    } catch (e) {
      print('❌ فشل في جلب الصور: $e');
    }
  }

  Future<void> pickAndUploadMultipleImages() async {
    if (stadiumImages.length >= 5) {
      _showTopSnackbar('❌ لا يمكنك رفع أكثر من 5 صور', Colors.red.shade600);
      return;
    }

    final picker = ImagePicker();
    List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isEmpty) {
      final singleFile = await picker.pickImage(source: ImageSource.gallery);
      if (singleFile != null) pickedFiles = [singleFile];
    }

    if (pickedFiles.isEmpty) {
      _showTopSnackbar('❌ لم يتم اختيار أي صورة', Colors.red.shade600);
      return;
    }

    final allowedCount = 5 - stadiumImages.length;
    if (pickedFiles.length > allowedCount) {
      pickedFiles = pickedFiles.sublist(0, allowedCount);
      _showTopSnackbar('📷 تم اختيار أول $allowedCount صور فقط', Colors.orange.shade700);
    }

    setState(() {
      pendingUploads = pickedFiles;
      isUploading = true;
    });

    final success = await OwnerStadiumService.uploadMultipleImages(
      stadiumId: widget.stadiumId,
      files: pickedFiles,
    );

    if (success) {
      await fetchStadiumImages();
      _showTopSnackbar('✅ تم رفع الصور بنجاح', Colors.green.shade700);
    } else {
      _showTopSnackbar('❌ فشل في رفع الصور', Colors.red.shade600);
    }

    setState(() {
      pendingUploads = [];
      isUploading = false;
    });
  }

  Future<void> confirmAndDeleteImage(String imageUrl) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.red),
              const SizedBox(height: 10),
              const Text('هل تريد حذف هذه الصورة؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        Navigator.pop(context);
                        final success = await OwnerStadiumService.deleteImage(
                          stadiumId: widget.stadiumId,
                          imageUrl: imageUrl,
                        );
                        if (success) {
                          await fetchStadiumImages();
                          _showTopSnackbar('✅ تم حذف الصورة، يمكنك رفع صورة جديدة.', Colors.green.shade600);
                        } else {
                          _showTopSnackbar('❌ فشل في حذف الصورة', Colors.red.shade600);
                        }
                      },
                      child: const Text('حذف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTopSnackbar(String message, Color backgroundColor) {
  Flushbar(
    message: message,
    backgroundColor: backgroundColor,
    duration: const Duration(seconds: 3),
    borderRadius: BorderRadius.circular(12),
    margin: const EdgeInsets.all(16),
    flushbarPosition: FlushbarPosition.TOP,
    animationDuration: const Duration(milliseconds: 400),
  ).show(context);
}

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: widget.stadiumName,
      ownerId: widget.ownerId,
      currentIndex: _selectedIndex,
      unreadBookingCount: 0,
      onTap: _onItemTapped,
      onAddPressed: () {},
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1E2761),
            tabs: const [
              Tab(text: "الصور"),
              Tab(text: "البيانات"),
              Tab(text: "الأوقات"), 
              Tab(text: "التقييمات"),   
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0, top: 6),
                        child: Text(
                          'المتبقي: ${5 - stadiumImages.length} / 5 صور',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (stadiumImages.length < 5)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: pickAndUploadMultipleImages,
                          child: const Text("📸 رفع صور الملعب (حتى 5 صور)"),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: stadiumImages.isEmpty && pendingUploads.isEmpty
                          ? const Center(child: Text("لا توجد صور مرفوعة حتى الآن"))
                          : GridView.builder(
                              padding: const EdgeInsets.all(10),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: stadiumImages.length + pendingUploads.length,
                              itemBuilder: (context, index) {
                                if (index >= stadiumImages.length) {
                                  final localImage = pendingUploads[index - stadiumImages.length];
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(localImage.path),
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const Positioned.fill(
                                        child: ColoredBox(
                                          color: Colors.black38,
                                          child: Center(child: CircularProgressIndicator(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final rawImage = stadiumImages[index];
                                final imageUrl = rawImage.startsWith('http')
                                    ? rawImage
                                    : 'https://darajaty.net/images/stadiums/$rawImage';

                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: GestureDetector(
                                        onTap: isUploading ? null : () => confirmAndDeleteImage(imageUrl),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close, size: 18, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
                StadiumInfoTab(stadiumId: widget.stadiumId),
                BookingPlanScreen(stadiumId: widget.stadiumId),
                OwnerStadiumRatingsTab(stadiumId: widget.stadiumId), 
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
