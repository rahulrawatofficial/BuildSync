import 'dart:io';

import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:buildsync/shared/widgets/custom_button.dart';
import 'package:buildsync/shared/widgets/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // Load logo
    final logoData = await rootBundle.load('assets/images/adp.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Company Info
    const companyName = "ADP Group Inc.";
    const companyAddress = "198 Dawn Dr, London, ON";
    const gstNumber = "GST #743426009RT0001";
    const email = "adpgroupinc@gmail.com";
    const website = "www.adpgroupinc.ca";

    final headerStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );

    final sectionTitleStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );

    final normalStyle = pw.TextStyle(fontSize: 11, color: PdfColors.black);
    final greyStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        build:
            (context) => [
              /// ---------- HEADER ----------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo + Company Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(logoImage, width: 90),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(companyAddress, style: greyStyle),
                      pw.Text(gstNumber, style: greyStyle),
                      pw.Text(email, style: greyStyle),
                      pw.UrlLink(
                        destination: "https://$website",
                        child: pw.Text(
                          website,
                          style: pw.TextStyle(
                            color: PdfColors.blue,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Document Title + Date
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PROJECT QUOTE', style: headerStyle),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                        style: greyStyle,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 25),

              /// ---------- PROJECT DETAILS ----------
              pw.Text('Project Details', style: sectionTitleStyle),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside: const pw.BorderSide(
                    color: PdfColors.grey300,
                    width: 0.3,
                  ),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(100),
                  1: const pw.FlexColumnWidth(),
                },
                children: [
                  _buildDetailRow('Title', title.isNotEmpty ? title : 'N/A'),
                  _buildDetailRow(
                    'Client Name',
                    clientName.isNotEmpty ? clientName : 'N/A',
                  ),
                  _buildDetailRow(
                    'Address',
                    address.isNotEmpty ? address : 'N/A',
                  ),
                  _buildDetailRow('Status', status.toUpperCase()),
                  _buildDetailRow(
                    'Start Date',
                    startDate != null ? dateFormat.format(startDate!) : 'N/A',
                  ),
                  _buildDetailRow(
                    'End Date',
                    endDate != null ? dateFormat.format(endDate!) : 'N/A',
                  ),
                  _buildDetailRow(
                    'Budget',
                    '\$${(budget ?? 0).toStringAsFixed(2)} CAD',
                  ),
                  if (notes.isNotEmpty) _buildDetailRow('Notes', notes),
                ],
              ),

              pw.SizedBox(height: 25),

              /// ---------- EXPENSES TABLE ----------
              pw.Text('Expected Expenses', style: sectionTitleStyle),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              expenses.isEmpty
                  ? pw.Text('No expenses added.', style: greyStyle)
                  : pw.Table.fromTextArray(
                    headers: ['Title', 'Amount (CAD)'],
                    data:
                        expenses
                            .map(
                              (e) => [
                                e['title'] ?? '',
                                '\$${(double.tryParse(e['amount'].toString()) ?? 0).toStringAsFixed(2)}',
                              ],
                            )
                            .toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey800,
                    ),
                    cellStyle: normalStyle,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerRight,
                    },
                    cellPadding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: pw.TableBorder.all(
                      width: 0.5,
                      color: PdfColors.grey400,
                    ),
                  ),

              pw.SizedBox(height: 30),

              /// ---------- FOOTER ----------
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Quote Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: greyStyle,
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.TableRow _buildDetailRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(value),
        ),
      ],
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
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'pdf':
                  generateQuotePdf();
                  break;
                case 'delete':
                  deleteProject();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Generate PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Project'),
                      ],
                    ),
                  ),
                ],
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
                  _buildProjectInfoSection(),
                  const SizedBox(height: 12),
                  _buildDatePickers(),

                  const SizedBox(height: 12),
                  _buildExpensesSection(),
                  const SizedBox(height: 12),
                  _buildNotesSection(),
                  const SizedBox(height: 12),
                  _buildPhotosSection(),
                  const SizedBox(height: 80), // Space for sticky button
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
            text: 'Update Project',
            onPressed: isSaving ? null : updateProject,
            isLoading: isSaving,
            icon: Icons.save,
          ),
        ),
      ),
    );
  }

  // Inside _EditProjectPageState
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
                  initialValue: title,
                  label: "Project Title",
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
                  initialValue: clientName,
                  label: 'Client Name',
                  onSaved: (val) => clientName = val ?? '',
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  initialValue: address,
                  label: 'Address',
                  onSaved: (val) => address = val ?? '',
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  initialValue: budget?.toString(),
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
              initialValue: notes,
              label: 'Notes (optional)',
              maxLines: 3,
              onSaved: (val) => notes = val ?? '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
        title: const Text(
          'Project Photos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          // const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...existingImageUrls.map(
                  (url) => Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed:
                            () => setState(() => existingImageUrls.remove(url)),
                      ),
                    ],
                  ),
                ),
                ...images.map(
                  (img) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(img.path),
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
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
        leading: const Icon(Icons.calendar_month, color: Colors.teal),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Date',
                          style: TextStyle(
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
                              const Icon(Icons.date_range, color: Colors.teal),
                              Text(
                                startDate != null
                                    ? dateFormat.format(startDate!)
                                    : 'Select',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      startDate != null
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => pickDate(isStart: false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Date',
                          style: TextStyle(
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
                              const Icon(Icons.event, color: Colors.deepOrange),
                              Text(
                                endDate != null
                                    ? dateFormat.format(endDate!)
                                    : 'Select',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      endDate != null
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      const Icon(
                        Icons.edit_note,
                        size: 18,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Expense #${index + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
}
