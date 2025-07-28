import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/core/extensions/string_extensions.dart';
import 'package:buildsync/shared/widgets/custom_button.dart';
import 'package:buildsync/shared/widgets/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String status = 'active';
  String clientName = '';
  String address = '';
  double? budget;
  DateTime? startDate;
  DateTime? endDate;
  String notes = '';
  bool isLoading = false;
  List<Map<String, dynamic>> expenses = [];

  final dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> submitProject() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    _formKey.currentState!.save();

    final companyId = AppSessionManager().companyId;
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .add({
          'title': title,
          'status': status,
          'clientName': clientName,
          'address': address,
          'budget': budget ?? 0.0,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'notes': notes,
          'updatedAt': DateTime.now().toIso8601String(),
          'companyId': companyId,
          'expenses':
              expenses
                  .where((e) => (e['title'] ?? '').toString().isNotEmpty)
                  .map(
                    (e) => {
                      "label": e['title'],
                      "amount":
                          double.tryParse((e['amount'] ?? '0').toString()) ??
                          0.0,
                    },
                  )
                  .toList(),
          // 'imageUrls': imageUrls,
          'createdAt': FieldValue.serverTimestamp(),
        });

    setState(() => isLoading = false);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? DateTime.now() : (startDate ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  void addExpenseField() {
    setState(() => expenses.add({"title": "", "amount": ""}));
  }

  void removeExpense(int index) {
    setState(() => expenses.removeAt(index));
  }

  Widget _buildProjectInfoSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.info_outline, color: Colors.teal),
        title: const Text(
          'Project Info',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          // const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CustomTextField(
                  label: 'Project Title',
                  onSaved: (val) => title = val?.trim() ?? '',
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Enter project title'
                              : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['active', 'pending', 'completed']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => status = val ?? 'active'),
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Client Name',
                  onSaved: (val) => clientName = val ?? '',
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Address',
                  onSaved: (val) => address = val ?? '',
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Budget (CAD)',
                  keyboardType: TextInputType.number,
                  onSaved: (val) => budget = double.tryParse(val ?? ''),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickers() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_month, color: Colors.deepOrange),
        title: const Text(
          'Project Dates',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          // const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => pickDate(isStart: true),
                    child: _buildDateBox(
                      label: 'Start Date',
                      date: startDate,
                      icon: Icons.date_range,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => pickDate(isStart: false),
                    child: _buildDateBox(
                      label: 'End Date',
                      date: endDate,
                      icon: Icons.event,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox({
    required String label,
    required DateTime? date,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(
                date != null ? dateFormat.format(date) : 'Select',
                style: TextStyle(
                  fontSize: 16,
                  color: date != null ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.receipt_long, color: Colors.blueAccent),
        title: const Text(
          'Estimated Expenses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          // const Divider(height: 1),
          ...expenses.asMap().entries.map((entry) {
            final index = entry.key;
            final expense = entry.value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Expense #${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => removeExpense(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    initialValue: expense['title']?.toString() ?? '',
                    label: 'Title',
                    maxLines: 2,
                    onChanged: (val) => expenses[index]['title'] = val,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    initialValue: expense['amount']?.toString() ?? '',
                    label: 'Amount (CAD)',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => expenses[index]['amount'] = val,
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: addExpenseField,
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.note_alt, color: Colors.purple),
        title: const Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          // const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: CustomTextField(
              label: 'Notes (optional)',
              maxLines: 3,
              onSaved: (val) => notes = val ?? '',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Project')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 600 : double.infinity,
              ),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  _buildProjectInfoSection(),
                  const SizedBox(height: 16),
                  _buildDatePickers(),
                  const SizedBox(height: 16),
                  _buildExpensesSection(),
                  const SizedBox(height: 16),
                  _buildNotesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CustomButton(
            text: 'Create Project',
            onPressed: isLoading ? null : submitProject,
            isLoading: isLoading,
            // icon: Icons.save,
          ),
        ),
      ),
    );
  }
}
