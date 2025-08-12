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
    companyId = AppSessionManager().companyId ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final expenseData = {
      'name': _nameController.text.trim(),
      'details': _detailsController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim()) ?? 0,
      'category': _category,
      'companyId': companyId,
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
    if (companyId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Expense')),
        body: const Center(
          child: Text('Company ID not found. Please contact administrator.'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Expense Name',
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Expense name is required'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _detailsController,
                    label: 'Details',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _amountController,
                    label: 'Amount',
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || double.tryParse(value) == null
                                ? 'Enter valid amount'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        // fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: InputDecoration(
        labelText: 'Category',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: 'Material', child: Text('Material')),
        DropdownMenuItem(value: 'Labor', child: Text('Labor')),
        DropdownMenuItem(value: 'Misc', child: Text('Miscellaneous')),
      ],
      onChanged: (value) => setState(() => _category = value ?? 'Material'),
    );
  }

  Widget _buildBottomButton() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // backgroundColor: Colors.blueAccent,
          elevation: 3,
        ),
        onPressed: _loading ? null : _submit,
        child:
            _loading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  'Add Expense',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }
}
