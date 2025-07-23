import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/features/admin/presentation/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ExpenseListPage extends StatefulWidget {
  final String? initialProjectId;

  const ExpenseListPage({super.key, this.initialProjectId});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  String? selectedProjectId;

  @override
  void initState() {
    super.initState();
    selectedProjectId = widget.initialProjectId;
  }

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId!;

    return Scaffold(
      drawer: const AdminDrawer(selectedRoute: '/expense-list'),
      appBar: AppBar(title: const Text('Project Expenses')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProjectDropdown(
              companyId: companyId,
              value: selectedProjectId,
              onChanged: (projectId) {
                setState(
                  () =>
                      selectedProjectId = projectId.isEmpty ? null : projectId,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: _ExpenseList(
              companyId: companyId,
              projectId: selectedProjectId,
            ),
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
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final projects = snapshot.data!.docs;
        final items = [
          const DropdownMenuItem(
            value: '',
            child: Row(
              children: [
                Icon(Icons.layers, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text('All Projects'),
              ],
            ),
          ),
          ...projects.map((doc) {
            final project = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Row(
                children: [
                  const Icon(Icons.folder, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(project['title'] ?? 'Untitled'),
                ],
              ),
            );
          }),
        ];

        return DropdownButtonFormField<String>(
          value: value ?? '',
          decoration: const InputDecoration(
            labelText: 'Filter by Project',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: items,
          onChanged: (selected) => onChanged(selected ?? ''),
        );
      },
    );
  }
}

class _ExpenseList extends StatelessWidget {
  final String companyId;
  final String? projectId;

  const _ExpenseList({required this.companyId, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final expenseStream =
        projectId != null
            ? FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('projects')
                .doc(projectId!)
                .collection('expenses')
                .orderBy('date', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collectionGroup('expenses')
                .where('companyId', isEqualTo: companyId)
                .orderBy('date', descending: true)
                .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: expenseStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No expenses found'));
        }

        final expenses = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final expenseDoc = expenses[index];
            final expense = expenseDoc.data() as Map<String, dynamic>;
            final expenseId = expenseDoc.id;
            final parentProjectId = expenseDoc.reference.parent.parent?.id;

            final amount = (expense['amount'] ?? 0).toDouble();
            final name = expense['name'] ?? 'Unnamed Expense';
            final category = expense['category'] ?? 'Misc';
            final date = (expense['date'] as Timestamp?)?.toDate();

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 1,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.receipt_long, color: Colors.blue),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Row(
                  children: [
                    _buildCategoryChip(category),
                    const SizedBox(width: 8),
                    if (date != null)
                      Text(
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                onTap: () {
                  if (parentProjectId != null) {
                    context.push('/edit-expense/$parentProjectId/$expenseId');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getCategoryColor(category),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'material':
        return Colors.orange;
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
