import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'quote_pdf_generator.dart'; // Import your PDF generator

import 'package:flutter/services.dart' show rootBundle;

class QuoteListPage extends StatelessWidget {
  final String companyId;
  final String projectId;

  const QuoteListPage({
    super.key,
    required this.companyId,
    required this.projectId,
  });

  void _generatePdfAndNavigate(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final logoBytes = await rootBundle
        .load('assets/images/adp.png')
        .then((byteData) => byteData.buffer.asUint8List());
    final pdfBytes = await QuotePdfGenerator.generate(
      data,
      logoBytes: logoBytes,
    );
    context.push('/quote-pdf-view', extra: pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quotes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(
            '/quote-form',
            extra: {'companyId': companyId, 'projectId': projectId},
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('projects')
                .doc(projectId)
                .collection('quotes')
                .orderBy('date', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final quotes = snapshot.data!.docs;

          if (quotes.isEmpty) {
            return const Center(child: Text("No quotes yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final quote = quotes[index];
              final data = quote.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'No title';
              final amount = data['amount']?.toDouble() ?? 0;
              final date = (data['date'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Total: \$${amount.toStringAsFixed(2)}'),
                      if (date != null)
                        Text(
                          'Date: ${date.day}/${date.month}/${date.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        context.push(
                          '/quote-form',
                          extra: {
                            'companyId': companyId,
                            'projectId': projectId,
                            'quoteId': quote.id,
                            'quoteData': data,
                          },
                        );
                      } else if (value == 'pdf') {
                        _generatePdfAndNavigate(context, data);
                        // final pdfBytes = await QuotePdfGenerator.generate(data);
                        // context.push('/quote-pdf-view', extra: pdfBytes);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'pdf',
                            child: Text('Generate PDF'),
                          ),
                        ],
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
