import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_theme.dart';
import '../services/ocr_engine_stub.dart'
    if (dart.library.io) '../services/ocr_engine_mobile.dart';

class OcrScannerScreen extends StatefulWidget {
  final ValueChanged<String>? onTextConfirmed;

  const OcrScannerScreen({
    super.key,
    this.onTextConfirmed,
  });

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final InvestigoOcrEngine _engine = InvestigoOcrEngine();
  final TextEditingController _resultController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imagePath;
  bool _busy = false;
  String _status = 'ক্যামেরা দিয়ে নথির ছবি তুলুন অথবা গ্যালারি থেকে নিন।';

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 92,
        requestFullMetadata: false,
      );
      if (image == null) return;
      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imagePath = image.path;
        _resultController.clear();
        _status = 'ছবি নেওয়া হয়েছে। এখন “OCR চালান” চাপুন।';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'ছবি নেওয়া যায়নি: $error');
    }
  }

  Future<void> _runOcr() async {
    final String? path = _imagePath;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('প্রথমে একটি ছবি নির্বাচন করুন')),
      );
      return;
    }
    if (!_engine.isSupported) {
      setState(() => _status = _engine.unsupportedMessage);
      return;
    }

    setState(() {
      _busy = true;
      _status = 'OCR চলছে...';
    });
    try {
      final String text = await _engine.recognize(path);
      if (!mounted) return;
      setState(() {
        _resultController.text = text;
        _status = text.isEmpty
            ? 'কোনো স্পষ্ট লেখা পাওয়া যায়নি। পরিষ্কার ছবি দিয়ে আবার চেষ্টা করুন।'
            : 'OCR সম্পন্ন। ব্যবহার করার আগে লেখাটি যাচাই ও সংশোধন করুন।';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'OCR করা যায়নি: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirmText() {
    final String text = _resultController.text.trim();
    if (text.isEmpty) return;
    final ValueChanged<String>? callback = widget.onTextConfirmed;
    if (callback != null) {
      callback(text);
      Navigator.of(context).pop();
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('যাচাইকৃত লেখা clipboard-এ কপি হয়েছে')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('OCR Scanner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'নথির ছবি থেকে লেখা সংগ্রহ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'বর্তমান local engine printed English/Latin text-এর জন্য। '
                    'বাংলা OCR-এর জন্য আলাদা Bengali model/backend প্রয়োজন। '
                    'OCR result কখনোই স্বয়ংক্রিয়ভাবে যাচাইকৃত প্রমাণ হিসেবে '
                    'ধরা হবে না—IO-কে দেখে সংশোধন ও নিশ্চিত করতে হবে।',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.document_scanner_rounded),
                  label: const Text('ক্যামেরা'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('গ্যালারি'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_imageBytes != null)
            Card(
              clipBehavior: Clip.antiAlias,
              child: Image.memory(
                _imageBytes!,
                height: 260,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy || _imagePath == null ? null : _runOcr,
            icon: const Icon(Icons.text_snippet_rounded),
            label: Text(_busy ? 'OCR চলছে...' : 'OCR চালান'),
          ),
          const SizedBox(height: 10),
          Text(
            _status,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resultController,
            minLines: 8,
            maxLines: 18,
            decoration: const InputDecoration(
              labelText: 'OCR Result — যাচাই করে প্রয়োজনমতো সংশোধন করুন',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                _resultController.text.trim().isEmpty ? null : _confirmText,
            icon: const Icon(Icons.verified_rounded),
            label: Text(
              widget.onTextConfirmed == null
                  ? 'যাচাই করে লেখা Copy করুন'
                  : 'যাচাই করে এই লেখা ব্যবহার করুন',
            ),
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
