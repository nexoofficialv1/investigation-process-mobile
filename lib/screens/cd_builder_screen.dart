import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/app_language_controller.dart';
import '../core/document_language.dart';
import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/daily_narration_record.dart';
import '../models/investigation_action.dart';
import '../models/officer_profile.dart';
import '../models/sketch_map.dart';
import '../models/statement_entry.dart';
import '../services/daily_narration_service.dart';
import '../services/local_store_service.dart';
import '../services/protected_translation_service.dart';
import '../services/unified_workflow_store.dart';
import '../services/writing_assist_service.dart';
import 'cd_editor_screen.dart';

class CdBuilderScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const CdBuilderScreen({
    super.key,
    required this.profile,
    required this.caseFile,
  });

  @override
  State<CdBuilderScreen> createState() => _CdBuilderScreenState();
}

class _CdBuilderScreenState extends State<CdBuilderScreen> {
  final LocalStoreService _store = LocalStoreService();
  final UnifiedWorkflowStore _workflowStore = UnifiedWorkflowStore();
  final DailyNarrationService _narrationService = DailyNarrationService();
  final WritingAssistService _writingAssist = WritingAssistService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _narrationController = TextEditingController();

  DocumentLanguage _documentLanguage = DocumentLanguage.bangla;
  String _inputLanguageCode = 'bn_BD';
  int? _cdNumber;
  bool _loading = true;
  bool _analysing = false;
  bool _generating = false;
  bool _isListening = false;
  List<DetectedDailyAction> _actions = <DetectedDailyAction>[];
  List<InvestigationActionEntry> _existingActions =
      <InvestigationActionEntry>[];
  List<StatementEntry> _existingStatements = <StatementEntry>[];
  SketchMapEntry? _existingSketchMap;
  final List<_WitnessDraft> _witnessDrafts = <_WitnessDraft>[];

  String _ui(String bangla, String english) {
    return AppLanguageController.instance.text(bangla, english);
  }

  String get _today => DateTime.now().toIso8601String().split('T').first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _narrationController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final number = await _store.nextCdNumber(widget.caseFile.id);
    final existingActions =
        await _store.loadInvestigationActions(widget.caseFile.id);
    final statements = await _store.loadStatements(widget.caseFile.id);
    final sketch = await _store.loadSketchMap(widget.caseFile.id);

    final todayActions = existingActions
        .where((item) => item.actionDate == _today)
        .toList();

    final restored = todayActions.asMap().entries.map((entry) {
      final item = entry.value;
      return DetectedDailyAction(
        id: item.id,
        type: item.actionType,
        time: item.actionArrivalTime.isNotEmpty
            ? item.actionArrivalTime
            : item.departureTime,
        place: item.place,
        details: item.details,
        sourceSentence: item.details,
        order: entry.key,
      );
    }).toList();

    if (restored.isEmpty) {
      restored.addAll(_legacyStartActions());
    }

