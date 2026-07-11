import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../widgets/form_helpers.dart';

class CdEditorScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;
  final CdEntry cd;

  const CdEditorScreen({super.key, required this.profile, required this.caseFile, required this.cd});

  @override
  State<CdEditorScreen> createState() => _CdEditorScreenState();
}

class _CdEditorScreenState extends State<CdEditorScreen> {
  final LocalStoreService _store = LocalStoreService();
  late CdEntry _cd;
  late final TextEditingController cdDate;
  late final TextEditingController startTime;
  late final TextEditingController endTime;
  late final TextEditingController place;
  late final TextEditingController body;

  @override
  void initState() {
    super.initState();
    _cd = widget.cd;
    cdDate = TextEditingController(text: _cd.cdDate);
    startTime = TextEditingController(text: _cd.startTime);
    endTime = TextEditingController(text: _cd.endTime);
    place = TextEditingController(text: _cd.placeOfEntry);
    body = TextEditingController(text: _cd.body);
  }

  @override
  void dispose() {
    cdDate.dispose();
    startTime.dispose();
    endTime.dispose();
    place.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> _save({bool finalSave = false}) async {
    final updated = _cd.copyWith(
      cdDate: cdDate.text.trim(),
      startTime: startTime.text.trim(),
      endTime: endTime.text.trim(),
      placeOfEntry: place.text.trim(),
      body: body.text.trim(),
      isFinal: finalSave ? true : _cd.isFinal,
    );
    await _store.saveCd(updated);
    if (!mounted) return;
    setState(() => _cd = updated);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(finalSave ? 'CD final saved' : 'CD draft saved')));
  }

  Future<void> _finalSave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Final Save CD?'),
        content: const Text('Final save করলে CD locked হিসেবে mark হবে। পরে edit করা যাবে, কিন্তু warning দেখাবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Final Save')),
        ],
      ),
    );
    if (ok == true) await _save(finalSave: true);
  }

  Future<void> _exportPdf() async {
    await _save(finalSave: false);
    if (!mounted) return;
    await PdfService().shareCaseDiaryPdf(officer: widget.profile, caseFile: widget.caseFile, cd: _cd.copyWith(
      cdDate: cdDate.text.trim(),
      startTime: startTime.text.trim(),
      endTime: endTime.text.trim(),
      placeOfEntry: place.text.trim(),
      body: body.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CD-${_cd.cdNumber} Editor')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save), label: const Text('Draft'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _finalSave, icon: const Icon(Icons.lock), label: const Text('Final'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_cd.isFinal)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('This CD is final saved. Edit carefully if required.', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          FormHelpers.textField(controller: cdDate, label: 'CD Date'),
          Row(
            children: [
              Expanded(child: FormHelpers.textField(controller: startTime, label: 'Start Time')),
              const SizedBox(width: 8),
              Expanded(child: FormHelpers.textField(controller: endTime, label: 'End Time')),
            ],
          ),
          FormHelpers.textField(controller: place, label: 'Place of Entry'),
          Text('CD Body', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: body,
            maxLines: 22,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              labelText: 'Generated CD draft — edit as required',
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
