import 'dart:io';

import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/shared/widgets/custom_button.dart';
import 'package:buildsync/shared/widgets/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EditProjectPage extends StatefulWidget {
  final String projectId;
  const EditProjectPage({super.key, required this.projectId});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String status = 'active';
  String clientName = '';
  String address = '';
  double? budget;
  DateTime? startDate;
  DateTime? endDate;
  String notes = '';
  bool isLoading = true;
  bool isSaving = false;
  List<Map<String, dynamic>> expenses = [];
  List<XFile> images = [];
  final ImagePicker _picker = ImagePicker();

  final dateFormat = DateFormat('yyyy-MM-dd');
  List<String> existingImageUrls = []; // existing Firebase URLs

  @override
  void initState() {
    super.initState();
    loadProjectData();
  }

  Future<void> generateQuotePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Project Quote',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Project Title: $title'),
              pw.Text('Client Name: $clientName'),
              pw.Text('Address: $address'),
              pw.Text('Status: ${status.toUpperCase()}'),
              pw.SizedBox(height: 10),
              pw.Text(
                'Start Date: ${startDate != null ? dateFormat.format(startDate!) : 'N/A'}',
              ),
              pw.Text(
                'End Date: ${endDate != null ? dateFormat.format(endDate!) : 'N/A'}',
              ),
              pw.SizedBox(height: 10),
              pw.Text('Budget: \$${budget?.toStringAsFixed(2) ?? '0.00'} CAD'),
              pw.SizedBox(height: 10),
              if (notes.isNotEmpty) pw.Text('Notes: $notes'),
              pw.SizedBox(height: 20),

              pw.Text(
                'Expected Expenses:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ['Title', 'Amount (CAD)'],
                data:
                    expenses
                        .map((e) => [e['title'] ?? '', e['amount'] ?? ''])
                        .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                border: pw.TableBorder.all(),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> deleteProject() async {
    final companyId = AppSessionManager().companyId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Project'),
            content: const Text(
              'Are you sure you want to delete this project? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('projects')
            .doc(widget.projectId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted successfully')),
          );
          Navigator.pop(context); // Go back after deletion
        }
      } catch (e) {
        print('Delete failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete project')),
          );
        }
      }
    }
  }

  Future<void> loadProjectData() async {
    final companyId = AppSessionManager().companyId;
    final doc =
        await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('projects')
            .doc(widget.projectId)
            .get();

    final data = doc.data();
    if (data == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      title = data['title'] ?? '';
      status = data['status'] ?? 'active';
      clientName = data['clientName'] ?? '';
      address = data['address'] ?? '';
      budget =
          (data['budget'] is num) ? (data['budget'] as num).toDouble() : null;
      startDate =
          data['startDate'] != null
              ? DateTime.tryParse(data['startDate'])
              : null;
      endDate =
          data['endDate'] != null ? DateTime.tryParse(data['endDate']) : null;
      notes = data['notes'] ?? '';
      expenses =
          (data['expenses'] as List<dynamic>?)
              ?.map(
                (e) => {
                  'title': e['label'] ?? '',
                  'amount': e['amount'].toString(),
                },
              )
              .toList() ??
          [];
      existingImageUrls = List<String>.from(data['imageUrls'] ?? []);
      isLoading = false;
    });
  }

  Future<void> updateProject() async {
    final companyId = AppSessionManager().companyId;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => isSaving = true);

    List<String> imageUrls = [...existingImageUrls];
    for (var image in images) {
      if (image.path.isEmpty) continue;
      final file = File(image.path);
      if (!file.existsSync()) {
        print('File does not exist: ${image.path}');
        continue;
      }

      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('project_images')
            .child(
              '${widget.projectId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );

        print('Uploading to: ${ref.fullPath}');
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        print('Upload failed for ${file.path}: $e');
      }
    }

    final cleanedExpenses =
        expenses
            .where(
              (e) =>
                  e['title'] != null &&
                  e['amount'] != null &&
                  e['title'].toString().isNotEmpty,
            )
            .map(
              (e) => {
                "label": e['title'],
                "amount": double.tryParse(e['amount'].toString()) ?? 0.0,
              },
            )
            .toList();

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('projects')
        .doc(widget.projectId)
        .update({
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
          'expenses': cleanedExpenses,
          'imageUrls': imageUrls,
        });

    setState(() => isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  void addExpenseField() {
    setState(() => expenses.add({"title": "", "amount": ""}));
  }

  void removeExpense(int index) {
    setState(() => expenses.removeAt(index));
  }

  Future<void> pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() => images.addAll(pickedFiles));
    }
  }

  Future<void> pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isStart
              ? (startDate ?? DateTime.now())
              : (endDate ?? startDate ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(startDate!)) endDate = null;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project'),
        actions: [
          IconButton(
            onPressed: deleteProject,
            icon: Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
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
                  SizedBox(height: 10),
                  CustomTextField(
                    initialValue: title,
                    label: "Project Title",
                    onSaved: (val) => title = val?.trim() ?? '',
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Enter project title'
                                : null,
                  ),
                  SizedBox(height: 10),
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
                    onChanged:
                        (val) => setState(() => status = val ?? 'active'),
                  ),
                  SizedBox(height: 10),
                  CustomTextField(
                    initialValue: clientName,
                    label: 'Client Name',
                    onSaved: (val) => clientName = val ?? '',
                  ),
                  SizedBox(height: 10),
                  CustomTextField(
                    initialValue: address,
                    label: 'Address',
                    onSaved: (val) => address = val ?? '',
                  ),
                  SizedBox(height: 10),
                  CustomTextField(
                    initialValue: budget?.toString(),

                    label: 'Budget (CAD)',

                    keyboardType: TextInputType.number,
                    onSaved: (val) => budget = double.tryParse(val ?? ''),
                  ),
                  SizedBox(height: 10),
                  Row(
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
                                  : 'Select',
                            ),
                            onTap: () => pickDate(isStart: true),
                          ),
                        ),
                      ),
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
                                  : 'Select',
                            ),
                            onTap: () => pickDate(isStart: false),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),
                  CustomTextField(
                    initialValue: notes,
                    label: 'Notes',
                    maxLines: 3,
                    onSaved: (val) => notes = val ?? '',
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Expenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ...expenses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final expense = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              initialValue: expense['title']?.toString() ?? '',
                              label: 'Title',
                              onChanged:
                                  (val) => expenses[index]['title'] = val,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              initialValue: expense['amount']?.toString() ?? '',
                              label: 'Amount',
                              keyboardType: TextInputType.number,
                              onChanged:
                                  (val) => expenses[index]['amount'] = val,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => removeExpense(index),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: addExpenseField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),

                  const SizedBox(height: 24),
                  Text('Photos', style: Theme.of(context).textTheme.titleLarge),
                  Wrap(
                    spacing: 8,
                    children: [
                      ...existingImageUrls.map(
                        (url) => Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.network(url, height: 100),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed:
                                  () => setState(
                                    () => existingImageUrls.remove(url),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ...images.map(
                        (img) => Image.file(File(img.path), height: 100),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Images'),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: generateQuotePdf,
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Generate Quote',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Update Project',
                    onPressed: isSaving ? null : updateProject,
                    isLoading: isSaving,
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
