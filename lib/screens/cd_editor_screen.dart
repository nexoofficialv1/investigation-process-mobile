import 'package:flutter/material.dart';

import '../core/app_language_controller.dart';
import '../core/document_language.dart';
import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../services/doc_export_service.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../services/protected_translation_service.dart';
import '../widgets/form_helpers.dart';
import 'pdf_preview_screen.dart';

class CdEditorScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;
  final CdEntry cd;

  const CdEditorScreen({
    super.key,
    required this.profile,
    required this.caseFile,
    required this.cd,
  });

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
  late final List<_CdLineControllers> _lineControllers;
  bool _translating = false;

  String _ui(String bangla, String english) =>
      AppLanguageController.instance.text(bangla, english);

  DocumentLanguage get _documentLanguage =>
      DocumentLanguage.fromCode(_cd.languageCode);

  @override
  void initState() {
    super.initState();
    _cd = widget.cd;
    cdDate = TextEditingController(text: _cd.cdDate);
    startTime = TextEditingController(text: _cd.startTime);
    endTime = TextEditingController(text: _cd.endTime);
    place = TextEditingController(text: _cd.placeOfEntry);

    final initialLines = _cd.tableLines.isNotEmpty
        ? _cd.tableLines.cast<CdTableLine>()
        : <CdTableLine>[
            CdTableLine(
              noAndHour: '${_cd.isEnglish ? '1' : '১'}\n${_cd.startTime}',
              placeOfEntry: _cd.placeOfEntry,
              synopsis: _cd.cdNumber == 1
                  ? (_cd.isEnglish
                      ? 'Receipt of FIR copy\n+\nBrief facts'
                      : 'এফআইআরের অনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা')
                  : (_cd.isEnglish
                      ? 'Further investigation'
                      : 'পরবর্তী তদন্ত'),
              proceedings: _cd.body,
            ),
          ];
    _lineControllers = initialLines.map(_CdLineControllers.fromLine).toList();
  }

  @override
  void dispose() {
    cdDate.dispose();
    startTime.dispose();
    endTime.dispose();
    place.dispose();
    for (final controller in _lineControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<CdTableLine> _currentLines() => _lineControllers
      .map(
        (controller) => CdTableLine(
          noAndHour: controller.noAndHour.text.trim(),
          placeOfEntry: controller.place.text.trim(),
          synopsis: controller.synopsis.text.trim(),
          proceedings: controller.proceedings.text.trim(),
        ),
      )
      .where(
        (line) =>
            line.noAndHour.isNotEmpty ||
            line.placeOfEntry.isNotEmpty ||
            line.synopsis.isNotEmpty ||
            line.proceedings.isNotEmpty,
      )
      .toList();

  String _combinedBody(List<CdTableLine> lines) => lines
      .map((line) => line.proceedings)
      .where((text) => text.trim().isNotEmpty)
      .join('\n\n');

  Future<void> _save({bool finalSave = false}) async {
    final lines = _currentLines();
    final updated = _cd.copyWith(
      cdDate: cdDate.text.trim(),
      startTime: startTime.text.trim(),
      endTime: endTime.text.trim(),
      placeOfEntry: place.text.trim(),
      body: _combinedBody(lines),
      tableLines: lines,
      isFinal: finalSave ? true : _cd.isFinal,
    );
    await _store.saveCd(updated);
    if (!mounted) return;
    setState(() => _cd = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          finalSave
              ? _ui(
                  'সিডি চূড়ান্তভাবে সংরক্ষিত হয়েছে।',
                  'The case diary has been saved as final.',
                )
              : _ui(
                  'সিডির খসড়া সংরক্ষিত হয়েছে।',
                  'The case diary draft has been saved.',
                ),
        ),
      ),
    );
  }

  Future<void> _finalSave() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _ui(
            'সিডি চূড়ান্তভাবে সংরক্ষণ করবেন?',
            'Save this case diary as final?',
          ),
        ),
        content: Text(
          _ui(
            'চূড়ান্তভাবে সংরক্ষণ করলে সিডি লক হিসেবে চিহ্নিত হবে। পরে সম্পাদনা করা যাবে, তবে সতর্কবার্তা দেখাবে।',
            'The diary will be marked as final. It may still be edited later, but a warning will be shown.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_ui('বাতিল', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_ui('চূড়ান্ত সংরক্ষণ', 'Save final')),
          ),
        ],
      ),
    );
    if (approved == true) await _save(finalSave: true);
  }

  CdEntry _currentCd() {
    final lines = _currentLines();
    return _cd.copyWith(
      cdDate: cdDate.text.trim(),
      startTime: startTime.text.trim(),
      endTime: endTime.text.trim(),
      placeOfEntry: place.text.trim(),
      body: _combinedBody(lines),
      tableLines: lines,
    );
  }

  Future<void> _previewPdf() async {
    await _save(finalSave: false);
    if (!mounted) return;
    final cdForPreview = _currentCd();
    final baseName =
        'CD_${widget.caseFile.psCaseNo.replaceAll('/', '_')}_${_cd.cdNumber}';
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewScreen(
          title: _ui(
            'সিডি-${_cd.cdNumber} প্রিভিউ',
            'CD-${_cd.cdNumber} preview',
          ),
          filename: '$baseName.pdf',
          docFilename: '$baseName.doc',
          buildPdf: () => PdfService().buildCaseDiaryPdf(
            officer: widget.profile,
            caseFile: widget.caseFile,
            cd: cdForPreview,
          ),
          buildDoc: () => DocExportService().buildCaseDiaryDoc(
            officer: widget.profile,
            caseFile: widget.caseFile,
            cd: cdForPreview,
          ),
          onFinalSave: () => _save(finalSave: true),
        ),
      ),
    );
  }


  Future<void> _changeDocumentLanguage(
    DocumentLanguage language,
  ) async {
    if (language.code == _cd.languageCode || _translating) return;
    setState(() {
      _cd = _cd.copyWith(languageCode: language.code);
    });
    await _translateAll();
    await _save(finalSave: false);
  }

  Future<void> _translateAll() async {
    setState(() => _translating = true);
    try {
      final protectedTerms = <String>[
        widget.profile.name,
        widget.profile.policeStation,
        widget.profile.district,
        widget.caseFile.psCaseNo,
        widget.caseFile.sections,
        widget.caseFile.complainantName,
        widget.caseFile.victimName,
        widget.caseFile.accusedName,
        widget.caseFile.placeOfOccurrence,
      ];
      for (final controller in _lineControllers) {
        controller.synopsis.text =
            await ProtectedTranslationService.instance.translate(
          controller.synopsis.text,
          target: _documentLanguage,
          protectedTerms: protectedTerms,
        );
        controller.proceedings.text =
            await ProtectedTranslationService.instance.translate(
          controller.proceedings.text,
          target: _documentLanguage,
          protectedTerms: protectedTerms,
        );
      }
      place.text = await ProtectedTranslationService.instance.translate(
        place.text,
        target: _documentLanguage,
        protectedTerms: protectedTerms,
      );
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  void _addEntry() {
    setState(() {
      final next = _lineControllers.length + 1;
      _lineControllers.add(
        _CdLineControllers(
          noAndHour: TextEditingController(
            text: '${_cd.isEnglish ? next : _banglaNumber(next)}\n${startTime.text.trim()}',
          ),
          place: TextEditingController(text: place.text.trim()),
          synopsis: TextEditingController(
            text: _cd.isEnglish ? 'New entry' : 'নতুন এন্ট্রি',
          ),
          proceedings: TextEditingController(),
        ),
      );
    });
  }

  String _banglaNumber(int number) {
    const digits = <String>['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number
        .toString()
        .split('')
        .map((digit) => digits[int.parse(digit)])
        .join();
  }

  void _deleteEntry(int index) {
    if (_lineControllers.length <= 1) return;
    setState(() {
      final removed = _lineControllers.removeAt(index);
      removed.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguageController.instance,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            _ui(
              'সিডি-${_cd.cdNumber} সম্পাদনা',
              'Edit CD-${_cd.cdNumber}',
            ),
          ),
          actions: <Widget>[
            IconButton(
              tooltip: _ui(
                'নির্বাচিত নথির ভাষায় রূপান্তর',
                'Convert to selected document language',
              ),
              onPressed: _translating ? null : _translateAll,
              icon: _translating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.translate),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _save(),
                    icon: const Icon(Icons.save),
                    label: Text(_ui('খসড়া', 'Draft')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _finalSave,
                    icon: const Icon(Icons.lock),
                    label: Text(_ui('চূড়ান্ত', 'Final')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _previewPdf,
                    icon: const Icon(Icons.preview),
                    label: Text(_ui('প্রিভিউ', 'Preview')),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (_cd.isFinal)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _ui(
                      'এই সিডি চূড়ান্তভাবে সংরক্ষিত। প্রয়োজন হলে সতর্কতার সঙ্গে সম্পাদনা করুন।',
                      'This case diary is marked final. Edit it carefully if required.',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _ui(
                              'সিডির শিরোনাম অংশের বিবরণ',
                              'Case diary header details',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DropdownButton<DocumentLanguage>(
                      value: _documentLanguage,
                      underline: const SizedBox.shrink(),
                      items: DocumentLanguage.values
                          .map(
                            (language) => DropdownMenuItem<DocumentLanguage>(
                              value: language,
                              child: Text(language.displayLabel),
                            ),
                          )
                          .toList(),
                      onChanged: _translating
                          ? null
                          : (language) {
                              if (language != null) {
                                _changeDocumentLanguage(language);
                              }
                            },
                    ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FormHelpers.dateField(
                      context: context,
                      controller: cdDate,
                      label: _ui('সিডির তারিখ', 'CD date'),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FormHelpers.timeField(
                            context: context,
                            controller: startTime,
                            label: _ui('শুরুর সময়', 'Start time'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FormHelpers.timeField(
                            context: context,
                            controller: endTime,
                            label: _ui('শেষের সময়', 'End time'),
                          ),
                        ),
                      ],
                    ),
                    FormHelpers.textField(
                      controller: place,
                      label: _ui(
                        'ডিফল্ট এন্ট্রির স্থান',
                        'Default place of entry',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _ui(
                'এন্ট্রিভিত্তিক সরকারি সিডি কলাম',
                'Official entry-wise case diary columns',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _ui(
                'প্রতিটি এন্ট্রি পর্যালোচনা করুন। অ্যাপ কখনো অনুপস্থিত সময়, নাম বা আলামতের বিবরণ নিজে থেকে বানাবে না।',
                'Review every entry. The app never invents a missing time, name or evidence description.',
              ),
            ),
            const SizedBox(height: 10),
            ...List<Widget>.generate(
              _lineControllers.length,
              (index) => _entryCard(index, _lineControllers[index]),
            ),
            OutlinedButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add),
              label: Text(
                _ui('নতুন এন্ট্রি লাইন যোগ করুন', 'Add a new entry line'),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(int index, _CdLineControllers controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _ui('এন্ট্রি ${index + 1}', 'Entry ${index + 1}'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteEntry(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            FormHelpers.textField(
              controller: controller.noAndHour,
              label: _ui('এন্ট্রি নং ও সময়', 'Entry no. and time'),
              maxLines: 2,
            ),
            FormHelpers.textField(
              controller: controller.place,
              label: _ui('এন্ট্রির স্থান', 'Place of entry'),
              maxLines: 2,
            ),
            FormHelpers.textField(
              controller: controller.synopsis,
              label: _ui('এন্ট্রির সারাংশ', 'Synopsis of entry'),
              maxLines: 3,
            ),
            FormHelpers.textField(
              controller: controller.proceedings,
              label: _ui(
                'কার্যবিবরণী/মূল লেখা',
                'Proceedings/main narrative',
              ),
              maxLines: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _CdLineControllers {
  final TextEditingController noAndHour;
  final TextEditingController place;
  final TextEditingController synopsis;
  final TextEditingController proceedings;

  _CdLineControllers({
    required this.noAndHour,
    required this.place,
    required this.synopsis,
    required this.proceedings,
  });

  factory _CdLineControllers.fromLine(CdTableLine line) =>
      _CdLineControllers(
        noAndHour: TextEditingController(text: line.noAndHour),
        place: TextEditingController(text: line.placeOfEntry),
        synopsis: TextEditingController(text: line.synopsis),
        proceedings: TextEditingController(text: line.proceedings),
      );

  void dispose() {
    noAndHour.dispose();
    place.dispose();
    synopsis.dispose();
    proceedings.dispose();
  }
}
