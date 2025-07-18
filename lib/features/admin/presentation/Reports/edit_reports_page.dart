import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String reportNotes = '';
  double totalExpenses = 0;
  int totalTasks = 0;
  int completedTasks = 0;

  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    companyId = AppSessionManager().companyId!;
    _loadReportData();
  }

  List<QueryDocumentSnapshot> taskDocs = [];
  List<QueryDocumentSnapshot> expenseDocs = [];

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
      appBar: AppBar(title: const Text('Edit Report')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project: ${projectData['title'] ?? 'Untitled'}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    _buildSummaryCard(taskDocs, expenseDocs),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Final Notes / Remarks',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _markComplete,
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Mark as Completed',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _generatePDF,
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Generate PDF Bill',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
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
    // Calculate totals
    final double taskTotal = tasks.fold<double>(
      0,
      (sum, t) => sum + (t['estimatedCost'] ?? 0),
    );
    final double expenseTotal = expenses.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] ?? 0),
    );
    final double grandTotal = taskTotal + expenseTotal;
    final double tax = grandTotal * 0.13; // 13% Tax
    final double finalTotal = grandTotal + tax;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Project Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tasks Section
            const Text(
              'Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...tasks.map((taskDoc) {
              final task = taskDoc.data() as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(task['title'] ?? 'Unnamed Task'),
                subtitle: Text('Status: ${task['status'] ?? 'unknown'}'),
                trailing: Text(
                  '\$${(task['estimatedCost'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            const Divider(thickness: 1),

            // Expenses Section
            const SizedBox(height: 8),
            const Text(
              'Expenses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...expenses.map((expDoc) {
              final expense = expDoc.data() as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.zero,
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
            }).toList(),

            const Divider(thickness: 1),
            const SizedBox(height: 8),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Tasks Cost',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('\$${taskTotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Expenses',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('\$${expenseTotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tax (13%)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('\$${tax.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Final Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '\$${finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    // Load logo
    final logoData = await rootBundle.load('assets/images/adp.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Calculate totals
    final double taskTotal = taskDocs.fold<double>(
      0,
      (sum, t) => sum + (t['estimatedCost'] ?? 0),
    );
    final double expenseTotal = expenseDocs.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] ?? 0),
    );
    final double grandTotal = taskTotal + expenseTotal;
    final double tax = grandTotal * 0.13;
    final double finalTotal = grandTotal + tax;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 80, height: 80),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Invoice",
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text("Date: ${DateTime.now().toLocal()}"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                "Project: ${projectData['title'] ?? 'Untitled'}",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              // Tasks
              pw.Text(
                "Tasks:",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Table.fromTextArray(
                headers: ["Task", "Status", "Cost"],
                data:
                    taskDocs.map((t) {
                      final task = t.data() as Map<String, dynamic>;
                      return [
                        task['title'] ?? '',
                        task['status'] ?? '',
                        "\$${(task['estimatedCost'] ?? 0).toStringAsFixed(2)}",
                      ];
                    }).toList(),
              ),
              pw.SizedBox(height: 10),

              // Expenses
              pw.Text(
                "Expenses:",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Table.fromTextArray(
                headers: ["Name", "Details", "Amount"],
                data:
                    expenseDocs.map((e) {
                      final exp = e.data() as Map<String, dynamic>;
                      return [
                        exp['name'] ?? '',
                        exp['details'] ?? '',
                        "\$${(exp['amount'] ?? 0).toStringAsFixed(2)}",
                      ];
                    }).toList(),
              ),
              pw.Divider(),

              // Totals
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
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );

    // Show PDF Preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
