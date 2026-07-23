import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/document_language.dart';
import '../models/case_file.dart';
import '../models/guided_daily_entry.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/guided_daily_entry_store.dart';
import '../services/guided_question_engine.dart';
import '../services/local_store_service.dart';
import '../services/protected_translation_service.dart';
import 'sketch_map_screen.dart';
import 'daily_cd_mode_screen.dart';

class GuidedDailyEntryScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;
  final DailyEntrySource source;
  final String? initialDate;

  final bool firstCdMode;
  const GuidedDailyEntryScreen({
    super.key,
    required this.profile,
    required this.caseFile,
    required this.source,
    this.initialDate,
    this.firstCdMode = false,
  });

  @override
  State<GuidedDailyEntryScreen> createState() =>
      _GuidedDailyEntryScreenState();
}

class _GuidedDailyEntryScreenState extends State<GuidedDailyEntryScreen> {
  final GuidedDailyEntryStore _entryStore = GuidedDailyEntryStore();
  final GuidedQuestionEngine _engine = GuidedQuestionEngine();
  final LocalStoreService _localStore = LocalStoreService();
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _narration = TextEditingController();
  late final TextEditingController _date;

  GuidedDailyEntry? _existing;
  List<GuidedAction> _actions = <GuidedAction>[];
  String _inputLanguageCode = 'bn';
  DocumentLanguage _documentLanguage = DocumentLanguage.bangla;
  bool _speechReady = false;
  bool _listening = false;
  bool _busy = false;

  bool get _isEvidence => widget.source == DailyEntrySource.evidence;

