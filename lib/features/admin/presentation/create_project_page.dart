import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/core/extensions/string_extensions.dart';
import 'package:buildsync/shared/widgets/custom_button.dart';
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
          'createdAt': DateTime.now().toIso8601String(),
          'companyId': companyId,
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Project')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 600 : double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // 🔤 Project Title
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Project Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    onSaved: (val) => title = val?.trim() ?? '',
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Enter project title'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  // 📊 Status Dropdown
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items:
                        ['active', 'pending', 'completed']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.capitalize()),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (val) => setState(() => status = val ?? 'active'),
                  ),
                  const SizedBox(height: 16),

                  // 👤 Client Name
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onSaved: (val) => clientName = val ?? '',
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Enter client name'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  // 📍 Address
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    onSaved: (val) => address = val ?? '',
                  ),
                  const SizedBox(height: 16),

                  // 💰 Budget
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Budget (in CAD)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (val) => budget = double.tryParse(val ?? ''),
                  ),
                  const SizedBox(height: 16),

                  // 📅 Start Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Start Date'),
                            subtitle: Text(
                              startDate != null
                                  ? dateFormat.format(startDate!)
                                  : 'Select start date',
                            ),
                            onTap: () => pickDate(isStart: true),
                          ),
                        ),
                      ),
                      // 📅 End Date
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.event),
                            title: const Text('End Date'),
                            subtitle: Text(
                              endDate != null
                                  ? dateFormat.format(endDate!)
                                  : 'Select end date',
                            ),
                            onTap: () => pickDate(isStart: false),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 📝 Notes
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    onSaved: (val) => notes = val ?? '',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Create Project',
                    onPressed: isLoading ? null : submitProject,
                    isLoading: isLoading,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
