import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

class QuotePdfViewPage extends StatefulWidget {
  final List<int> pdfBytes;

  const QuotePdfViewPage({super.key, required this.pdfBytes});

  @override
  State<QuotePdfViewPage> createState() => _QuotePdfViewPageState();
}

class _QuotePdfViewPageState extends State<QuotePdfViewPage> {
  String? _tempFilePath;
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/quote_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(widget.pdfBytes);
    _tempFilePath = file.path;

    _pdfController = PdfController(
      document: PdfDocument.openFile(_tempFilePath!),
    );

    setState(() {}); // To rebuild once controller is ready
  }

  Future<void> _sharePdf() async {
    if (_tempFilePath != null && await File(_tempFilePath!).exists()) {
      await Share.shareXFiles(
        [XFile(_tempFilePath!)],
        text: 'Here is your quote PDF',
        subject: 'Estimate from ADP Group Inc.',
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF file not found.')));
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimate PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body:
          _pdfController == null
              ? const Center(child: CircularProgressIndicator())
              : PdfView(
                controller: _pdfController!,
                scrollDirection: Axis.vertical,
              ),
    );
  }
}
