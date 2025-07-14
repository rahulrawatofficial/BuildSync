import 'package:buildsync/shared/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditWorkerPage extends StatefulWidget {
  final String workerId;
  final Map<String, dynamic> workerData;

  const EditWorkerPage({
    super.key,
    required this.workerId,
    required this.workerData,
  });

  @override
  State<EditWorkerPage> createState() => _EditWorkerPageState();
}

class _EditWorkerPageState extends State<EditWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  late String name;
  late String email;
  late String role;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    name = widget.workerData['name'] ?? '';
    email = widget.workerData['email'] ?? '';
    role = widget.workerData['role'] ?? 'worker';
    _phoneController.text = widget.workerData['phone'] ?? '';
  }

  Future<void> updateWorker() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.workerId)
        .update({
          'name': name,
          'email': email,
          'phone': _phoneController.text.trim(),
          'role': role,
          'updatedAt': DateTime.now().toIso8601String(),
        });

    setState(() => isLoading = false);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Team Member')),
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
                    'Update details for this member',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // 👤 Name
                  TextFormField(
                    initialValue: name,
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
                    initialValue: email,
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
                    text: 'Update Project',
                    onPressed: isLoading ? null : updateWorker,
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
