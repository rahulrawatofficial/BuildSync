import 'package:buildsync/core/config/app_setion_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportsListPage extends StatelessWidget {
  const ReportsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = AppSessionManager().companyId!;

    return Scaffold(
      appBar: AppBar(title: const Text('Project Reports')),
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
            return const Center(child: Text('No projects available'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final doc = projects[index];
              final data = doc.data() as Map<String, dynamic>;
              final projectId = doc.id;

              final status = data['status'] ?? 'active';
              final title = data['title'] ?? 'Untitled Project';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Status: ${status.toUpperCase()}'),
                  trailing:
                      status == 'completed'
                          ? const Icon(Icons.lock, color: Colors.green)
                          : ElevatedButton(
                            onPressed: () {
                              context.push('/edit-report/$projectId');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                            ),
                            child: const Text(
                              'Edit Report',
                              style: TextStyle(color: Colors.white),
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
}
