import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import 'package:booking_demo/widgets/owner_base_screen.dart';
import 'package:booking_demo/services/owner_stadium_service.dart';

class AddStadiumScreen extends StatefulWidget {
  final int ownerId;

  const AddStadiumScreen({super.key, required this.ownerId});

  @override
  _AddStadiumScreenState createState() => _AddStadiumScreenState();
}

class _AddStadiumScreenState extends State<AddStadiumScreen> {
  bool isSaving = false;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final locationController = TextEditingController(); // المنطقة
  final locationNameController = TextEditingController(); // اسم الموقع من الخريطة

  String? selectedType;
  String? locationAddress;
  LatLng? selectedPosition;
  GoogleMapController? mapController;

  final List<String> stadiumTypes = [
    'ملعب كرة قدم سداسي',
    'ملعب كرة قدم قياسي',
    'ملعب بادل',
    'ملعب طائرة',
    'ملعب اصطناعي سداسي',
  ];

  Future<void> fetchAddressFromLatLng(LatLng position) async {
    final apiKey = "AIzaSyCMns-EDNOhWV8lcO2KgT63loD71G0xRXQ";
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&language=ar&key=$apiKey");

    final response = await http.get(url);

    try {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final address = data['results'][0]['formatted_address'];
        setState(() {
          locationAddress = address;
          locationNameController.text = address;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحليل عنوان الخريطة: $e');
    }
  }

  Future<void> moveToCurrentLocation() async {
    final location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final currentLocation = await location.getLocation();
    final latLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);

    mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    setState(() {
      selectedPosition = latLng;
    });
    await fetchAddressFromLatLng(latLng);
  }

  Future<void> submitStadium() async {
  if (selectedPosition == null) {
    Flushbar(
      message: '❗ الرجاء تحديد موقع الملعب على الخريطة',
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(10),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
    return;
  }

  setState(() => isSaving = true);

  final result = await OwnerStadiumService.addStadium({
    'name': nameController.text,
    'price_per_hour': double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0,
    'location': locationController.text,
    'address': locationNameController.text,
    'type': selectedType ?? '',
    'latitude': selectedPosition!.latitude,
    'longitude': selectedPosition!.longitude,
    'owner_id': widget.ownerId,
  });

  setState(() => isSaving = false);

if (result['success']) {
  Flushbar(
    message: '✅ تم تسجيل الملعب بنجاح. بانتظار موافقة الأدمن',
    duration: const Duration(seconds: 2),
    backgroundColor: Colors.green,
    margin: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(10),
    flushbarPosition: FlushbarPosition.TOP,
  ).show(context);

  // ننتظر لحظة لعرض الرسالة ثم نرجع للصفحة الرئيسية
  await Future.delayed(const Duration(seconds: 2));
  Navigator.of(context).popUntil((route) => route.isFirst);
} else {
  Flushbar(
    message: '❌ فشل في تسجيل الملعب',
    duration: const Duration(seconds: 3),
    backgroundColor: Colors.red,
    margin: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(10),
    flushbarPosition: FlushbarPosition.TOP,
  ).show(context);
}
  }
  
  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'إضافة ملعب',
      ownerId: widget.ownerId,
      currentIndex: 0,
      unreadBookingCount: 0,
      onTap: (_) {},
      onAddPressed: () {},
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 الموقع الجغرافي للملعب', style: sectionTitleStyle),
            const SizedBox(height: 8),
            const Text(
              '📌 اضغط مطولاً على الخريطة لتحديد موقع الملعب',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Tajawal',
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      onMapCreated: (controller) => mapController = controller,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(23.5880, 58.3829),
                        zoom: 12,
                      ),
                      onLongPress: (LatLng position) async {
                        setState(() {
                          selectedPosition = position;
                          locationAddress = null;
                        });
                        await fetchAddressFromLatLng(position);
                      },
                      markers: selectedPosition != null
                          ? {
                              Marker(
                                markerId: const MarkerId('selected'),
                                position: selectedPosition!,
                              )
                            }
                          : {},
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: FloatingActionButton(
                      heroTag: 'btnLocation',
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: moveToCurrentLocation,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locationNameController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '📍 اسم الموقع المحدد تلقائيًا',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
            ),
            const SizedBox(height: 30),
            Text('📋 بيانات الملعب', style: sectionTitleStyle),
            const SizedBox(height: 12),
            buildInputField(nameController, 'اسم الملعب'),
            const SizedBox(height: 12),
            buildInputField(priceController, 'سعر الإيجار بالساعة', type: TextInputType.number),
            const SizedBox(height: 12),
            buildInputField(locationController, 'منطقة تواجد الملعب'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
              items: stadiumTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, style: const TextStyle(fontFamily: 'NotoKufiArabic')),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'نوع الملعب',
                labelStyle: const TextStyle(fontFamily: 'NotoKufiArabic'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
  onPressed: isSaving ? null : submitStadium,
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1E2761),
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: isSaving
      ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
      : const Text(
          'إضافة',
          style: TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
        ),
),
          ],
        ),
      ),
    );
  }

  TextStyle get sectionTitleStyle => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'NotoKufiArabic',
      );

  Widget buildInputField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFamily: 'NotoKufiArabic'),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(fontFamily: 'NotoKufiArabic'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }
}
