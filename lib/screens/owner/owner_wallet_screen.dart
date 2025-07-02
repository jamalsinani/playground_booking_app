import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:open_file/open_file.dart';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:booking_demo/services/owner_service.dart';
import 'package:booking_demo/widgets/owner_base_screen.dart';

class OwnerWalletScreen extends StatefulWidget {
  const OwnerWalletScreen({super.key});

  @override
  State<OwnerWalletScreen> createState() => _OwnerWalletScreenState();
}

class _OwnerWalletScreenState extends State<OwnerWalletScreen> {
  int? ownerId;
  late Future<Map<String, dynamic>> walletDataFuture;
  List<Map<String, dynamic>> stadiums = [];

  DateTime? selectedFrom;
  DateTime? selectedTo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    ownerId = args?['ownerId'] ?? 3;
    walletDataFuture = OwnerService.fetchWalletData(ownerId!);
  }

  void _reloadData() {
    setState(() {
      walletDataFuture = OwnerService.fetchWalletData(
        ownerId!,
        from: selectedFrom,
        to: selectedTo,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return OwnerBaseScreen(
      title: 'محفظتي',
      ownerId: ownerId!,
      currentIndex: 0,
      unreadBookingCount: 0,
      body: FutureBuilder<Map<String, dynamic>>(
        future: walletDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final total = data['total_profit'] ?? 0.0;
          final month = data['month_profit'] ?? 0.0;
          final change = data['percent_change'] ?? 0;
          final stats = List<Map<String, dynamic>>.from(data['weekly_stats'] ?? []);
          stadiums = List<Map<String, dynamic>>.from(data['stadium_profits'] ?? []);

          return SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSummaryCardWithPdf(total, month, change, () {
        exportFullWalletReport(
          ownerName: data['owner_name'] ?? 'غير معروف',
          ownerPhone: data['owner_phone'] ?? '---',
          totalProfit: total,
          weeklyStats: List<Map<String, dynamic>>.from(data['weekly_stats'] ?? []),
          stadiumProfits: List<Map<String, dynamic>>.from(data['stadium_profits'] ?? []),
         bookings: List<Map<String, dynamic>>.from(data['bookings'] ?? []),
        );
      }),
      const SizedBox(height: 20),
      _buildChart(stats),
      const SizedBox(height: 20),
      _buildDateFilter(context),
      const SizedBox(height: 20),
      ...stats.map((item) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6FF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item['value'].toStringAsFixed(2)} ر.ع',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Row(
                  children: [
                    Text('${item['week']}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    const Icon(Icons.calendar_today, color: Colors.green, size: 18),
                  ],
                ),
              ],
            ),
          )),
    ],
  ),
);
        },
      ),
    );
  }


  Widget _buildSummaryCardWithPdf(double total, double month, int change, VoidCallback onPdfPressed) {
    return Stack(
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFB2F2BB), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('إجمالي الأرباح', style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 8),
                Text('ر.ع ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.green),
                    const SizedBox(width: 6),
                    Text('هذا الشهر: ${month.toStringAsFixed(2)} ر.ع'),
                    const SizedBox(width: 12),
                    Icon(change >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.blue),
                    Text(' ${change >= 0 ? '+' : ''}$change%', style: const TextStyle(color: Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: GestureDetector(
            onTap: onPdfPressed,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: const [
                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                  SizedBox(width: 4),
                  Text('PDF', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> stats) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < stats.length) {
                    return Text(stats[index]['week'], style: const TextStyle(fontSize: 11));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          barGroups: stats.asMap().entries.map((entry) {
            int index = entry.key;
            double value = (entry.value['value'] ?? 0).toDouble();
            return BarChartGroupData(x: index, barRods: [
              BarChartRodData(toY: value, width: 14, borderRadius: BorderRadius.circular(4), color: Colors.blueAccent),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'تفاصيل الأرباح الأسبوعية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D5FEF),
          ),
          textAlign: TextAlign.center,
        ),
      ),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedFrom ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => selectedFrom = picked);
                  _reloadData();
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(selectedFrom != null
                  ? "${selectedFrom!.toLocal()}".split(' ')[0]
                  : "من تاريخ"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2761),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedTo ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => selectedTo = picked);
                  _reloadData();
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(selectedTo != null
                  ? "${selectedTo!.toLocal()}".split(' ')[0]
                  : "إلى تاريخ"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2761),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              selectedFrom = null;
              selectedTo = null;
            });
            _reloadData();
          },
          icon: const Icon(Icons.clear, size: 18),
          label: const Text("مسح الفلاتر"),
        ),
      ),
    ],
  );
}

  void exportFullWalletReport({
  required String ownerName,
  required String ownerPhone,
  required double totalProfit,
  required List<Map<String, dynamic>> weeklyStats,
  required List<Map<String, dynamic>> stadiumProfits,
  required List<Map<String, dynamic>> bookings,
}) async {
  final fontData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);
  final now = DateTime.now();
  final formattedDate = "${now.day}-${now.month}-${now.year}";
  final formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (context) => [

        // ✅ العنوان وبيانات المالك
        pw.Center(
          child: pw.Text('تقرير تحصيل الملاعب', style: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 10),
        pw.Text('اسم المالك: $ownerName', style: pw.TextStyle(font: ttf, fontSize: 14)),
        pw.Text('رقم الهاتف: $ownerPhone', style: pw.TextStyle(font: ttf, fontSize: 14)),
        pw.Text('تاريخ التقرير: $formattedDate', style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.SizedBox(height: 16),

        // ✅ جدول الأرباح الأسبوعية
        if (weeklyStats.isNotEmpty) ...[
          pw.Text('تفاصيل الأرباح الأسبوعية:', style: pw.TextStyle(font: ttf, fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('الأسبوع', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('المبلغ (ر.ع)', style: pw.TextStyle(font: ttf))),
                ],
              ),
              ...weeklyStats.map((item) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['week'] ?? '', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text((item['value'] ?? 0).toString(), style: pw.TextStyle(font: ttf))),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 20),
        ],

        // ✅ جدول الأرباح حسب الملاعب
        if (stadiumProfits.isNotEmpty) ...[
          pw.Text('تفاصيل الأرباح حسب الملاعب:', style: pw.TextStyle(font: ttf, fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('اسم الملعب', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('المبلغ (ر.ع)', style: pw.TextStyle(font: ttf))),
                ],
              ),
              ...stadiumProfits.map((item) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['stadium'] ?? '', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text((item['amount'] ?? 0).toString(), style: pw.TextStyle(font: ttf))),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 20),
        ],

        // ✅ جدول الحجوزات المؤكدة
        if (bookings.isNotEmpty) ...[
          pw.Text('تفاصيل الحجوزات المؤكدة:', style: pw.TextStyle(font: ttf, fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('التاريخ', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('اسم الملعب', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('الوقت', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('السعر (ر.ع)', style: pw.TextStyle(font: ttf))),
                ],
              ),
              ...bookings.map((item) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['date'] ?? '', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['stadium'] ?? '', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['time'] ?? '—', style: pw.TextStyle(font: ttf))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['price'].toString(), style: pw.TextStyle(font: ttf))),
                ],
              )),
            ],
          ),
        ],

        // ✅ توقيع التطبيق أسفل الصفحة
        pw.SizedBox(height: 32),
        pw.Divider(),
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'تم إنشاء التقرير بواسطة تطبيق ملعبنا - $formattedDate $formattedTime',
            style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey600),
          ),
        ),
      ],
    ),
  );

  final output = await getTemporaryDirectory();
  final filePath = "${output.path}/wallet-report-${DateTime.now().millisecondsSinceEpoch}.pdf";
  final file = File(filePath);
  await file.writeAsBytes(await pdf.save());

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("📄 تم حفظ التقرير في:\n$filePath")),
  );
  await OpenFile.open(filePath);
}

}