  @override
  void initState() {
    super.initState();
    _date = TextEditingController(
      text: widget.initialDate ??
          DateTime.now().toIso8601String().split('T').first,
    );
    _initializeSpeech();
    _loadExisting();
    if (widget.firstCdMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFirstCdGuide();
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _narration.dispose();
    _date.dispose();
    super.dispose();
  }


  Future<void> _showFirstCdGuide() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('First Case Diary-এর প্রয়োজনীয় তথ্য দিন'),
        content: const Text(
          'নিজের ভাষায় বলুন বা লিখুন—কখন তদন্তভার গ্রহণ করেছেন, কখন PS থেকে '
          'রওনা হয়েছেন, কখন PO-তে পৌঁছেছেন, PO-এর বিস্তারিত কী, সেখানে কী '
          'দেখেছেন, Sketch Map প্রস্তুত করবেন কি না, সাক্ষীর নাম ও বয়ান, '
          'এবং জব্দ/চিকিৎসা/Evidence সংক্রান্ত কাজ।',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('তথ্য দেওয়া শুরু করুন'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _listening = status == 'listening');
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    setState(() => _speechReady = available);
  }

  Future<void> _loadExisting() async {
    final existing = await _entryStore.loadOne(
      widget.caseFile.id,
      _date.text.trim(),
      widget.source,
    );
    if (!mounted) return;
    setState(() {
      _existing = existing;
      if (existing == null) {
        _narration.clear();
        _actions = <GuidedAction>[];
        return;
      }
      _narration.text = existing.narration;
      _inputLanguageCode = existing.inputLanguageCode;
      _documentLanguage =
          DocumentLanguage.fromCode(existing.documentLanguageCode);
      _actions = List<GuidedAction>.from(existing.actions);
    });
  }

  Future<void> _toggleListening() async {
    if (!_speechReady) {
      await _initializeSpeech();
    }
    if (!_speechReady || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input পাওয়া যাচ্ছে না। লিখে Entry দিন।')),
      );
      return;
    }
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    await _speech.listen(
      localeId: _inputLanguageCode == 'en' ? 'en_IN' : 'bn_IN',
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _narration.text = result.recognizedWords;
          _narration.selection = TextSelection.collapsed(
            offset: _narration.text.length,
          );
        });
      },
    );
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _date.text = picked.toIso8601String().split('T').first;
    await _loadExisting();
  }

  Future<void> _analyseAndQuestion() async {
    final text = _narration.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আগে নিজের ভাষায় দিনের কাজটি বলুন বা লিখুন।')),
      );
      return;
    }
    setState(() {
      _actions = _engine.analyse(text, widget.source);
    });
    await _handleSketchMapAfterPoVisit();
    await _runQuestionWizard();
  }

  Future<void> _handleSketchMapAfterPoVisit() async {
    final poIndex = _actions.indexWhere((item) => item.type == 'po_visit');
    if (poIndex < 0) return;
    final poAction = _actions[poIndex];
    if ((poAction.answers['sketch_map_decision'] ?? '').isNotEmpty) return;

    final decision = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Rough Sketch Map'),
        content: const Text(
          'আপনি ঘটনাস্থলে গিয়েছেন। এখন কি সূচিসহ Rough Sketch Map প্রস্তুত করবেন?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'later'),
            child: const Text('পরে করব'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'no'),
            child: const Text('না'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'yes'),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
    if (!mounted || decision == null) return;
    final answers = Map<String, String>.from(poAction.answers)
      ..['sketch_map_decision'] = decision;
    setState(() => _actions[poIndex] = poAction.copyWith(answers: answers));

    if (decision != 'yes') return;
    final before = await _localStore.loadSketchMap(widget.caseFile.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SketchMapScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
        ),
      ),
    );
    final after = await _localStore.loadSketchMap(widget.caseFile.id);
    if (!mounted) return;
    if (after == null ||
        (before != null && !after.updatedAt.isAfter(before.updatedAt))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sketch Map নতুন করে Save করা হয়নি; CD entry যোগ করা হয়নি।'),
        ),
      );
      return;
    }

    final savedMap = after;

    final mention = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('সিডিতে Mention করবেন?'),
        content: const Text(
          'Sketch Map সংরক্ষিত হয়েছে। এটি আজকের Case Diary-তে mention করা হবে কি?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
    if (mention != true || !mounted) return;
    final alreadyAdded = _actions.any((item) => item.type == 'sketch_map');
    if (!alreadyAdded) {
      setState(() {
        _actions.add(GuidedAction(
          id: 'guided_sketch_${DateTime.now().microsecondsSinceEpoch}',
          type: 'sketch_map',
          time: poAction.time,
          place: poAction.place.isEmpty
              ? widget.caseFile.placeOfOccurrence
              : poAction.place,
          details: 'সূচিসহ ঘটনাস্থলের Rough Sketch Map প্রস্তুত ও সংরক্ষণ করা হয়েছে।',
          sequence: poAction.sequence + 1,
          answers: <String, String>{
            'sketch_reference': savedMap.title,
            'sketch_map_id': savedMap.id,
          },
        ));
      });
    }
  }

  Future<void> _runQuestionWizard() async {
    while (mounted) {
      final question = _engine.nextQuestion(_actions, widget.source);
      if (question == null) break;
      final answer = await _askQuestion(question);
      if (!mounted || answer == null) break;
      final index = _actions.indexWhere((item) => item.id == question.actionId);
      if (index < 0) continue;
      setState(() {
        _actions[index] = _engine.applyAnswer(
          _actions[index],
          question,
          answer,
        );
      });
    }
  }

  Future<String?> _askQuestion(GuidedQuestion question) async {
    if (question.options.isNotEmpty) {
      return showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(question.prompt(_inputLanguageCode)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: question.options
                .map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.pop(context, option),
                        child: Text(option),
                      ),
                    ))
                .toList(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('এখন বন্ধ করুন'),
            ),
          ],
        ),
      );
    }

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(question.prompt(_inputLanguageCode)),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'উত্তর লিখুন',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('এখন বন্ধ করুন'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty && question.required) return;
              Navigator.pop(
                dialogContext,
                value.isEmpty ? 'প্রযোজ্য নয়' : value,
              );
            },
            child: const Text('উত্তর দিন'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _editAction(GuidedAction action) async {
    final time = TextEditingController(text: action.time);
    final place = TextEditingController(text: action.place);
    final details = TextEditingController(text: action.details);
    var include = action.includeInCd;
    final edited = await showDialog<GuidedAction>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_engine.synopsis(action, _documentLanguage)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: time,
                  decoration: const InputDecoration(labelText: 'সময়'),
                ),
                TextField(
                  controller: place,
                  decoration: const InputDecoration(labelText: 'স্থান'),
                ),
                TextField(
                  controller: details,
                  minLines: 3,
                  maxLines: 7,
                  decoration: const InputDecoration(labelText: 'বিবরণ'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Case Diary-তে নেবেন'),
                  value: include,
                  onChanged: (value) => setDialogState(() => include = value),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                action.copyWith(
                  time: time.text.trim(),
                  place: place.text.trim(),
                  details: details.text.trim(),
                  includeInCd: include,
                ),
              ),
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
    time.dispose();
    place.dispose();
    details.dispose();
    if (edited == null || !mounted) return;
    final index = _actions.indexWhere((item) => item.id == action.id);
    if (index >= 0) setState(() => _actions[index] = edited);
  }

  Future<void> _saveEntry({bool createCdAfterSave = false}) async {
    if (_narration.text.trim().isEmpty || _actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Narration Analyse করে প্রশ্নগুলোর উত্তর দিন।')),
      );
      return;
    }
    final pendingQuestion = _engine.nextQuestion(_actions, widget.source);
    if (pendingQuestion != null) {
      final continueSave = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('কিছু তথ্য এখনও বাকি'),
          content: Text(
            'পরবর্তী প্রশ্ন: ${pendingQuestion.prompt(_inputLanguageCode)}\n\nঅসম্পূর্ণ অবস্থায়ও Draft হিসেবে সংরক্ষণ করবেন?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('প্রশ্নে ফিরুন'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Draft Save'),
            ),
          ],
        ),
      );
      if (continueSave != true) {
        await _runQuestionWizard();
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final entry = _existing == null
          ? GuidedDailyEntry.create(
              caseId: widget.caseFile.id,
              actionDate: _date.text.trim(),
              source: widget.source,
              narration: _narration.text.trim(),
              inputLanguageCode: _inputLanguageCode,
              documentLanguageCode: _documentLanguage.code,
              actions: _actions,
            )
          : _existing!.copyWith(
              actionDate: _date.text.trim(),
              narration: _narration.text.trim(),
              inputLanguageCode: _inputLanguageCode,
              documentLanguageCode: _documentLanguage.code,
              actions: _actions,
            );
      await _entryStore.save(entry);

      // Interoperability with the existing pending-CD workflow.
      for (final action in _actions.where((item) => item.includeInCd)) {
        String facts = _engine.factSummary(action);
        try {
          facts = await ProtectedTranslationService.instance.translate(
            facts,
            target: _documentLanguage,
            protectedTerms: <String>[
              widget.caseFile.psCaseNo,
              widget.caseFile.complainantName,
              widget.caseFile.accusedName,
              widget.caseFile.placeOfOccurrence,
              action.place,
            ],
          );
        } catch (_) {
          // Keep original factual wording rather than inventing/losing data.
        }
        final paragraph = _engine.officialProceeding(
          action: action,
          language: _documentLanguage,
          translatedFacts: facts,
        );
        final isSketchMap = action.type == 'sketch_map';
        await _localStore.savePendingCdAction(PendingCdAction.create(
          caseId: widget.caseFile.id,
          sourceType: isSketchMap
              ? 'Sketch Map'
              : widget.source.englishLabel,
          sourceId: isSketchMap
              ? (action.answers['sketch_map_id'] ?? '${entry.id}_${action.id}')
              : '${entry.id}_${action.id}',
          title: isSketchMap
              ? 'সূচিসহ ঘটনাস্থলের খসড়া নকশা প্রস্তুত'
              : _engine.synopsis(action, _documentLanguage),
          actionDate: entry.actionDate,
          paragraph: paragraph,
        ));
      }

      if (!mounted) return;
      setState(() => _existing = entry);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '${widget.source.banglaLabel} দিনের Entry সংরক্ষিত হয়েছে।',
        ),
      ));
      if (createCdAfterSave) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DailyCdModeScreen(
              profile: widget.profile,
              caseFile: widget.caseFile,
              initialDate: _date.text.trim(),
              lockDate: true,
              autoGenerate: true,
            ),
          ),
        );
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry সংরক্ষণ করা যায়নি: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    await _saveEntry();
  }

  Future<void> _saveAndCreateCd() async {
    await _saveEntry(createCdAfterSave: true);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.firstCdMode
              ? 'First CD-এর Investigation Entry'
              : 'আজকের ${widget.source.banglaLabel} Entry',
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _saveAndCreateCd,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    widget.firstCdMode
                        ? 'Entry সংরক্ষণ করে CD-I তৈরি করুন'
                        : 'Entry সংরক্ষণ করে এই দিনের CD তৈরি করুন',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('শুধু দিনের Entry সংরক্ষণ করুন'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.caseFile.displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text('ধারা: ${widget.caseFile.sections}'),
                  if (widget.caseFile.placeOfOccurrence.trim().isNotEmpty)
                    Text('PO: ${widget.caseFile.placeOfOccurrence}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _date,
            readOnly: true,
            onTap: widget.firstCdMode ? null : _pickDate,
            decoration: InputDecoration(
              labelText: widget.firstCdMode
                  ? 'দিনের তারিখ (মামলার তারিখ অনুযায়ী নির্ধারিত)'
                  : 'দিনের তারিখ',
              suffixIcon: Icon(
                widget.firstCdMode
                    ? Icons.lock_outline
                    : Icons.calendar_month,
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _inputLanguageCode,
                  decoration: const InputDecoration(
                    labelText: 'IO যে ভাষায় বলবেন',
                    border: OutlineInputBorder(),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) =>
                      setState(() => _inputLanguageCode = value ?? 'bn'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<DocumentLanguage>(
                  value: _documentLanguage,
                  decoration: const InputDecoration(
                    labelText: 'CD-এর ভাষা',
                    border: OutlineInputBorder(),
                  ),
                  items: DocumentLanguage.values
                      .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.displayLabel),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() =>
                      _documentLanguage = value ?? DocumentLanguage.bangla),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _narration,
            minLines: 7,
            maxLines: 14,
            decoration: InputDecoration(
              labelText: _isEvidence
                  ? 'আজ কী Evidence পেয়েছেন/সংগ্রহ/জব্দ/সংরক্ষণ করেছেন—নিজের ভাষায় বলুন বা লিখুন'
                  : 'আজ তদন্তে কী কী করেছেন—নিজের ভাষায় বলুন বা লিখুন',
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _listening ? 'Voice বন্ধ করুন' : 'Voice দিয়ে বলুন',
                onPressed: _toggleListening,
                icon: Icon(_listening ? Icons.stop_circle : Icons.mic),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _analyseAndQuestion,
            icon: const Icon(Icons.psychology_alt),
            label: const Text('বিবরণ বুঝে প্রশ্ন শুরু করুন'),
          ),
          const SizedBox(height: 18),
          if (_actions.isNotEmpty) ...<Widget>[
            Text(
              'অ্যাপ যে কাজগুলো বুঝেছে',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ..._actions.map((action) => Card(
                  child: ListTile(
                    leading: Icon(
                      action.includeInCd
                          ? Icons.check_circle
                          : Icons.remove_circle_outline,
                    ),
                    title: Text(_engine.synopsis(
                      action,
                      _documentLanguage,
                    )),
                    subtitle: Text(<String>[
                      if (action.time.trim().isNotEmpty) action.time.trim(),
                      if (action.place.trim().isNotEmpty) action.place.trim(),
                      _engine.factSummary(action),
                    ].where((item) => item.isNotEmpty).join(' • ')),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _editAction(action),
                  ),
                )),
            OutlinedButton.icon(
              onPressed: _runQuestionWizard,
              icon: const Icon(Icons.question_answer),
              label: const Text('বাকি প্রশ্ন চালিয়ে যান'),
            ),
          ],
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
