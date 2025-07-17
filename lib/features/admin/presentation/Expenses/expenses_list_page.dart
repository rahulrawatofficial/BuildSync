import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  String? selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId;

    return Scaffold(
      appBar: AppBar(title: const Text('Project Expenses')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProjectDropdown(
              companyId: companyId!,
              value: selectedProjectId,
              onChanged: (projectId) {
                setState(() => selectedProjectId = projectId);
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          if (selectedProjectId != null)
            Expanded(
              child: _ExpenseList(
                companyId: companyId,
                projectId: selectedProjectId!,
              ),
            )
          else
            const Expanded(
              child: Center(child: Text('Select a project to view expenses')),
            ),
        ],
      ),
      floatingActionButton:
          selectedProjectId != null
              ? FloatingActionButton.extended(
                onPressed: () {
                  context.push('/add-expense/${selectedProjectId!}');
                },
                label: const Text('Add Expense'),
                icon: const Icon(Icons.add),
              )
              : null,
    );
  }
}

class _ProjectDropdown extends StatelessWidget {
  final String companyId;
  final String? value;
  final void Function(String) onChanged;

  const _ProjectDropdown({
    required this.companyId,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('projects')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final docs = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(labelText: 'Select Project'),
          items:
              docs.map((doc) {
                final project = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(project['title'] ?? 'Untitled'),
                );
              }).toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        );
      },
    );
  }
}

class _ExpenseList extends StatelessWidget {
  final String companyId;
  final String projectId;

  const _ExpenseList({required this.companyId, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('projects')
              .doc(projectId)
              .collection('expenses')
              .orderBy('date', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No expenses found'));
        }

        final expenses = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expenseDoc = expenses[index];
            final expense = expenseDoc.data() as Map<String, dynamic>;
            final expenseId = expenseDoc.id;

            final amount = expense['amount'] ?? 0;
            final name = expense['name'] ?? 'Unnamed Expense';
            final category = expense['category'] ?? 'Misc';
            final paidBy = expense['paidBy'] ?? 'Unknown';
            final date = (expense['date'] as Timestamp?)?.toDate();

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Name + Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Paid By + Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid by: $paidBy',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (date != null)
                        Text(
                          _formatDate(date),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Edit Button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: () {
                        context.push('/edit-expense/$projectId/$expenseId');
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'material':
        return Colors.orangeAccent;
      case 'labor':
        return Colors.green;
      case 'misc':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
