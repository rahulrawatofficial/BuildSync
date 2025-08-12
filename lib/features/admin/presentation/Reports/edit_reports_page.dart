import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EditReportPage extends StatefulWidget {
  final String projectId;

  const EditReportPage({super.key, required this.projectId});

  @override
  State<EditReportPage> createState() => _EditReportPageState();
}

class _EditReportPageState extends State<EditReportPage> {
  bool _loading = true;
  bool _sessionLoading = true;
  String companyId = '';
  Map<String, dynamic> projectData = {};
  final _notesController = TextEditingController();

  List<QueryDocumentSnapshot> expenseDocs = [];

  @override
  void initState() {
    super.initState();
    _loadSessionAndData();
  }

  Future<void> _loadSessionAndData() async {
    await AppSessionManager().loadSession();
    if (mounted) {
      setState(() {
        companyId = AppSessionManager().companyId ?? '';
        _sessionLoading = false;
      });
      
      if (companyId.isNotEmpty) {
        _loadReportData();
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadReportData() async {
    final projectDoc =
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('projects')
            .doc(widget.projectId)
            .get();

    projectData = projectDoc.data() ?? {};
    _notesController.text = projectData['reportNotes'] ?? '';

    final expensesSnapshot =
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('projects')
            .doc(widget.projectId)
            .collection('expenses')
            .get();
    expenseDocs = expensesSnapshot.docs;

    setState(() => _loading = false);
  }

  Future<void> _markComplete() async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .doc(widget.projectId)
        .update({
          'reportNotes': _notesController.text.trim(),
          'status': 'completed',
          'reportCompletedAt': FieldValue.serverTimestamp(),
        });

    if (context.mounted) Navigator.pop(context);
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'pdf':
        _generatePDF();
        break;
      case 'share':
        // TODO: implement share
        break;
    }
  }

    @override
  Widget build(BuildContext context) {
    if (_sessionLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (companyId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Report')),
        body: const Center(
          child: Text('Company ID not found. Please contact administrator.'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Report'),
        centerTitle: true,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'pdf', child: Text('Generate PDF')),
                  PopupMenuItem(value: 'share', child: Text('Share Report')),
                ],
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.business,
                              size: 28,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                projectData['title'] ?? 'Untitled Project',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(expenseDocs),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Final Notes / Remarks',
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 80), // spacing for sticky button
                  ],
                ),
              ),
      bottomNavigationBar:
          _loading
              ? null
              : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _markComplete,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Mark Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSummaryCard(List<QueryDocumentSnapshot> expenses) {
    final double expenseTotal = expenses.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] ?? 0),
    );
    final double tax = expenseTotal * 0.13;
    final double finalTotal = expenseTotal + tax;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...expenses.map((expDoc) {
              final expense = expDoc.data() as Map<String, dynamic>;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_money, color: Colors.black54),
                title: Text(expense['name'] ?? 'Unnamed Expense'),
                subtitle: Text(expense['details'] ?? ''),
                trailing: Text(
                  '\$${(expense['amount'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
            const Divider(thickness: 0.8),
            const SizedBox(height: 8),
            _buildTotalRow('Total Expenses', expenseTotal),
            _buildTotalRow('Tax (13%)', tax),
            _buildTotalRow('Final Total', finalTotal, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    // Load logo
    final logoData = await rootBundle.load('assets/images/adp.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Company Info
    const companyName = "ADP Group Inc.";
    const companyAddress = "198 Dawn Dr, London, ON";
    const gstNumber = "GST #743426009RT0001";
    const email = "adpgroupinc@gmail.com";
    const website = "www.adpgroupinc.ca";

    // Project Info
    final title = projectData['title'] ?? 'Untitled Project';
    final clientName = projectData['clientName'] ?? 'N/A';
    final clientAddress = projectData['address'] ?? 'N/A';
    final status = projectData['status'] ?? 'Active';

    final dateFormat = DateFormat('yyyy-MM-dd');
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final startDate = _parseDate(projectData['startDate']);
    final endDate = _parseDate(projectData['endDate']);

    // Expenses
    final expenses =
        expenseDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    final expenseTotal = expenses.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] ?? 0),
    );
    final tax = expenseTotal * 0.13;
    final finalTotal = expenseTotal + tax;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              // HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(logoImage, width: 80),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(companyAddress),
                      pw.Text(gstNumber),
                      pw.Text(email),
                      pw.UrlLink(
                        destination: "https://$website",
                        child: pw.Text(
                          website,
                          style: pw.TextStyle(color: PdfColors.blue),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Date: ${dateFormat.format(DateTime.now())}'),
                      pw.Text('Status: ${status.toUpperCase()}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // PROJECT INFO
              pw.Text(
                'Project Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Title: $title'),
              pw.Text('Client Name: $clientName'),
              pw.Text('Address: $clientAddress'),
              pw.Text(
                'Start Date: ${startDate != null ? dateFormat.format(startDate) : 'N/A'}',
              ),
              pw.Text(
                'End Date: ${endDate != null ? dateFormat.format(endDate) : 'N/A'}',
              ),
              pw.SizedBox(height: 20),

              // EXPENSES
              pw.Text(
                'Expenses',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Title', 'Details', 'Amount'],
                data:
                    expenses
                        .map(
                          (e) => [
                            e['name'] ?? 'Unnamed Expense',
                            e['details'] ?? '',
                            "\$${(e['amount'] ?? 0).toStringAsFixed(2)}",
                          ],
                        )
                        .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
              pw.SizedBox(height: 20),

              // TOTALS
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Expenses Total: \$${expenseTotal.toStringAsFixed(2)}",
                    ),
                    pw.Text("Tax (13%): \$${tax.toStringAsFixed(2)}"),
                    pw.Text(
                      "Final Total: \$${finalTotal.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