    if (!mounted) return;
    setState(() {
      _cdNumber = number;
      _existingActions = existingActions;
      _existingStatements = statements;
      _existingSketchMap = sketch;
      _actions = restored;
      _loading = false;
    });
  }


  List<DetectedDailyAction> _legacyStartActions() {
    final start = widget.caseFile.investigationStart;
    final result = <DetectedDailyAction>[];

    void add(String type, bool completed, String details) {
      if (!completed) return;
      result.add(
        DetectedDailyAction(
          id: 'legacy_${type}_${result.length}',
          type: type,
          time: '',
          place: type == 'po_visit' ||
                  type == 'sketch_map' ||
                  type == 'witness_examination'
              ? widget.caseFile.placeOfOccurrence
              : '',
          details: details,
          sourceSentence: details,
          order: result.length,
          witnessCount: type == 'witness_examination' ? 1 : 0,
        ),
      );
    }

    add('po_visit', start.visitedPo, start.poDetails);
    add('sketch_map', start.sketchPrepared, start.sketchDetails);
    add('witness_examination', start.witnessExamined, start.witnessDetails);
    add('medical', start.medicalRequired, start.medicalDetails);
    add('seizure', start.seizureRequired, start.seizureDetails);
    add('evidence_collection', start.evidenceRequired, start.evidenceDetails);
    return result;
  }

  Future<void> _toggleListening(TextEditingController controller) async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        _showMessage(
          _ui(
            'ভয়েস শনাক্তকরণ চালু করা যায়নি: ${error.errorMsg}',
            'Speech recognition could not start: ${error.errorMsg}',
          ),
        );
      },
    );

    if (!available) {
      _showMessage(
        _ui(
          'এই ডিভাইস/ব্রাউজারে ভয়েস শনাক্তকরণ পাওয়া যায়নি। লিখে দিন।',
          'Speech recognition is unavailable on this device/browser. Please type instead.',
        ),
      );
      return;
    }

    final base = controller.text.trim();
    setState(() => _isListening = true);

    await _speech.listen(
      localeId: _inputLanguageCode,
      onResult: (result) {
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;
        controller.text = base.isEmpty ? recognized : '$base $recognized';
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _analyseNarration() async {
    final narration = _narrationController.text.trim();
    if (narration.isEmpty) {
      _showMessage(
        _ui(
          'আজকের তদন্তের ঘটনা আগে বলুন বা লিখুন।',
          'Please narrate or type today’s investigation first.',
        ),
      );
      return;
    }

    setState(() => _analysing = true);
    final detected = _narrationService.analyse(narration);

    final merged = <DetectedDailyAction>[..._actions];
    for (final action in detected) {
      final alreadyExists = merged.any(
        (item) =>
            item.type == action.type &&
            item.details.trim().toLowerCase() ==
                action.details.trim().toLowerCase(),
      );
      if (!alreadyExists) merged.add(action);
    }

    _ensureStatementSlots(merged);

    if (!mounted) return;
    setState(() {
      _actions = merged;
      _analysing = false;
    });
  }

  void _ensureStatementSlots(List<DetectedDailyAction> actions) {
    final needsComplainant = actions.any(
      (item) => item.selected && item.type == 'complainant_examination',
    );
    if (needsComplainant &&
        !_witnessDrafts.any((item) => item.role == 'complainant')) {
      _witnessDrafts.add(_WitnessDraft(role: 'complainant'));
    }

    final witnessCount = actions
        .where((item) => item.selected && item.type == 'witness_examination')
        .fold<int>(0, (sum, item) => sum + (item.witnessCount < 1 ? 1 : item.witnessCount));
    final currentWitnesses =
        _witnessDrafts.where((item) => item.role == 'witness').length;
    for (var index = currentWitnesses; index < witnessCount; index++) {
      _witnessDrafts.add(_WitnessDraft(role: 'witness'));
    }
  }

  Future<void> _editAction(int index) async {
    final action = _actions[index];
    final timeController = TextEditingController(text: action.time);
    final placeController = TextEditingController(text: action.place);
    final detailsController = TextEditingController(text: action.details);
    final repeatReasonController =
        TextEditingController(text: action.repeatReason);
    var isRepeat = action.isRepeat;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            _narrationService.synopsis(action.type, _documentLanguage),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: _ui('সময় (HH:MM)', 'Time (HH:MM)'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: placeController,
                  decoration: InputDecoration(
                    labelText: _ui('স্থান', 'Place'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  minLines: 3,
                  maxLines: 7,
                  decoration: InputDecoration(
                    labelText: _ui('বিস্তারিত', 'Details'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _ui(
                      'এটি একই কাজের পুনরাবৃত্তি/Further Action',
                      'This is a repeated/further action',
                    ),
                  ),
                  value: isRepeat,
                  onChanged: (value) =>
                      setDialogState(() => isRepeat = value),
                ),
                if (isRepeat)
                  TextField(
                    controller: repeatReasonController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: _ui(
                        'পুনরায় করার কারণ',
                        'Reason for repeating the action',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_ui('বাতিল', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (isRepeat && repeatReasonController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(_ui('সংরক্ষণ', 'Save')),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        _actions[index] = action.copyWith(
          time: timeController.text.trim(),
          place: placeController.text.trim(),
          details: detailsController.text.trim(),
          isRepeat: isRepeat,
          repeatReason: repeatReasonController.text.trim(),
        );
      });
    }

    timeController.dispose();
    placeController.dispose();
    detailsController.dispose();
    repeatReasonController.dispose();
  }

  Future<void> _editWitness(int index) async {
    final draft = _witnessDrafts[index];
    final nameController = TextEditingController(text: draft.name);
    final detailsController = TextEditingController(text: draft.details);
    final statementController = TextEditingController(text: draft.statement);
    final reasonController = TextEditingController(text: draft.furtherReason);
    var role = draft.role;
    var further = draft.isFurther;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            _ui('ধারা ১৮০ BNSS-এর বয়ান', 'Statement under Section 180 BNSS'),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: InputDecoration(
                      labelText: _ui('ব্যক্তির ভূমিকা', 'Person’s role'),
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'complainant',
                        child: Text(_ui('অভিযোগকারী', 'Complainant')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'witness',
                        child: Text(_ui('সাক্ষী', 'Witness')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => role = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: _ui('নাম', 'Name'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: _ui(
                        'পিতা/স্বামী, বয়স, ঠিকানা ও পরিচয়',
                        'Parent/spouse, age, address and identity',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: statementController,
                    minLines: 5,
                    maxLines: 12,
                    decoration: InputDecoration(
                      labelText: _ui(
                        'তিনি কী বলেছেন—বলুন বা লিখুন',
                        'What did the person state—speak or type',
                      ),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _ui('ভয়েসে বলুন', 'Dictate by voice'),
                        onPressed: () => _toggleListening(statementController),
                        icon: Icon(
                          _isListening ? Icons.stop_circle : Icons.mic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      OutlinedButton(
                        onPressed: () {
                          statementController.text =
                              _writingAssist.gist(statementController.text);
                        },
                        child: Text(_ui('Gist', 'Gist')),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          statementController.text = _writingAssist
                              .chronological(statementController.text);
                        },
                        child: Text(_ui('ক্রম অনুযায়ী সাজান', 'Chronology')),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          statementController.text = _writingAssist
                              .officialDraft(
                                statementController.text,
                                _documentLanguage,
                              );
                        },
                        child: Text(
                          _ui('সরকারি ভাষা', 'Official language'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _ui(
                        'Further/Re-statement',
                        'Further/Re-statement',
                      ),
                    ),
                    value: further,
                    onChanged: (value) =>
                        setDialogState(() => further = value),
                  ),
                  if (further)
                    TextField(
                      controller: reasonController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: _ui(
                          'অতিরিক্ত/পুনরায় বয়ানের কারণ',
                          'Reason for further/re-statement',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_ui('বাতিল', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final statement = statementController.text.trim();
                if (name.isEmpty || statement.isEmpty) return;
                if (further && reasonController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              child: Text(_ui('সংরক্ষণ', 'Save')),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      final samePersonExists = _existingStatements.any(
        (item) =>
            item.witnessName.trim().toLowerCase() ==
            nameController.text.trim().toLowerCase(),
      );

      if (samePersonExists && !further) {
        final recordFurther = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(_ui('আগের বয়ান পাওয়া গেছে', 'Previous statement found')),
            content: Text(
              _ui(
                '${nameController.text.trim()}-এর বয়ান আগে রেকর্ড করা হয়েছে। এটিকে Further/Re-statement হিসেবে সংরক্ষণ করবেন?',
                'A statement of ${nameController.text.trim()} already exists. Save this as a further/re-statement?',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_ui('বাতিল', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(_ui('Further Statement', 'Further statement')),
              ),
            ],
          ),
        );
        if (recordFurther != true) {
          nameController.dispose();
          detailsController.dispose();
          statementController.dispose();
          reasonController.dispose();
          return;
        }
        further = true;
      }

      setState(() {
        _witnessDrafts[index] = _WitnessDraft(
          role: role,
          name: nameController.text.trim(),
          details: detailsController.text.trim(),
          statement: statementController.text.trim(),
          isFurther: further,
          furtherReason: further && reasonController.text.trim().isEmpty
              ? _ui(
                  'আগে বয়ান রেকর্ড থাকায় অতিরিক্ত বয়ান',
                  'Further statement because a previous statement exists',
                )
              : reasonController.text.trim(),
        );
      });
    }

    nameController.dispose();
    detailsController.dispose();
    statementController.dispose();
    reasonController.dispose();
  }

  Future<String> _translateForDocument(
    String value, {
    Iterable<String> protectedTerms = const <String>[],
  }) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return ProtectedTranslationService.instance.translate(
      trimmed,
      target: _documentLanguage,
      protectedTerms: <String>[
        widget.profile.name,
        widget.profile.policeStation,
        widget.profile.district,
        widget.caseFile.psCaseNo,
        widget.caseFile.sections,
        widget.caseFile.complainantName,
        widget.caseFile.victimName,
        widget.caseFile.accusedName,
        widget.caseFile.placeOfOccurrence,
        ...protectedTerms,
      ],
    );
  }

  Future<void> _generateCd() async {
    final number = _cdNumber;
    if (number == null) return;

    final selectedActions =
        _actions.where((item) => item.selected).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    if (selectedActions.isEmpty) {
      _showMessage(
        _ui(
          'কমপক্ষে একটি তদন্তমূলক কাজ নির্বাচন করুন।',
          'Select at least one investigation action.',
        ),
      );
      return;
    }

    final requiresStatements = selectedActions.any(
      (item) =>
          item.type == 'complainant_examination' ||
          item.type == 'witness_examination',
    );
    if (requiresStatements &&
        _witnessDrafts.any(
          (item) => item.name.trim().isEmpty || item.statement.trim().isEmpty,
        )) {
      _showMessage(
        _ui(
          'অভিযোগকারী/সাক্ষীর নাম ও তিনি কী বলেছেন তা পূরণ করুন।',
          'Complete the name and statement of each complainant/witness.',
        ),
      );
      return;
    }

    final missingTimes = selectedActions.where((item) => item.time.isEmpty).length;
    if (missingTimes > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(_ui('সময় অসম্পূর্ণ', 'Missing time')),
          content: Text(
            _ui(
              '$missingTimesটি কাজের নির্দিষ্ট সময় নেই। অ্যাপ সময় বানাবে না; “সময় উল্লেখ নেই” হিসেবে থাকবে। তবুও এগোবেন?',
              '$missingTimes action(s) have no specific time. The app will not invent a time; they will remain marked as “Time not stated”. Continue?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_ui('না', 'No')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(_ui('এগিয়ে যান', 'Continue')),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _generating = true);

    try {
      final translatedActionDetails = <String, String>{};
      for (final action in selectedActions) {
        translatedActionDetails[action.id] =
            await _translateForDocument(action.details);
      }

      final statementBodies = <_PreparedStatement>[];
      for (final draft in _witnessDrafts) {
        if (draft.name.trim().isEmpty || draft.statement.trim().isEmpty) {
          continue;
        }
        final translatedStatement = await _translateForDocument(
          draft.statement,
          protectedTerms: <String>[draft.name],
        );
        final translatedDetails = await _translateForDocument(
          draft.details,
          protectedTerms: <String>[draft.name],
        );
        final body = _fullStatementBody(
          draft: draft,
          translatedDetails: translatedDetails,
          translatedStatement: translatedStatement,
        );
        statementBodies.add(
          _PreparedStatement(draft: draft, body: body),
        );
      }

      final tableLines = <CdTableLine>[];
      var entryNumber = 1;
      final startTime = selectedActions.first.time.isEmpty
          ? (_documentLanguage.isBangla ? 'সময় উল্লেখ নেই' : 'Time not stated')
          : selectedActions.first.time;
      tableLines.add(
        CdTableLine(
          noAndHour:
              '${_entryNumber(entryNumber++)}\n$startTime',
          placeOfEntry: widget.profile.policeStation,
          synopsis: _documentLanguage.isBangla
              ? 'পরবর্তী তদন্ত পুনরারম্ভ'
              : 'Resumption of further investigation',
          proceedings: _documentLanguage.isBangla
              ? 'মামলাটির পরবর্তী তদন্ত পুনরায় শুরু করলাম।'
              : 'Resumed further investigation of the case.',
        ),
      );

      for (final action in selectedActions) {
        var proceeding = _narrationService.officialProceeding(
          action: action,
          language: _documentLanguage,
          translatedDetails: translatedActionDetails[action.id] ?? '',
        );

        if (action.type == 'complainant_examination') {
          proceeding = _statementCdNarration(
            role: 'complainant',
            statements: statementBodies,
            fallback: proceeding,
          );
        } else if (action.type == 'witness_examination') {
          proceeding = _statementCdNarration(
            role: 'witness',
            statements: statementBodies,
            fallback: proceeding,
          );
        }

        if (action.isRepeat && action.repeatReason.trim().isNotEmpty) {
          proceeding += _documentLanguage.isBangla
              ? ' পুনরায় কার্যক্রম গ্রহণের কারণ: ${action.repeatReason.trim()}।'
              : ' Reason for the repeated action: ${action.repeatReason.trim()}.';
        }

        final time = action.time.isEmpty
            ? (_documentLanguage.isBangla
                ? 'সময় উল্লেখ নেই'
                : 'Time not stated')
            : action.time;
        tableLines.add(
          CdTableLine(
            noAndHour: '${_entryNumber(entryNumber++)}\n$time',
            placeOfEntry: action.place.isEmpty
                ? widget.profile.policeStation
                : action.place,
            synopsis:
                _narrationService.synopsis(action.type, _documentLanguage),
            proceedings: proceeding,
          ),
        );
      }

      final endTime = selectedActions.last.time.isEmpty
          ? (_documentLanguage.isBangla ? 'সময় উল্লেখ নেই' : 'Time not stated')
          : selectedActions.last.time;
      tableLines.add(
        CdTableLine(
          noAndHour: '${_entryNumber(entryNumber)}\n$endTime',
          placeOfEntry: widget.profile.policeStation,
          synopsis: _documentLanguage.isBangla
              ? 'আজকের ডায়েরি বন্ধ'
              : 'Closure of today’s diary',
          proceedings: _documentLanguage.isBangla
              ? 'মামলাটির পরবর্তী তদন্ত মুলতুবি রেখে আজকের মতো কেস ডায়েরি বন্ধ করলাম।'
              : 'Closed the diary pending further investigation of this case.',
        ),
      );

      final body = tableLines.map((item) => item.proceedings).join('\n\n');
      final cd = CdEntry.newDraft(
        caseId: widget.caseFile.id,
        cdNumber: number,
        body: body,
        placeOfEntry: widget.profile.policeStation,
        tableLines: tableLines,
        languageCode: _documentLanguage.code,
      );

      await _saveCentralActions(selectedActions, translatedActionDetails);
      await _saveStatements(statementBodies);
      await _syncLegacyInvestigationStart(selectedActions, statementBodies);
      await _syncSketchMap(selectedActions);
      await _store.saveCd(cd);

      final record = DailyNarrationRecord.create(
        caseId: widget.caseFile.id,
        actionDate: _today,
        inputLanguageCode: _inputLanguageCode,
        documentLanguageCode: _documentLanguage.code,
        originalNarration: _narrationController.text.trim(),
        generatedBody: body,
        actions: <Map<String, dynamic>>[
          ...selectedActions.map((item) => item.toJson()),
          ...statementBodies.map(
            (item) => <String, dynamic>{
              'type': 'statement_180_bnss',
              'role': item.draft.role,
              'name': item.draft.name,
              'originalStatement': item.draft.statement,
              'generatedStatement': item.body,
              'isFurther': item.draft.isFurther,
              'furtherReason': item.draft.furtherReason,
            },
          ),
        ],
      );
      await _workflowStore.saveRecord(record);

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CdEditorScreen(
            profile: widget.profile,
            caseFile: widget.caseFile,
            cd: cd,
          ),
        ),
      );
    } catch (error) {
      _showMessage(
        _ui(
          'সিডি তৈরি করা যায়নি: $error',
          'The case diary could not be generated: $error',
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _saveCentralActions(
    List<DetectedDailyAction> actions,
    Map<String, String> translatedDetails,
  ) async {
    for (final action in actions) {
      final duplicate = _existingActions.any(
        (item) =>
            item.actionDate == _today &&
            item.actionType == action.type &&
            !action.isRepeat,
      );
      if (duplicate) continue;

      final entry = InvestigationActionEntry.create(
        caseId: widget.caseFile.id,
        actionDate: _today,
        actionType: action.type,
        outsidePs: action.type == 'departure' ||
            action.type == 'po_visit' ||
            action.type == 'search' ||
            action.type == 'court' ||
            action.type == 'medical',
        departureTime: action.type == 'departure' ? action.time : '',
        actionArrivalTime: action.time,
        returnTime: action.type == 'return_ps' ? action.time : '',
        place: action.place,
        accompaniedBy: '',
        sopResponse: jsonEncode(<String, dynamic>{
          'source': 'simple_daily_cd',
          'originalSentence': action.sourceSentence,
          'isRepeat': action.isRepeat,
          'repeatReason': action.repeatReason,
        }),
        details: translatedDetails[action.id] ?? action.details,
        arrestInvolved: action.type == 'arrest',
        seizureInvolved: action.type == 'seizure',
        courtForwardingSuggested: action.type == 'arrest',
        pcPrayerSuggested: action.type == 'arrest',
      );
      await _store.saveInvestigationAction(entry);
      _existingActions.add(entry);
    }
  }

  Future<void> _saveStatements(List<_PreparedStatement> statements) async {
    for (final prepared in statements) {
      final draft = prepared.draft;
      final duplicate = _existingStatements.any(
        (item) =>
            item.witnessName.trim().toLowerCase() ==
                draft.name.trim().toLowerCase() &&
            !draft.isFurther,
      );
      if (duplicate) continue;

      final statement = StatementEntry.create(
        caseId: widget.caseFile.id,
        witnessName: draft.name,
        witnessDetails: draft.details,
        statementType: _documentLanguage.isBangla
            ? (draft.isFurther
                ? 'ধারা ১৮০ BNSS-এর অধীন অতিরিক্ত বয়ান'
                : 'ধারা ১৮০ BNSS-এর অধীন বয়ান')
            : (draft.isFurther
                ? 'Further statement under Section 180 BNSS'
                : 'Statement under Section 180 BNSS'),
        body: prepared.body,
      );
      await _store.saveStatement(statement);
      _existingStatements.add(statement);
    }
  }


  Future<void> _syncLegacyInvestigationStart(
    List<DetectedDailyAction> actions,
    List<_PreparedStatement> statements,
  ) async {
    final current = widget.caseFile.investigationStart;

    DetectedDailyAction? first(String type) {
      for (final action in actions) {
        if (action.type == type) return action;
      }
      return null;
    }

    final po = first('po_visit');
    final sketch = first('sketch_map');
    final medical = first('medical');
    final seizure = first('seizure');
    final evidence = first('evidence_collection');
    final witnessNames = statements
        .map((item) => item.draft.name.trim())
        .where((name) => name.isNotEmpty)
        .join(', ');

    String detailsOrCurrent(
      DetectedDailyAction? action,
      String currentValue,
    ) {
      if (action == null || action.details.trim().isEmpty) return currentValue;
      return action.details;
    }

    final updatedStart = InvestigationStart(
      ioName: current.ioName.isEmpty ? widget.profile.name : current.ioName,
      tookUpDate: current.tookUpDate.isEmpty ? _today : current.tookUpDate,
      visitedPo: current.visitedPo || po != null,
      poDetails: detailsOrCurrent(po, current.poDetails),
      sketchPrepared: current.sketchPrepared || sketch != null,
      sketchDetails: detailsOrCurrent(sketch, current.sketchDetails),
      witnessExamined: current.witnessExamined || statements.isNotEmpty,
      witnessDetails: witnessNames.isNotEmpty
          ? witnessNames
          : current.witnessDetails,
      medicalRequired: current.medicalRequired || medical != null,
      medicalDetails: detailsOrCurrent(medical, current.medicalDetails),
      seizureRequired: current.seizureRequired || seizure != null,
      seizureDetails: detailsOrCurrent(seizure, current.seizureDetails),
      evidenceRequired: current.evidenceRequired || evidence != null,
      evidenceDetails: detailsOrCurrent(evidence, current.evidenceDetails),
    );

    await _store.saveCase(
      widget.caseFile.copyWith(investigationStart: updatedStart),
    );
  }

  Future<void> _syncSketchMap(List<DetectedDailyAction> actions) async {
    DetectedDailyAction? sketchAction;
    DetectedDailyAction? poAction;
    for (final action in actions) {
      if (action.type == 'sketch_map') sketchAction ??= action;
      if (action.type == 'po_visit') poAction ??= action;
    }

    if (sketchAction == null || _existingSketchMap != null) return;

    final empty = SketchMapEntry.empty(caseId: widget.caseFile.id);
    final map = empty.copyWith(
      date: _today,
      poDescription: poAction?.details ?? sketchAction.details,
    );
    await _store.saveSketchMap(map);
    _existingSketchMap = map;
  }

  String _fullStatementBody({
    required _WitnessDraft draft,
    required String translatedDetails,
    required String translatedStatement,
  }) {
    final details = translatedDetails.trim();
    final statement = translatedStatement.trim();
    if (_documentLanguage.isBangla) {
      final identity = details.isEmpty ? '' : ', $details';
      final further = draft.isFurther && draft.furtherReason.isNotEmpty
          ? ' এটি অতিরিক্ত/পুনরায় বয়ান; কারণ: ${draft.furtherReason}।'
          : '';
      return 'আমি, ${draft.name}$identity, জিজ্ঞাসাবাদে জানাই যে, $statement$further';
    }

    final identity = details.isEmpty ? '' : ', $details';
    final further = draft.isFurther && draft.furtherReason.isNotEmpty
        ? ' This is a further/re-statement for the following reason: ${draft.furtherReason}.'
        : '';
    return 'I, ${draft.name}$identity, state on examination that $statement$further';
  }

  String _statementCdNarration({
    required String role,
    required List<_PreparedStatement> statements,
    required String fallback,
  }) {
    final matching =
        statements.where((item) => item.draft.role == role).toList();
    if (matching.isEmpty) return fallback;

    final names = matching.map((item) => item.draft.name).join(', ');
    final gists = matching
        .map((item) => _writingAssist.gist(item.draft.statement))
        .join(' ');

    if (_documentLanguage.isBangla) {
      final label = role == 'complainant' ? 'অভিযোগকারী' : 'সাক্ষী/সাক্ষীগণ';
      return '$label $names-কে পৃথকভাবে জিজ্ঞাসাবাদ করলাম। তাঁরা সংক্ষেপে জানান যে, $gists। তাঁদের পূর্ণ বয়ান ধারা ১৮০ BNSS অনুসারে পৃথকভাবে লিপিবদ্ধ করলাম।';
    }

    final label = role == 'complainant' ? 'the complainant' : 'the witness/witnesses';
    return 'I examined $label, namely $names, separately. In substance, they stated that $gists. Their full statements were recorded separately under Section 180 BNSS.';
  }

  String _entryNumber(int number) {
    if (_documentLanguage.isEnglish) return number.toString();
    const digits = <String>['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number
        .toString()
        .split('')
        .map((item) => digits[int.parse(item)])
        .join();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AnimatedBuilder(
      animation: AppLanguageController.instance,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            _ui(
              'সহজ দৈনিক সিডি — CD-${_cdNumber ?? ''}',
              'Simple Daily CD — CD-${_cdNumber ?? ''}',
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _generating ? null : _generateCd,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _generating
                    ? _ui('সিডি তৈরি হচ্ছে...', 'Generating CD...')
                    : _ui(
                        'খসড়া সিডি তৈরি ও পর্যালোচনা',
                        'Generate and review draft CD',
                      ),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: <Widget>[
            _languageCard(),
            const SizedBox(height: 12),
            _narrationCard(),
            const SizedBox(height: 12),
            _actionCard(),
            const SizedBox(height: 12),
            _statementCard(),
            const SizedBox(height: 12),
            _singleSourceCard(),
          ],
        ),
      ),
    );
  }

  Widget _languageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _ui('ভাষা নির্বাচন', 'Language selection'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: AppLanguageController.instance.languageCode,
              decoration: InputDecoration(
                labelText: _ui('পুরো অ্যাপের ভাষা', 'System language'),
                border: const OutlineInputBorder(),
              ),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'bn', child: Text('বাংলা')),
                DropdownMenuItem<String>(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) {
                  AppLanguageController.instance.setLanguage(value);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _inputLanguageCode,
                    decoration: InputDecoration(
                      labelText: _ui('যে ভাষায় বলবেন', 'Input language'),
                      border: const OutlineInputBorder(),
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'bn_BD',
                        child: Text('বাংলা'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'en_US',
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _inputLanguageCode = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<DocumentLanguage>(
                    value: _documentLanguage,
                    decoration: InputDecoration(
                      labelText: _ui('সিডির ভাষা', 'Document language'),
                      border: const OutlineInputBorder(),
                    ),
                    items: DocumentLanguage.values
                        .map(
                          (language) => DropdownMenuItem<DocumentLanguage>(
                            value: language,
                            child: Text(language.displayLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _documentLanguage = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _ui(
                'বাংলায় বললেও English সিডি নির্বাচন করলে অনুবাদ করে সরকারি English draft তৈরি হবে। নাম, মামলা নম্বর, তারিখ, সময়, ধারা, IMEI ও অন্যান্য পরিচয় অপরিবর্তিত থাকবে।',
                'You may narrate in Bangla and select English output. The app will translate the narrative into an official English draft while preserving names, case numbers, dates, times, sections, IMEI and other identifiers.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _narrationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _ui(
                'আজকের সম্পূর্ণ তদন্তের ঘটনা বলুন বা লিখুন',
                'Speak or type today’s complete investigation',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _ui(
                'স্বাভাবিকভাবে পুরো ঘটনাটি বলুন। বিরতি হলে আবার মাইক চাপুন—নতুন বক্তব্য আগের লেখার শেষে যুক্ত হবে।',
                'Narrate naturally. If recognition stops after a pause, tap the microphone again; the next segment will be appended.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _narrationController,
              minLines: 7,
              maxLines: 16,
              decoration: InputDecoration(
                hintText: _ui(
                  'উদাহরণ: আজ সকাল ১০টায় থানা থেকে রওনা হয়ে ঘটনাস্থলে যাই...',
                  'Example: At 10:00 hrs I left the Police Station and proceeded to the place of occurrence...',
                ),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _ui('ভয়েসে বলুন', 'Dictate by voice'),
                  onPressed: () => _toggleListening(_narrationController),
                  icon: Icon(
                    _isListening ? Icons.stop_circle : Icons.mic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _analysing ? null : _analyseNarration,
                    icon: _analysing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.account_tree_outlined),
                    label: Text(
                      _ui(
                        'ঘটনা বিশ্লেষণ ও chronology তৈরি',
                        'Analyse and build chronology',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: _ui('লেখা মুছুন', 'Clear narration'),
                  onPressed: () {
                    setState(() {
                      _narrationController.clear();
                      _actions = _actions
                          .where((item) => item.id.startsWith('inv_'))
                          .toList();
                      _witnessDrafts.clear();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _ui('শনাক্ত chronology', 'Detected chronology'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _ui(
                'Investigation/Step Map-এ আজ আগে থেকে সংরক্ষিত কাজ থাকলে সেগুলো এখানে নিজে থেকেই এসেছে। একই তথ্য আবার দিতে হবে না।',
                'Actions already saved today in Investigation/Step Map appear here automatically. The same details do not need to be entered again.',
              ),
            ),
            const SizedBox(height: 12),
            if (_actions.isEmpty)
              Text(
                _ui(
                  'এখনও কোনো কাজ শনাক্ত হয়নি। উপরে পুরো ঘটনা বলুন বা লিখুন।',
                  'No action has been detected yet. Narrate or type the full day above.',
                ),
              )
            else
              ..._actions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: action.selected,
                    onChanged: (value) {
                      setState(() {
                        _actions[index] =
                            action.copyWith(selected: value ?? false);
                      });
                    },
                    title: Text(
                      '${index + 1}. ${_narrationService.synopsis(action.type, _documentLanguage)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${action.time.isEmpty ? _ui('সময় উল্লেখ নেই', 'Time not stated') : action.time}'
                      '${action.place.isEmpty ? '' : ' • ${action.place}'}\n${action.details}'
                      '${action.isRepeat ? '\n${_ui('পুনরাবৃত্তি:', 'Repeated:')} ${action.repeatReason}' : ''}',
                    ),
                    secondary: IconButton(
                      tooltip: _ui('সংশোধন করুন', 'Edit'),
                      onPressed: () => _editAction(index),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () {
                final now = DateTime.now();
                setState(() {
                  _actions.add(
                    DetectedDailyAction(
                      id: 'manual_${now.microsecondsSinceEpoch}',
                      type: 'other',
                      time: '',
                      place: '',
                      details: '',
                      sourceSentence: '',
                      order: _actions.length + 1,
                    ),
                  );
                });
                _editAction(_actions.length - 1);
              },
              icon: const Icon(Icons.add),
              label: Text(_ui('অন্য কাজ যোগ করুন', 'Add another action')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statementCard() {
    final selectedNeedsStatement = _actions.any(
      (item) =>
          item.selected &&
          (item.type == 'complainant_examination' ||
              item.type == 'witness_examination'),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _ui(
                'অভিযোগকারী/সাক্ষীর বয়ান — ধারা ১৮০ BNSS',
                'Complainant/Witness statements — Section 180 BNSS',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _ui(
                '“সাক্ষী পরীক্ষা” শনাক্ত হলে অ্যাপ শুধু Completed করবে না; প্রত্যেকে কী বলেছেন তা নেবে। একই record থেকেই পূর্ণ বয়ান, CD gist ও witness list তৈরি হবে।',
                'When witness examination is detected, the app captures what each person stated. The same record is used for the full statement, CD gist and witness list.',
              ),
            ),
            const SizedBox(height: 12),
            if (!selectedNeedsStatement && _witnessDrafts.isEmpty)
              Text(
                _ui(
                  'Chronology-তে অভিযোগকারী/সাক্ষী পরীক্ষা থাকলে এখানে প্রয়োজনীয় statement card নিজে থেকে তৈরি হবে।',
                  'Statement cards will be created automatically when complainant/witness examination is present in the chronology.',
                ),
              ),
            ..._witnessDrafts.asMap().entries.map((entry) {
              final index = entry.key;
              final draft = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(
                  draft.name.isEmpty
                      ? (draft.role == 'complainant'
                          ? _ui('অভিযোগকারীর বয়ান দিন', 'Enter complainant statement')
                          : _ui('সাক্ষীর বয়ান দিন', 'Enter witness statement'))
                      : draft.name,
                ),
                subtitle: Text(
                  draft.statement.isEmpty
                      ? _ui(
                          'নাম এবং তিনি কী বলেছেন তা প্রয়োজন',
                          'Name and statement are required',
                        )
                      : _writingAssist.gist(draft.statement),
                ),
                trailing: IconButton(
                  onPressed: () => _editWitness(index),
                  icon: const Icon(Icons.edit_note),
                ),
              );
            }),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _witnessDrafts.add(_WitnessDraft(role: 'witness'));
                });
                _editWitness(_witnessDrafts.length - 1);
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(
                _ui('অন্য সাক্ষীর বয়ান যোগ করুন', 'Add another witness statement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _singleSourceCard() {
    final hasSketch = _existingSketchMap != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _ui('একবার তথ্য দিন—সব জায়গায় ব্যবহার', 'Enter once—use everywhere'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _ui(
                'PO Visit, Sketch Map, সাক্ষীর বয়ান, তল্লাশি, জব্দ ও গ্রেপ্তার এখানে দিলে Investigation Step-এও একই central record থাকবে। Step Map-এ আগে দিলে এখানে তা নিজে থেকে আসবে।',
                'PO visit, sketch map, statements, search, seizure and arrest use one central record. Data entered in Step Map appears here automatically, and data entered here updates the investigation record.',
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                hasSketch ? Icons.check_circle : Icons.info_outline,
              ),
              title: Text(
                hasSketch
                    ? _ui(
                        'এই মামলার Sketch Map record পাওয়া গেছে—আবার details চাওয়া হবে না।',
                        'A Sketch Map record already exists—details will not be requested again.',
                      )
                    : _ui(
                        'Sketch Map action থাকলে একটি linked draft record তৈরি হবে; পরে Map screen-এ সেটিই খুলবে।',
                        'If a Sketch Map action is present, a linked draft record will be created and opened later in the Map screen.',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WitnessDraft {
  final String role;
  final String name;
  final String details;
  final String statement;
  final bool isFurther;
  final String furtherReason;

  const _WitnessDraft({
    required this.role,
    this.name = '',
    this.details = '',
    this.statement = '',
    this.isFurther = false,
    this.furtherReason = '',
  });
}

class _PreparedStatement {
  final _WitnessDraft draft;
  final String body;

  const _PreparedStatement({
    required this.draft,
    required this.body,
  });
}
