// import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuotePdfGenerator {
  static Future<List<int>> generate(
    Map<String, dynamic> data, {
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();

    final title = data['title'] ?? 'Quote';
    final notes = data['notes'] ?? '';
    final address = data['address'] ?? '';
    final phone = data['phone'] ?? '';

    final startDate =
        (data['startDate'] is Timestamp)
            ? (data['startDate'] as Timestamp).toDate()
            : data['startDate'] as DateTime?;

    final endDate =
        (data['endDate'] is Timestamp)
            ? (data['endDate'] as Timestamp).toDate()
            : data['endDate'] as DateTime?;

    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

    double totalAmount;
    if (data['amount'] != null) {
      final rawAmount = data['amount'];
      if (rawAmount is num) {
        totalAmount = rawAmount.toDouble();
      } else if (rawAmount is String) {
        totalAmount = double.tryParse(rawAmount) ?? 0.0;
      } else {
        totalAmount = 0.0;
      }
    } else {
      totalAmount = items.fold<double>(
        0.0,
        (sum, item) => sum + ((item['amount'] ?? 0) as num).toDouble(),
      );
    }

    final dateFormat = DateFormat('yyyy-MM-dd');

    const companyName = "ADP Group Inc.";
    const companyAddress = "198 Dawn Dr, London, ON";
    const gstNumber = "GST #743426009RT0001";
    const email = "adpgroupinc@gmail.com";
    const website = "www.adpgroupinc.ca";

    final headerStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );

    final sectionTitleStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );

    final normalStyle = pw.TextStyle(fontSize: 10);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        build:
            (context) => [
              // HEADER with LOGO and company info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (logoBytes != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          child: pw.Image(pw.MemoryImage(logoBytes)),
                        ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(companyName, style: headerStyle),
                          pw.SizedBox(height: 2),
                          pw.Text(companyAddress, style: normalStyle),
                          pw.Text(gstNumber, style: normalStyle),
                          pw.Text(email, style: normalStyle),
                          pw.UrlLink(
                            destination: "https://$website",
                            child: pw.Text(
                              website,
                              style: pw.TextStyle(color: PdfColors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (address.isNotEmpty)
                        pw.Text("Client Address: $address", style: normalStyle),
                      if (phone.isNotEmpty)
                        pw.Text("Phone: $phone", style: normalStyle),
                      if (startDate != null)
                        pw.Text(
                          "Start: ${dateFormat.format(startDate)}",
                          style: normalStyle,
                        ),
                      if (endDate != null)
                        pw.Text(
                          "End: ${dateFormat.format(endDate)}",
                          style: normalStyle,
                        ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Title
              pw.Text(title, style: headerStyle),
              pw.SizedBox(height: 24),

              // Estimated Expenses
              pw.Text("Estimated Expenses", style: sectionTitleStyle),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              items.isEmpty
                  ? pw.Text('No items added.', style: normalStyle)
                  : pw.Table.fromTextArray(
                    headers: ['Details', 'Qty', 'Rate', 'Amount'],
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey800,
                    ),
                    cellStyle: normalStyle,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1.2),
                    },
                    data:
                        items.map((item) {
                          final name = item['name'] ?? '';
                          final desc = item['description'] ?? '';
                          final qty = item['quantity']?.toString() ?? '0';
                          final rate = item['rate']?.toString() ?? '0.00';
                          final amount = item['amount']?.toString() ?? '0.00';

                          return [
                            '$name\n${desc.isNotEmpty ? desc : ''}',
                            qty,
                            '\$$rate',
                            '\$$amount',
                          ];
                        }).toList(),
                  ),

              pw.SizedBox(height: 24),

              if (notes.isNotEmpty) ...[
                pw.Text('Notes', style: sectionTitleStyle),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.Text(notes, style: normalStyle),
                pw.SizedBox(height: 16),
              ],

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: \$${totalAmount.toStringAsFixed(2)} CAD',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              pw.SizedBox(height: 16),
              pw.Divider(),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated on ${dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ],
      ),
    );

    return pdf.save();
  }
}
