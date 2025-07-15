import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _WorkerSelector extends StatelessWidget {
  final String companyId;
  final List<String> selectedIds;
  final void Function(List<String>) onChanged;

  const _WorkerSelector({
    required this.companyId,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('workers')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final workers = snapshot.data!.docs;

        return Column(
          children:
              workers.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final workerName = data['name'] ?? 'Unnamed';
                final workerId = doc.id;

                final isSelected = selectedIds.contains(workerId);

                return CheckboxListTile(
                  title: Text(workerName),
                  value: isSelected,
                  onChanged: (checked) {
                    final updated = [...selectedIds];
                    if (checked == true) {
                      updated.add(workerId);
                    } else {
                      updated.remove(workerId);
                    }
                    onChanged(updated);
                  },
                );
              }).toList(),
        );
      },
    );
  }
}
