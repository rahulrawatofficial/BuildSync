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
  late String companyId;
  Map<String, dynamic> projectData = {};
  final _notesController = TextEditingController();

  List<QueryDocumentSnapshot> taskDocs = [];
  List<QueryDocumentSnapshot> expenseDocs = [];

  @override
  void initState() {
    super.initState();
    companyId = AppSessionManager().companyId!;
    _loadReportData();
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

    final tasksSnapshot =
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('projects')
            .doc(widget.projectId)
            .collection('tasks')
            .get();
    taskDocs = tasksSnapshot.docs;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Report'),
        centerTitle: true,
        elevation: 2,
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
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.business,
                              color: Colors.blue,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                projectData['title'] ?? 'Untitled Project',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSummaryCard(taskDocs, expenseDocs),
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
                    const SizedBox(height: 80), // Space for sticky buttons
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
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _markComplete,
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Mark Completed',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generatePDF,
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Generate PDF',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryCard(
    List<QueryDocumentSnapshot> tasks,
    List<QueryDocumentSnapshot> expenses,
  ) {
    final double taskTotal = tasks.fold<double>(
      0,
      (sum, t) => sum + (t['estimatedCost'] ?? 0),
    );
    final double expenseTotal = expenses.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] ?? 0),
    );
    final double grandTotal = taskTotal + expenseTotal;
    final double tax = grandTotal * 0.13;
    final double finalTotal = grandTotal + tax;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.summarize, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Project Summary',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...tasks.map((taskDoc) {
              final task = taskDoc.data() as Map<String, dynamic>;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.task_alt, color: Colors.green),
                title: Text(task['title'] ?? 'Unnamed Task'),
                subtitle: Text('Status: ${task['status'] ?? 'unknown'}'),
                trailing: Text(
                  '\$${(task['estimatedCost'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
            const Divider(thickness: 1),
            const Text(
              'Expenses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...expenses.map((expDoc) {
              final expense = expDoc.data() as Map<String, dynamic>;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.attach_money,
                  color: Colors.redAccent,
                ),
                title: Text(expense['name'] ?? 'Unnamed Expense'),
                subtitle: Text(expense['details'] ?? ''),
                trailing: Text(
                  '\$${(expense['amount'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            }),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            _buildTotalRow('Total Tasks Cost', taskTotal),
            _buildTotalRow('Total Expenses', expenseTotal),
            _buildTotalRow('Grand Total', grandTotal, color: Colors.blue),
            _buildTotalRow('Tax (13%)', tax),
            _buildTotalRow(
              'Final Total',
              finalTotal,
              color: Colors.green,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    Color color = Colors.black,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
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
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final startDate = _parseDate(projectData['startDate']);
    final endDate = _parseDate(projectData['endDate']);
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Tasks & Expenses
    final tasks =
        taskDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    final expenses =
        expenseDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    final taskTotal = tasks.fold<double>(
      0,
      (sum, t) => sum + (t['estimatedCost'] ?? 0),
    );
    final expenseTotal = expenses.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] ?? 0),
    );
    final grandTotal = taskTotal + expenseTotal;
    final tax = grandTotal * 0.13;
    final finalTotal = grandTotal + tax;

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
                      pw.Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                      ),
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

              // TASKS
              pw.Text(
                'Tasks',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Task', 'Status', 'Cost'],
                data:
                    tasks
                        .map(
                          (t) => [
                            t['title'] ?? 'Unnamed Task',
                            t['status'] ?? 'N/A',
                            "\$${(t['estimatedCost'] ?? 0).toStringAsFixed(2)}",
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
                    pw.Text("Tasks Total: \$${taskTotal.toStringAsFixed(2)}"),
                    pw.Text(
                      "Expenses Total: \$${expenseTotal.toStringAsFixed(2)}",
                    ),
                    pw.Text("Grand Total: \$${grandTotal.toStringAsFixed(2)}"),
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
