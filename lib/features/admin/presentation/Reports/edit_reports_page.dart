import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
}
