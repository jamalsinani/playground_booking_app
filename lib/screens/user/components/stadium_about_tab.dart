import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_image_slider/carousel.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/user_service.dart';
import 'package:booking_demo/widgets/fullscreen_image_viewer.dart';

class StadiumAboutTab extends StatefulWidget {
  final int stadiumId;

  const StadiumAboutTab({super.key, required this.stadiumId});

  @override
  State<StadiumAboutTab> createState() => _StadiumAboutTabState();
}

class _StadiumAboutTabState extends State<StadiumAboutTab> {
  bool isLoading = true;
  Map<String, dynamic>? details;
  List<String> services = [];
  List<String> images = [];
  double? latitude;
  double? longitude;
  String? address;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final result = await UserService.fetchStadiumDetails(widget.stadiumId);
      final d = result['details'];

      setState(() {
        details = d;
        services = d['services'] != null && d['services'] is List
            ? List<String>.from(d['services'])
            : [];
        images = List<String>.from(result['images'] ?? []);
        latitude = double.tryParse(result['latitude'].toString());
        longitude = double.tryParse(result['longitude'].toString());
        address = result['address'];
        isLoading = false;
      });
    } catch (e, stack) {
      print('❌ فشل تحميل البيانات: $e');
      print(stack);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (details == null) return const Center(child: Text('تعذر تحميل بيانات الملعب'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Carousel(
                height: 220,
                width: double.infinity,
                autoScroll: true,
                indicatorBarColor: Colors.transparent,
                items: images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrls: images,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),

          buildSection(title: 'بيانات الملعب', children: [
            dataText('نوع الأرضية: ${details!['surface'] ?? ''}'),
            dataText('الحجم: ${details!['size'] ?? ''}'),
            dataText('عدد اللاعبين: ${details!['players']?.toString() ?? ''}'),
            dataText('من الساعة: ${details!['open_time'] ?? ''}'),
            dataText('إلى الساعة: ${details!['close_time'] ?? ''}'),
          ]),

          if ((details!['rules'] ?? '').toString().isNotEmpty)
            buildSection(title: 'ملاحظات مالك الملعب', children: [
              Text(details!['rules'], style: const TextStyle(fontSize: 13))
            ]),

          // إضافة قسم شروط الدفع هنا
          if ((details!['payment_rules'] ?? '').toString().isNotEmpty)
            buildSection(title: 'شروط الدفع', children: [
              Text(
                details!['payment_rules'],
                style: const TextStyle(fontSize: 13),
              )
            ]),

          if (services.isNotEmpty)
            buildSection(title: 'الخدمات المتوفرة', children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: services
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.green.shade100,
                        ))
                    .toList(),
              )
            ]),

          buildSection(title: 'موقع الملعب', children: [
            if (latitude != null && longitude != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(latitude!, longitude!),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('stadium'),
                            position: LatLng(latitude!, longitude!),
                            infoWindow: InfoWindow(title: 'الملعب', snippet: address ?? ''),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        liteModeEnabled: true,
                      ),
                    ),
                  ),
                  if (address != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              address!,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            else
              const Text(
                'لم يتم تحديد موقع الملعب بعد.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              )
          ]),

          const SizedBox(height: 20),
          if (latitude != null && longitude != null)
            ElevatedButton(
              onPressed: () {
                final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('فتح في Google Map', style: TextStyle(fontSize: 14)),
            ),
        ],
      ),
    );
  }

  Widget buildSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 1.2),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          ...children
        ],
      ),
    );
  }

  Widget dataText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}