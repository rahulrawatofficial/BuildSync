import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReportsListPage extends StatelessWidget {
  const ReportsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId!;

    return Scaffold(
      appBar: AppBar(title: const Text('Project Reports'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('projects')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final projects = snapshot.data!.docs;

          if (projects.isEmpty) {
            return const Center(child: Text('No reports found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = projects[index];
              final data = doc.data() as Map<String, dynamic>;
              final projectId = doc.id;

              final status =
                  (data['status'] ?? 'active').toString().toLowerCase();
              final title = data['title'] ?? 'Untitled Project';
              final createdAt = _formatDate(data['createdAt']);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1.5,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Status: ${status.toUpperCase()} • $createdAt",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      context.push('/edit-report/$projectId');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          status == 'completed' ? Colors.green : Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      status == 'completed' ? 'View' : 'Edit',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'No Date';
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is DateTime) {
      date = value;
    }
    return date != null ? DateFormat('MMM dd, yyyy').format(date) : 'No Date';
  }
}
