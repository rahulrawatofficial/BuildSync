import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/shared/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateWorkerPage extends StatefulWidget {
  const CreateWorkerPage({super.key});

  @override
  State<CreateWorkerPage> createState() => _CreateWorkerPageState();
}

class _CreateWorkerPageState extends State<CreateWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  String name = '';
  String email = '';
  String role = 'worker';
  bool isLoading = false;

  Future<void> submitWorker() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final companyId = AppSessionManager().companyId;
    if (companyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Company ID not found')));
      return;
    }

    setState(() => isLoading = true);

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .add({
          'name': name,
          'email': email,
          'phone': _phoneController.text.trim(),
          'role': role,
          'createdAt': DateTime.now().toIso8601String(),
        });

    setState(() => isLoading = false);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Worker / Supervisor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 500 : double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Fill details to add a new team member',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // 👤 Name
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onSaved: (val) => name = val?.trim() ?? '',
                    validator:
                        (val) =>
                            val == null || val.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 16),

                  // 📧 Email
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (val) => email = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),

                  // 📱 Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator:
                        (val) =>
                            val == null || val.length < 10
                                ? 'Enter valid phone number'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  // 🛠️ Role Dropdown
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'worker', child: Text('Worker')),
                      DropdownMenuItem(
                        value: 'supervisor',
                        child: Text('Supervisor'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) => setState(() => role = val ?? 'worker'),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Add Member',
                    onPressed: isLoading ? null : submitWorker,
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
