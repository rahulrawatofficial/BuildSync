import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuoteFormPage extends StatefulWidget {
  final String companyId;
  final String projectId;
  final String? quoteId;
  final Map<String, dynamic>? quoteData;

  const QuoteFormPage({
    super.key,
    required this.companyId,
    required this.projectId,
    this.quoteId,
    this.quoteData,
  });

  @override
  State<QuoteFormPage> createState() => _QuoteFormPageState();
}

class _QuoteFormPageState extends State<QuoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.quoteData != null) {
      final data = widget.quoteData!;
      _titleController.text = data['title'] ?? '';
      _notesController.text = data['notes'] ?? '';
      _addressController.text = data['address'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _startDate = (data['startDate'] as Timestamp?)?.toDate();
      _endDate = (data['endDate'] as Timestamp?)?.toDate();
      _items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    } else {
      _items = [{}];
    }
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var item in _items) {
      final qty = item['quantity'] ?? 1;
      final rate = item['rate'] ?? 0.0;
      item['amount'] = qty * rate;
      total += item['amount'];
    }
    return total;
  }

  void _saveQuote() async {
    if (!_formKey.currentState!.validate()) return;

    final quote = {
      'title': _titleController.text,
      'notes': _notesController.text,
      'address': _addressController.text,
      'phone': _phoneController.text,
      'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
      'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
      'items': _items,
      'amount': _calculateTotalAmount(),
      'date': FieldValue.serverTimestamp(),
    };

    final quoteRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('projects')
        .doc(widget.projectId)
        .collection('quotes');

    if (widget.quoteId != null) {
      await quoteRef.doc(widget.quoteId).update(quote);
    } else {
      await quoteRef.add(quote);
    }

    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initial =
        isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _items.removeAt(index));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item['name'],
              decoration: const InputDecoration(labelText: 'Item Name'),
              onChanged: (val) => item['name'] = val,
            ),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 2,
              initialValue: item['description'],
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (val) => item['description'] = val,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item['quantity']?.toString(),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      item['quantity'] = int.tryParse(val) ?? 1;
                      item['amount'] = (item['rate'] ?? 0.0) * item['quantity'];
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: item['rate']?.toString(),
                    decoration: const InputDecoration(labelText: 'Rate'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      item['rate'] = double.tryParse(val) ?? 0.0;
                      item['amount'] = (item['rate']) * (item['quantity'] ?? 1);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Amount: \$${(item['amount'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quoteId != null ? 'Edit Quote' : 'Create Quote'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Client Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.toLocal()}'.split(' ')[0]
                              : 'Select',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.toLocal()}'.split(' ')[0]
                              : 'Select',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Quote Items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...List.generate(_items.length, _buildItemCard),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _items.add({})),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: \$${_calculateTotalAmount().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                onPressed: _saveQuote,
                label: const Text('Save Quote'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
