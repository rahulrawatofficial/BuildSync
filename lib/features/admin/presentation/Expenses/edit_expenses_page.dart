import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditExpensePage extends StatefulWidget {
  final String projectId;
  final String expenseId;

  const EditExpensePage({
    super.key,
    required this.projectId,
    required this.expenseId,
  });

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Material'; // default fallback
  bool _loading = true;
  bool _deleting = false;
  late String companyId;

  @override
  void initState() {
    super.initState();
    companyId = AppSessionManager().companyId!;
    _loadExpense();
  }

  Future<void> _loadExpense() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('projects')
            .doc(widget.projectId)
            .collection('expenses')
            .doc(widget.expenseId)
            .get();

    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _detailsController.text = data['details'] ?? '';
      _amountController.text = (data['amount'] ?? '').toString();
      _category = data['category'] ?? 'Material';
    }

    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final expenseData = {
      'name': _nameController.text.trim(),
      'details': _detailsController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim()) ?? 0,
      'category': _category,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .doc(widget.projectId)
        .collection('expenses')
        .doc(widget.expenseId)
        .update(expenseData);

    setState(() => _loading = false);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _deleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Expense'),
            content: const Text(
              'Are you sure you want to delete this expense? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;
    setState(() => _deleting = true);

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .doc(widget.projectId)
        .collection('expenses')
        .doc(widget.expenseId)
        .delete();

    setState(() => _deleting = false);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleting ? null : _deleteExpense,
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _deleting
              ? const Center(
                child: CircularProgressIndicator(color: Colors.red),
              )
              : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Expense Name',
                            ),
                            validator:
                                (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Expense name is required'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _detailsController,
                            decoration: const InputDecoration(
                              labelText: 'Details',
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                            ),
                            validator:
                                (value) =>
                                    value == null ||
                                            double.tryParse(value) == null
                                        ? 'Enter valid amount'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Material',
                                child: Text('Material'),
                              ),
                              DropdownMenuItem(
                                value: 'Labor',
                                child: Text('Labor'),
                              ),
                              DropdownMenuItem(
                                value: 'Misc',
                                child: Text('Miscellaneous'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _submit,
                      // icon: const Icon(Icons.save),
                      label: const Text(
                        'Update Expense',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
