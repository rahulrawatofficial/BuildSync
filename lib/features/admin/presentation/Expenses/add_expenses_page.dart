import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddExpensePage extends StatefulWidget {
  final String projectId;

  const AddExpensePage({super.key, required this.projectId});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Material'; // default category
  late String companyId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    companyId = AppSessionManager().companyId!;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final expenseData = {
      'name': _nameController.text.trim(),
      'details': _detailsController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim()) ?? 0,
      'category': _category,
      // 'paidBy': AppSessionManager().userId, // or name
      'date': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .doc(widget.projectId)
        .collection('expenses')
        .add(expenseData);

    setState(() => _loading = false);

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
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
                        decoration: const InputDecoration(labelText: 'Details'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        validator:
                            (value) =>
                                value == null || double.tryParse(value) == null
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
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check),
                        label: const Text('Add Expense'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
