import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final String filename;
  final Future<Uint8List> Function() buildPdf;
  final Future<void> Function()? onFinalSave;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.filename,
    required this.buildPdf,
    this.onFinalSave,
  });

  Future<void> _export(BuildContext context) async {
    if (onFinalSave != null) await onFinalSave!();
    final bytes = await buildPdf();
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Back to Edit'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  onPressed: () => _export(context),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            color: Colors.amber.shade100,
            child: const Text(
              'Preview দেখে নাম, তারিখ, section, লেখা, page break ও official format ঠিক আছে কিনা verify করুন। ভুল থাকলে Back to Edit চাপুন।',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (_) => buildPdf(),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: false,
              pdfFileName: filename,
            ),
          ),
        ],
      ),
    );
  }
}
