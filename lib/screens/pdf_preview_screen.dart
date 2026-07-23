import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String title;
  final String filename;
  final Future Function() buildPdf;
  final String? docFilename;
  final Future Function()? buildDoc;
  final Future Function()? onFinalSave;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.filename,
    required this.buildPdf,
    this.docFilename,
    this.buildDoc,
    this.onFinalSave,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  static const Duration _previewTimeout = Duration(seconds: 45);

  late Future<Uint8List> _previewFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _previewFuture = _buildPdfOnce();
  }

  Future<Uint8List> _normaliseBytes(dynamic value, String label) async {
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    throw StateError('$label did not return PDF/document bytes.');
  }

  Future<Uint8List> _buildPdfOnce() async {
    final result = await widget.buildPdf().timeout(
          _previewTimeout,
          onTimeout: () => throw TimeoutException(
            'PDF generation exceeded ${_previewTimeout.inSeconds} seconds.',
          ),
        );
    return _normaliseBytes(result, 'PDF builder');
  }

  void _retryPreview() {
    setState(() {
      _previewFuture = _buildPdfOnce();
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('কাজটি সম্পন্ন হয়নি: ${_friendlyError(error)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object? error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isEmpty) return 'অজানা ত্রুটি';
    return text.length > 220 ? '${text.substring(0, 220)}…' : text;
  }

  Future<void> _exportPdf() => _runBusy(() async {
        if (widget.onFinalSave != null) await widget.onFinalSave!();
        final bytes = await _previewFuture;
        await Printing.sharePdf(bytes: bytes, filename: widget.filename);
      });

  Future<void> _exportDoc() => _runBusy(() async {
        final docBuilder = widget.buildDoc;
        if (docBuilder == null) return;
        if (widget.onFinalSave != null) await widget.onFinalSave!();
        final result = await docBuilder().timeout(_previewTimeout);
        final bytes = await _normaliseBytes(result, 'Document builder');
        final dir = await getTemporaryDirectory();
        final safeName = widget.docFilename ??
            widget.filename.replaceAll(
              RegExp(r'\.pdf$', caseSensitive: false),
              '.doc',
            );
        final file = File('${dir.path}/$safeName');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles([XFile(file.path)], text: widget.title);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('সম্পাদনা'),
                  onPressed: _busy ? null : () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: const Text('পিডিএফ'),
                  onPressed: _busy ? null : _exportPdf,
                ),
              ),
              if (widget.buildDoc != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.description),
                    label: const Text('ডক'),
                    onPressed: _busy ? null : _exportDoc,
                  ),
                ),
              ],
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
              'প্রিভিউ দেখে নাম, তারিখ, ধারা, লেখা, পৃষ্ঠা বিভাজন ও সরকারি বিন্যাস ঠিক আছে কি না যাচাই করুন। ভুল থাকলে “সম্পাদনা” চাপুন। ঠিক থাকলে পিডিএফ বা ডক এক্সপোর্ট করুন।',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: FutureBuilder<Uint8List>(
              future: _previewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text(
                          'সিডির পৃষ্ঠা প্রস্তুত হচ্ছে…',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 46),
                              const SizedBox(height: 12),
                              const Text(
                                'সিডি প্রিভিউ তৈরি করা যায়নি',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _friendlyError(snapshot.error),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _retryPreview,
                                icon: const Icon(Icons.refresh),
                                label: const Text('আবার চেষ্টা করুন'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final bytes = snapshot.data!;
                return PdfPreview(
                  build: (_) async => bytes,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: false,
                  pdfFileName: widget.filename,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
