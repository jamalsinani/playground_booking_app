import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:booking_demo/services/owner_stadium_service.dart';

class StadiumInfoTab extends StatefulWidget {
  final int stadiumId;
  const StadiumInfoTab({super.key, required this.stadiumId});

  @override
  State<StadiumInfoTab> createState() => _StadiumInfoTabState();
}

class _StadiumInfoTabState extends State<StadiumInfoTab> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final typeController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  final sizeController = TextEditingController();
  final playersController = TextEditingController();
  final openTimeController = TextEditingController();
  final closeTimeController = TextEditingController();
  final rulesController = TextEditingController();
  final addressController = TextEditingController();
  final _paymentRulesController = TextEditingController();

  bool isSaving = false;

  // Form state variables
  String? selectedSurface;
  List<String> selectedServices = [];
  bool isExpanded1 = false;
  bool isExpanded2 = false;
  bool isExpanded3 = false;
  bool isEditingPrimary = false;

  // Map related variables
  LatLng? selectedPosition;
  String? locationAddress;
  GoogleMapController? mapController;

  // Constants
  final List<String> surfaces = ['عشب طبيعي', 'عشب صناعي', 'إسفلت', 'رمل', 'ترتان صناعي'];
  final List<String> services = ['دورات مياه', 'مواقف سيارات', 'غرفة تبديل', 'إنارة ليلية', 'كافتيريا'];

  @override
  void initState() {
    super.initState();
    fetchStadiumData();

    openTimeController.text = '00:00';
    closeTimeController.text = '00:00';
  }

  @override
  void dispose() {
    // Dispose all controllers
    nameController.dispose();
    typeController.dispose();
    locationController.dispose();
    priceController.dispose();
    sizeController.dispose();
    playersController.dispose();
    openTimeController.dispose();
    closeTimeController.dispose();
    rulesController.dispose();
    addressController.dispose();
    _paymentRulesController.dispose();
    super.dispose();
  }

  Future<void> fetchStadiumData() async {
    try {
      // Fetch basic stadium data
      final data = await OwnerStadiumService.getStadiumById(widget.stadiumId);
      
      // Handle location data
      final lat = double.tryParse(data['latitude']?.toString() ?? '');
      final lng = double.tryParse(data['longitude']?.toString() ?? '');
      final dbAddress = data['address']?.toString();

      if (lat != null && lng != null) {
        selectedPosition = LatLng(lat, lng);
        await fetchAddressFromLatLng(selectedPosition!);
      } else {
        await moveToCurrentLocation();
      }

      // Update address if available
      if (dbAddress != null && dbAddress.isNotEmpty) {
        locationAddress = dbAddress;
        addressController.text = dbAddress;
      }

      // Update basic info
      setState(() {
        nameController.text = data['name']?.toString() ?? '';
        typeController.text = data['type']?.toString() ?? '';
        locationController.text = data['location']?.toString() ?? '';
        priceController.text = data['price_per_hour']?.toString() ?? '';
      });

      // Fetch stadium details
      final details = await OwnerStadiumService.getStadiumDetailsById(widget.stadiumId);
      setState(() {
        selectedSurface = details['surface']?.toString();
        sizeController.text = details['size']?.toString() ?? '';
        playersController.text = details['players']?.toString() ?? '';
        openTimeController.text = details['open_time']?.toString() ?? '';
        closeTimeController.text = details['close_time']?.toString() ?? '';
        rulesController.text = details['rules']?.toString() ?? '';
        _paymentRulesController.text = details['payment_rules']?.toString() ?? '';
        
        // Handle services data
        if (details['services'] != null) {
          if (details['services'] is List) {
            selectedServices = List<String>.from(details['services'].map((e) => e.toString()));
          } else if (details['services'] is String) {
            try {
              final decoded = jsonDecode(details['services']);
              if (decoded is List) {
                selectedServices = List<String>.from(decoded.map((e) => e.toString()));
              }
            } catch (e) {
              print('Error decoding services: $e');
            }
          }
        }
      });
    } catch (e) {
      print('Failed to fetch stadium data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load stadium data: $e')),
      );
    }
  }

  Future<void> fetchAddressFromLatLng(LatLng position) async {
    
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&language=ar&key=$apiKey"
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final address = results[0]['formatted_address']?.toString();
          setState(() {
            locationAddress = address;
            addressController.text = address ?? '';
          });
        } else {
          print("No address found for these coordinates");
        }
      } else {
        print("Failed to connect to Google: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching address: $e");
    }
  }

  Future<void> moveToCurrentLocation() async {
    final location = Location();

    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      final currentLocation = await location.getLocation();
      final latLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      setState(() {
        selectedPosition = latLng;
      });
      await fetchAddressFromLatLng(latLng);
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> saveAllData() async {
  if (_formKey.currentState?.validate() ?? false) {
    setState(() => isSaving = true); // 🔄 بدء التحميل

    try {
      final basicUpdated = await OwnerStadiumService.updateStadiumBasicData(
        stadiumId: widget.stadiumId,
        type: typeController.text,
        location: locationController.text,
        pricePerHour: double.tryParse(priceController.text) ?? 0,
      );

      final detailUpdated = await OwnerStadiumService.updateStadiumDetails(
        stadiumId: widget.stadiumId,
        surface: selectedSurface,
        size: sizeController.text,
        players: playersController.text,
        openTime: openTimeController.text,
        closeTime: closeTimeController.text,
        services: selectedServices,
        rules: rulesController.text,
        paymentRules: _paymentRulesController.text,
      );

      final locationUpdated = await OwnerStadiumService.updateStadiumLocation(
        stadiumId: widget.stadiumId,
        latitude: selectedPosition?.latitude,
        longitude: selectedPosition?.longitude,
        address: locationAddress ?? '',
      );

      final success = basicUpdated && detailUpdated && locationUpdated;

      Flushbar(
        messageText: const Text(
          '✅ تم حفظ جميع البيانات بنجاح',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        icon: const Icon(Icons.check_circle, size: 28.0, color: Colors.white),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(8),
      ).show(context);
    } catch (e) {
      Flushbar(
        messageText: Text(
          '❌ حدث خطأ أثناء الحفظ: $e',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        icon: const Icon(Icons.error_outline, size: 28.0, color: Colors.white),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(8),
      ).show(context);
    } finally {
      setState(() => isSaving = false); // 🛑 انتهاء التحميل
    }
  }
}


  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: validator ?? (value) => (value == null || value.isEmpty) ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  Widget buildLabeledTextArea({
    required String label,
    required String tooltip,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Tooltip(
                message: tooltip,
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(Icons.info_outline, size: 18, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: validator ?? (value) => (value == null || value.isEmpty) ? 'هذا الحقل مطلوب' : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Section
            if (selectedPosition != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📍 الموقع الجغرافي للملعب',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📌 اضغط مطولًا على الخريطة لتحديث موقع الملعب',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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
                            initialCameraPosition: CameraPosition(
                              target: selectedPosition!,
                              zoom: 15,
                            ),
                            onLongPress: (LatLng position) async {
                              setState(() {
                                selectedPosition = position;
                                locationAddress = null;
                              });
                              await fetchAddressFromLatLng(position);
                            },
                            markers: {
                              Marker(
                                markerId: const MarkerId('selected'),
                                position: selectedPosition!,
                              )
                            },
                            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
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
                  TextFormField(
                    readOnly: true,
                    controller: addressController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: '📍 اسم الموقع المحدد تلقائيًا',
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(fontSize: 14),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Primary Data Section
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "بيانات الملعب",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    IconButton(
                      icon: Icon(isEditingPrimary ? Icons.close : Icons.edit, size: 20),
                      onPressed: () {
                        setState(() {
                          isEditingPrimary = !isEditingPrimary;
                        });
                      },
                    ),
                  ],
                ),
                initiallyExpanded: isExpanded1,
                onExpansionChanged: (val) => setState(() => isExpanded1 = val),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        buildTextField(
                          controller: nameController,
                          label: 'اسم الملعب',
                          readOnly: true,
                        ),
                        buildTextField(
                          controller: typeController,
                          label: 'نوع الملعب',
                          readOnly: !isEditingPrimary,
                        ),
                        buildTextField(
                          controller: locationController,
                          label: 'الموقع',
                          readOnly: !isEditingPrimary,
                        ),
                        buildTextField(
                          controller: priceController,
                          label: 'السعر للساعة',
                          keyboardType: TextInputType.number,
                          readOnly: !isEditingPrimary,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'هذا الحقل مطلوب';
                            }
                            if (double.tryParse(value) == null) {
                              return 'يجب إدخال رقم صحيح';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Basic Data Section
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: const Text(
                  "بيانات الملعب الفنية",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                initiallyExpanded: isExpanded2,
                onExpansionChanged: (val) => setState(() => isExpanded2 = val),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedSurface,
                          items: surfaces
                              .map((surface) => DropdownMenuItem(
                                    value: surface,
                                    child: Text(surface, style: const TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => selectedSurface = value),
                          decoration: const InputDecoration(
                            labelText: 'نوع الأرضية',
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(fontSize: 14),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (value) =>
                              value == null ? 'يرجى اختيار نوع الأرضية' : null,
                        ),
                        const SizedBox(height: 12),
                        buildTextField(
                          controller: sizeController,
                          label: 'الأبعاد (مثال: 40x20)',
                        ),
                        buildTextField(
                          controller: playersController,
                          label: 'عدد اللاعبين',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'هذا الحقل مطلوب';
                            }
                            if (int.tryParse(value) == null) {
                              return 'يجب إدخال رقم صحيح';
                            }
                            return null;
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                controller: openTimeController,
                                label: 'وقت البدء',
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: buildTextField(
                                controller: closeTimeController,
                                label: 'وقت الإغلاق',
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Services and Conditions Section
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: const Text(
                  "الخدمات والشروط",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                initiallyExpanded: isExpanded3,
                onExpansionChanged: (val) => setState(() => isExpanded3 = val),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الخدمات المتوفرة:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ...services.map((service) {
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(service, style: const TextStyle(fontSize: 14)),
                            value: selectedServices.contains(service),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedServices.add(service);
                                } else {
                                  selectedServices.remove(service);
                                }
                              });
                            },
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        buildLabeledTextArea(
                          label: 'شروط وتعليمات الحجز',
                          tooltip:
                              'اكتب هنا أي شروط للحجز مثل: يُمنع الإلغاء في آخر لحظة – الالتزام بالوقت – الحجز لا يشمل الإضاءة.',
                          controller: rulesController,
                          hint: 'أدخل شروط الحجز...',
                        ),
                        buildLabeledTextArea(
                          label: 'شروط الدفع',
                          tooltip:
                              'حدد سياسة الدفع مثل: دفعة مقدمة – تحويل مسبق عبر الهاتف أو البنك – إلغاء قبل 24 ساعة.',
                          controller: _paymentRulesController,
                          hint: 'مثال: دفع 50% مقدمًا – أو تحويل قبل يوم الحجز...',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Save Button
            SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: isSaving ? null : saveAllData,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: isSaving
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : const Text(
            "حفظ التغييرات",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
  ),
),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} 
