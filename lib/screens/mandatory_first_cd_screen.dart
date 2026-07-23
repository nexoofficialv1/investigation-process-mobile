import 'package:flutter/material.dart';

import '../core/document_language.dart';
import '../models/case_file.dart';
import '../models/guided_daily_entry.dart';
import '../models/officer_profile.dart';
import '../services/chronology_engine_service.dart';
import '../services/daily_cd_assembly_service.dart';
import '../services/guided_daily_entry_store.dart';
import '../services/local_store_service.dart';
import 'cd_editor_screen.dart';
import 'sketch_map_screen.dart';

class MandatoryFirstCdScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const MandatoryFirstCdScreen({
    super.key,
    required this.profile,
    required this.caseFile,
  });

  @override
  State<MandatoryFirstCdScreen> createState() =>
      _MandatoryFirstCdScreenState();
}

class _MandatoryFirstCdScreenState extends State<MandatoryFirstCdScreen> {
  final GuidedDailyEntryStore _entryStore = GuidedDailyEntryStore();
  final ChronologyEngineService _chronology = ChronologyEngineService();
  final DailyCdAssemblyService _assembly = DailyCdAssemblyService();
  final LocalStoreService _localStore = LocalStoreService();

  final TextEditingController _takingUpTime = TextEditingController();
  final TextEditingController _departureTime = TextEditingController();
  final TextEditingController _departurePurpose = TextEditingController(
    text: 'ঘটনাস্থল পরিদর্শন, অভিযোগকারী ও সাক্ষীদের পরীক্ষা এবং প্রাথমিক তদন্ত।',
  );
  final TextEditingController _poArrivalTime = TextEditingController();
  late final TextEditingController _poDetails;
  final TextEditingController _poObservation = TextEditingController();
  final TextEditingController _sketchReason = TextEditingController();
  final TextEditingController _complainantTime = TextEditingController();
  final TextEditingController _complainantStatement = TextEditingController();
  final TextEditingController _noWitnessReason = TextEditingController();

  final TextEditingController _seizureTime = TextEditingController();
  final TextEditingController _seizedArticle = TextEditingController();
  final TextEditingController _seizedFrom = TextEditingController();
  final TextEditingController _seizureWitness = TextEditingController();
  final TextEditingController _seizureReference = TextEditingController();

  final TextEditingController _medicalTime = TextEditingController();
  final TextEditingController _medicalPerson = TextEditingController();
  final TextEditingController _medicalFacility = TextEditingController();
  final TextEditingController _medicalResult = TextEditingController();

  final TextEditingController _evidenceTime = TextEditingController();
  final TextEditingController _evidenceDescription = TextEditingController();
  final TextEditingController _evidenceSource = TextEditingController();
  final TextEditingController _evidencePreservation = TextEditingController();

  final TextEditingController _returnTime = TextEditingController();
  final TextEditingController _returnStatus = TextEditingController();

  final List<_WitnessDraft> _witnesses = <_WitnessDraft>[];
  int _step = 0;
  bool _sketchPrepared = true;
  bool _noWitnessAvailable = false;
  bool _seizureApplicable = false;
  bool _medicalApplicable = false;
  bool _evidenceApplicable = false;
  bool _busy = false;
  DocumentLanguage _language = DocumentLanguage.bangla;

  String get _caseDate => widget.caseFile.caseDate.trim().isEmpty
      ? DateTime.now().toIso8601String().split('T').first
      : widget.caseFile.caseDate.trim();

  String get _station => widget.profile.policeStation.trim().isEmpty
      ? 'Police Station'
      : widget.profile.policeStation.trim();

  @override
  void initState() {
    super.initState();
    final start = widget.caseFile.investigationStart;
    _poDetails = TextEditingController(
      text: start.poDetails.trim().isNotEmpty
          ? start.poDetails.trim()
          : widget.caseFile.placeOfOccurrence.trim(),
    );
    _poObservation.text = start.poDetails.trim();
    if (start.witnessDetails.trim().isNotEmpty) {
      _witnesses.add(
        _WitnessDraft(
          identity: start.witnessDetails.trim(),
          statement: '',
          time: '',
        ),
      );
    }
    _seizureApplicable = start.seizureRequired;
    _seizedArticle.text = start.seizureDetails.trim();
    _medicalApplicable = start.medicalRequired;
    _medicalResult.text = start.medicalDetails.trim();
    _evidenceApplicable = start.evidenceRequired;
    _evidenceDescription.text = start.evidenceDetails.trim();
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _takingUpTime,
      _departureTime,
      _departurePurpose,
      _poArrivalTime,
      _poDetails,
      _poObservation,
      _sketchReason,
      _complainantTime,
      _complainantStatement,
      _noWitnessReason,
      _seizureTime,
      _seizedArticle,
      _seizedFrom,
      _seizureWitness,
      _seizureReference,
      _medicalTime,
      _medicalPerson,
      _medicalFacility,
      _medicalResult,
      _evidenceTime,
      _evidenceDescription,
      _evidenceSource,
      _evidencePreservation,
      _returnTime,
      _returnStatus,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selected == null || !mounted) return;
    controller.text =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')} hrs';
  }

  Widget _timeField(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickTime(controller),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.schedule),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  bool _require(
    TextEditingController controller,
    String message,
  ) {
    if (controller.text.trim().isNotEmpty) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    return false;
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _require(
              _takingUpTime,
              'FIR/Case Papers গ্রহণ ও তদন্তভার গ্রহণের সময় দিন।',
            ) &&
            _require(
              _departureTime,
              'থানা থেকে রওনার সময় দিন।',
            ) &&
            _require(
              _departurePurpose,
              'রওনার উদ্দেশ্য লিখুন।',
            );
      case 1:
        if (!_require(_poArrivalTime, 'PO-তে পৌঁছানোর সময় দিন।') ||
            !_require(_poDetails, 'PO-এর বিস্তারিত অবস্থান লিখুন।') ||
            !_require(
              _poObservation,
              'PO-তে দেখা গুরুত্বপূর্ণ বিষয়গুলো লিখুন।',
            )) {
          return false;
        }
        if (!_sketchPrepared &&
            _sketchReason.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sketch Map প্রস্তুত না করার কারণ লিখুন।',
              ),
            ),
          );
          return false;
        }
        return true;
      case 2:
        if (!_require(
          _complainantTime,
          'অভিযোগকারী পরীক্ষার সময় দিন।',
        )) {
          return false;
        }
        if (widget.caseFile.complainantName.trim().isNotEmpty &&
            !_require(
              _complainantStatement,
              'অভিযোগকারীর বক্তব্যের সারাংশ লিখুন।',
            )) {
          return false;
        }
        if (_noWitnessAvailable) {
          return _require(
            _noWitnessReason,
            'প্রাথমিক সাক্ষী না পাওয়ার কারণ লিখুন।',
          );
        }
        if (_witnesses.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'অন্তত একজন প্রাথমিক সাক্ষী যোগ করুন অথবা সাক্ষী পাওয়া যায়নি নির্বাচন করুন।',
              ),
            ),
          );
          return false;
        }
        for (final witness in _witnesses) {
          if (witness.identity.trim().isEmpty ||
              witness.statement.trim().isEmpty ||
              witness.time.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'প্রত্যেক সাক্ষীর সময়, পরিচয় এবং বক্তব্য সম্পূর্ণ করুন।',
                ),
              ),
            );
            return false;
          }
        }
        return true;
      case 3:
        if (_seizureApplicable &&
            (!_require(_seizureTime, 'জব্দের সময় দিন।') ||
                !_require(
                  _seizedArticle,
                  'জব্দ করা বস্তু/নথির বিবরণ দিন।',
                ) ||
                !_require(
                  _seizedFrom,
                  'কোথা থেকে/কার কাছ থেকে জব্দ হয়েছে লিখুন।',
                ) ||
                !_require(
                  _seizureWitness,
                  'জব্দ সাক্ষীদের নাম লিখুন।',
                ) ||
                !_require(
                  _seizureReference,
                  'Seizure List reference লিখুন।',
                ))) {
          return false;
        }
        if (_medicalApplicable &&
            (!_require(_medicalTime, 'Medical action-এর সময় দিন।') ||
                !_require(
                  _medicalPerson,
                  'কার medical examination হয়েছে লিখুন।',
                ) ||
                !_require(
                  _medicalFacility,
                  'Hospital/Medical Officer-এর নাম লিখুন।',
                ) ||
                !_require(
                  _medicalResult,
                  'Medical requisition/report-এর অবস্থা লিখুন।',
                ))) {
          return false;
        }
        if (_evidenceApplicable &&
            (!_require(
                  _evidenceTime,
                  'Evidence collection-এর সময় দিন।',
                ) ||
                !_require(
                  _evidenceDescription,
                  'Evidence-এর পূর্ণ বিবরণ লিখুন।',
                ) ||
                !_require(
                  _evidenceSource,
                  'Evidence-এর উৎস লিখুন।',
                ) ||
                !_require(
                  _evidencePreservation,
                  'Evidence কীভাবে সংরক্ষণ করেছেন লিখুন।',
                ))) {
          return false;
        }
        return true;
      case 4:
        return _require(
              _returnTime,
              'থানায় প্রত্যাবর্তন/দিনের কাজ বন্ধের সময় দিন।',
            ) &&
            _require(
              _returnStatus,
              'ফেরার পর নথি/আলামত জমা বা সংরক্ষণের বিবরণ লিখুন।',
            );
      default:
        return true;
    }
  }

  Future<void> _addWitness() async {
    final time = TextEditingController();
    final identity = TextEditingController();
    final statement = TextEditingController();

    final result = await showDialog<_WitnessDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('প্রাথমিক সাক্ষীর বয়ান'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: time,
                  readOnly: true,
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.now(),
                    );
                    if (selected != null) {
                      time.text =
                          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')} hrs';
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'পরীক্ষার সময়',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.schedule),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: identity,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'নাম, পিতৃপরিচয় ও ঠিকানা',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: statement,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'বক্তব্যের মূল বিষয়',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () {
              if (time.text.trim().isEmpty ||
                  identity.text.trim().isEmpty ||
                  statement.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(
                dialogContext,
                _WitnessDraft(
                  time: time.text.trim(),
                  identity: identity.text.trim(),
                  statement: statement.text.trim(),
                ),
              );
            },
            child: const Text('সাক্ষী যোগ করুন'),
          ),
        ],
      ),
    );
    time.dispose();
    identity.dispose();
    statement.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _noWitnessAvailable = false;
      _witnesses.add(result);
    });
  }

  Future<void> _openSketchMap() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SketchMapScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
        ),
      ),
    );
  }

  void _continue() {
    if (!_validateStep(_step)) return;
    if (_step < 4) {
      setState(() => _step += 1);
    } else {
      _finalizeFirstCd();
    }
  }

  List<GuidedAction> _buildActions() {
    final actions = <GuidedAction>[];
    var sequence = 10;
    final seed = DateTime.now().microsecondsSinceEpoch;

    actions.add(
      GuidedAction(
        id: 'first_cd_departure_$seed',
        type: 'departure',
        time: _departureTime.text.trim(),
        place: _station,
        details:
            '${_takingUpTime.text.trim()}-এ FIR/Case Papers গ্রহণ করে তদন্তভার গ্রহণ। ${_departurePurpose.text.trim()}',
        sequence: sequence,
        answers: <String, String>{
          'taking_up_time': _takingUpTime.text.trim(),
          'purpose': _departurePurpose.text.trim(),
        },
      ),
    );
    sequence += 10;

    actions.add(
      GuidedAction(
        id: 'first_cd_po_${seed + 1}',
        type: 'po_visit',
        time: _poArrivalTime.text.trim(),
        place: _poDetails.text.trim(),
        details: _poObservation.text.trim(),
        sequence: sequence,
        answers: <String, String>{
          'po_observation': _poObservation.text.trim(),
        },
      ),
    );
    sequence += 10;

    actions.add(
      GuidedAction(
        id: 'first_cd_sketch_${seed + 2}',
        type: 'sketch_map',
        time: _poArrivalTime.text.trim(),
        place: _poDetails.text.trim(),
        details: _sketchPrepared
            ? 'PO-এর অবস্থান ও পারিপার্শ্বিকতা প্রদর্শন করে Rough Sketch Map প্রস্তুত।'
            : 'Rough Sketch Map প্রস্তুত করা হয়নি। কারণ: ${_sketchReason.text.trim()}',
        sequence: sequence,
        answers: <String, String>{
          'sketch_map_decision': _sketchPrepared ? 'হ্যাঁ' : 'না',
          'sketch_reference': _sketchPrepared
              ? 'সূচিসহ ঘটনাস্থলের খসড়া নকশা'
              : 'প্রস্তুত করা হয়নি: ${_sketchReason.text.trim()}',
        },
      ),
    );
    sequence += 10;

    if (widget.caseFile.complainantName.trim().isNotEmpty) {
      actions.add(
        GuidedAction(
          id: 'first_cd_complainant_${seed + 3}',
          type: 'complainant_examination',
          time: _complainantTime.text.trim(),
          place: _poDetails.text.trim(),
          details: _complainantStatement.text.trim(),
          sequence: sequence,
          answers: <String, String>{
            'person_identity': widget.caseFile.complainantName.trim(),
            'statement_substance': _complainantStatement.text.trim(),
          },
        ),
      );
      sequence += 10;
    }

    if (_noWitnessAvailable) {
      actions.add(
        GuidedAction(
          id: 'first_cd_witness_na_${seed + 4}',
          type: 'witness_examination',
          time: _complainantTime.text.trim(),
          place: _poDetails.text.trim(),
          details:
              'প্রাথমিক সাক্ষী পাওয়া যায়নি। কারণ: ${_noWitnessReason.text.trim()}',
          sequence: sequence,
          answers: <String, String>{
            'person_identity': 'প্রাথমিক সাক্ষী পাওয়া যায়নি',
            'statement_substance': _noWitnessReason.text.trim(),
            'statement_recorded': 'প্রযোজ্য নয়',
          },
        ),
      );
      sequence += 10;
    } else {
      for (final witness in _witnesses) {
        actions.add(
          GuidedAction(
            id: 'first_cd_witness_${seed + sequence}',
            type: 'witness_examination',
            time: witness.time,
            place: _poDetails.text.trim(),
            details: witness.statement,
            sequence: sequence,
            answers: <String, String>{
              'person_identity': witness.identity,
              'statement_substance': witness.statement,
              'statement_recorded': 'হ্যাঁ',
            },
          ),
        );
        sequence += 10;
      }
    }

    if (_seizureApplicable) {
      actions.add(
        GuidedAction(
          id: 'first_cd_seizure_${seed + sequence}',
          type: 'seizure',
          time: _seizureTime.text.trim(),
          place: _seizedFrom.text.trim(),
          details: _seizedArticle.text.trim(),
          sequence: sequence,
          answers: <String, String>{
            'article_description': _seizedArticle.text.trim(),
            'seized_from': _seizedFrom.text.trim(),
            'seizure_witness': _seizureWitness.text.trim(),
            'seizure_list': 'হ্যাঁ',
            'seizure_reference': _seizureReference.text.trim(),
          },
        ),
      );
      sequence += 10;
    }

    if (_medicalApplicable) {
      actions.add(
        GuidedAction(
          id: 'first_cd_medical_${seed + sequence}',
          type: 'medical',
          time: _medicalTime.text.trim(),
          place: _medicalFacility.text.trim(),
          details: _medicalResult.text.trim(),
          sequence: sequence,
          answers: <String, String>{
            'person_identity': _medicalPerson.text.trim(),
            'medical_facility': _medicalFacility.text.trim(),
            'medical_result': _medicalResult.text.trim(),
          },
        ),
      );
      sequence += 10;
    }

    if (_evidenceApplicable) {
      actions.add(
        GuidedAction(
          id: 'first_cd_evidence_${seed + sequence}',
          type: 'evidence_collection',
          time: _evidenceTime.text.trim(),
          place: _evidenceSource.text.trim(),
          details: _evidenceDescription.text.trim(),
          sequence: sequence,
          answers: <String, String>{
            'evidence_category': 'Other',
            'evidence_description': _evidenceDescription.text.trim(),
            'evidence_source': _evidenceSource.text.trim(),
            'preservation': _evidencePreservation.text.trim(),
          },
        ),
      );
      sequence += 10;
    }

    actions.add(
      GuidedAction(
        id: 'first_cd_return_${seed + sequence}',
        type: 'return_ps',
        time: _returnTime.text.trim(),
        place: _station,
        details: _returnStatus.text.trim(),
        sequence: sequence,
        answers: <String, String>{
          'return_status': _returnStatus.text.trim(),
        },
      ),
    );

    return actions;
  }

  GuidedDailyEntry _buildFirstCdEntry() {
    final now = DateTime.now();
    return GuidedDailyEntry(
      id: 'first_cd_${widget.caseFile.id}',
      caseId: widget.caseFile.id,
      actionDate: _caseDate,
      source: DailyEntrySource.investigation,
      narration:
          'Mandatory First Case Diary guided chronology for ${widget.caseFile.displayTitle}',
      inputLanguageCode: 'bn',
      documentLanguageCode: _language.code,
      actions: _buildActions(),
      includeInCd: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _saveDraft() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final entry = _buildFirstCdEntry();
      final assessment = await _chronology.assessEntry(entry);
      final draft = entry.copyWith(
        actions: assessment.acceptedActions.cast<GuidedAction>(),
      );
      await _entryStore.save(draft);
      await _chronology.commitEntry(draft, assessment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'অসম্পূর্ণ CD-I Draft সংরক্ষিত হয়েছে। Final করার আগে বাকি প্রশ্নগুলোর উত্তর দিতে হবে।',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CD-I Draft সংরক্ষণ করা যায়নি: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finalizeFirstCd() async {
    if (_busy || !_validateStep(4)) return;
    setState(() => _busy = true);
    try {
      if (_sketchPrepared) {
        final sketch = await _localStore.loadSketchMap(widget.caseFile.id);
        if (sketch == null) {
          if (!mounted) return;
          final openMap = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Rough Sketch Map এখনও Save হয়নি'),
              content: const Text(
                'CD-I সম্পূর্ণ করার আগে Sketch Map portal-এ নকশাটি Save করুন।',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Review-এ থাকুন'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Sketch Map খুলুন'),
                ),
              ],
            ),
          );
          if (openMap == true) await _openSketchMap();
          return;
        }
      }

      final entry = _buildFirstCdEntry();

      final assessment = await _chronology.assessEntry(entry);
      if (!assessment.hasNewFacts) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'একই First-CD তথ্য আগে থেকেই chronology-তে রয়েছে। নতুন CD তৈরি হয়নি।',
            ),
          ),
        );
        return;
      }

      final acceptedEntry = entry.copyWith(
        actions: assessment.acceptedActions.cast<GuidedAction>(),
      );
      await _entryStore.save(acceptedEntry);
      await _chronology.commitEntry(acceptedEntry, assessment);

      final existing = await _localStore.loadCdForDate(
        widget.caseFile.id,
        _caseDate,
      );
      final result = await _assembly.build(
        caseId: widget.caseFile.id,
        caseFile: widget.caseFile,
        actionDate: _caseDate,
        cdNumber: existing?.cdNumber ?? 1,
        profile: widget.profile,
        language: _language,
        entries: <GuidedDailyEntry>[acceptedEntry],
      );
      if (result == null) {
        throw StateError('First-CD assembly produced no verified rows.');
      }

      final saved = await _localStore.saveCdForDate(result.cd);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CdEditorScreen(
            profile: widget.profile,
            caseFile: widget.caseFile,
            cd: saved,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CD-I তৈরি করা যায়নি: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mandatory First Case Diary'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            onPressed: _busy ? null : _saveDraft,
            tooltip: 'অসম্পূর্ণ CD-I Draft সংরক্ষণ',
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (value) {
          if (value <= _step) setState(() => _step = value);
        },
        onStepContinue: _busy ? null : _continue,
        onStepCancel: _step == 0
            ? null
            : () => setState(() => _step -= 1),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : details.onStepContinue,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_step == 4 ? Icons.note_add : Icons.arrow_forward),
                  label: Text(
                    _step == 4
                        ? 'Verified chronology থেকে CD-I তৈরি করুন'
                        : 'পরবর্তী প্রশ্ন',
                  ),
                ),
              ),
              if (_step > 0) ...<Widget>[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: details.onStepCancel,
                  child: const Text('পেছনে'),
                ),
              ],
            ],
          ),
        ),
        steps: <Step>[
          Step(
            title: const Text('FIR ও তদন্তভার'),
            isActive: _step >= 0,
            content: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(widget.caseFile.displayTitle),
                  subtitle: Text('CD-I-এর তারিখ: $_caseDate'),
                ),
                _timeField(
                  _takingUpTime,
                  'FIR/Case Papers গ্রহণ ও তদন্তভার গ্রহণের সময়',
                ),
                const SizedBox(height: 10),
                _timeField(_departureTime, 'PS থেকে রওনার সময়'),
                const SizedBox(height: 10),
                _textField(
                  _departurePurpose,
                  'রওনার উদ্দেশ্য',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          Step(
            title: const Text('PO Visit ও Sketch Map'),
            isActive: _step >= 1,
            content: Column(
              children: <Widget>[
                _timeField(_poArrivalTime, 'PO-তে পৌঁছানোর সময়'),
                const SizedBox(height: 10),
                _textField(
                  _poDetails,
                  'PO-এর সঠিক অবস্থান ও চারদিকের বিবরণ',
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                _textField(
                  _poObservation,
                  'PO-তে দেখা গুরুত্বপূর্ণ বিষয় ও observations',
                  maxLines: 5,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _sketchPrepared,
                  onChanged: (value) =>
                      setState(() => _sketchPrepared = value),
                  title: const Text('Rough Sketch Map প্রস্তুত করবেন'),
                ),
                if (_sketchPrepared)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openSketchMap,
                      icon: const Icon(Icons.map),
                      label: const Text('Sketch Map portal খুলুন'),
                    ),
                  )
                else
                  _textField(
                    _sketchReason,
                    'Sketch Map প্রস্তুত না করার কারণ',
                    maxLines: 3,
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('অভিযোগকারী ও সাক্ষী'),
            isActive: _step >= 2,
            content: Column(
              children: <Widget>[
                if (widget.caseFile.complainantName.trim().isNotEmpty) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person),
                    title: const Text('অভিযোগকারী'),
                    subtitle: Text(widget.caseFile.complainantName),
                  ),
                  _timeField(
                    _complainantTime,
                    'অভিযোগকারী পরীক্ষার সময়',
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    _complainantStatement,
                    'অভিযোগকারী কী জানিয়েছেন',
                    maxLines: 5,
                  ),
                ] else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Case Form-এ অভিযোগকারীর নাম নেই। Case particulars review করুন।',
                      ),
                    ),
                  ),
                const Divider(height: 28),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _noWitnessAvailable,
                  onChanged: (value) => setState(() {
                    _noWitnessAvailable = value ?? false;
                    if (_noWitnessAvailable) _witnesses.clear();
                  }),
                  title: const Text('প্রাথমিক সাক্ষী পাওয়া যায়নি'),
                ),
                if (_noWitnessAvailable)
                  _textField(
                    _noWitnessReason,
                    'সাক্ষী না পাওয়ার কারণ/অনুসন্ধানের ফল',
                    maxLines: 3,
                  )
                else ...<Widget>[
                  ..._witnesses.asMap().entries.map(
                        (entry) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${entry.key + 1}'),
                            ),
                            title: Text(entry.value.identity),
                            subtitle: Text(
                              '${entry.value.time}\n${entry.value.statement}',
                              maxLines: 4,
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              onPressed: () => setState(
                                () => _witnesses.removeAt(entry.key),
                              ),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        ),
                      ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addWitness,
                      icon: const Icon(Icons.person_add),
                      label: const Text('প্রাথমিক সাক্ষী যোগ করুন'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('Seizure, Medical ও Evidence'),
            isActive: _step >= 3,
            content: Column(
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _seizureApplicable,
                  onChanged: (value) =>
                      setState(() => _seizureApplicable = value),
                  title: const Text('First CD-তে কোনো জব্দ হয়েছে'),
                ),
                if (_seizureApplicable) ...<Widget>[
                  _timeField(_seizureTime, 'জব্দের সময়'),
                  const SizedBox(height: 10),
                  _textField(
                    _seizedArticle,
                    'জব্দ করা বস্তু/নথির সম্পূর্ণ বিবরণ',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  _textField(_seizedFrom, 'কার কাছ থেকে/কোথা থেকে জব্দ'),
                  const SizedBox(height: 10),
                  _textField(_seizureWitness, 'জব্দ সাক্ষীদের নাম'),
                  const SizedBox(height: 10),
                  _textField(
                    _seizureReference,
                    'Seizure List-এর সময়/তারিখ/reference',
                  ),
                ],
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _medicalApplicable,
                  onChanged: (value) =>
                      setState(() => _medicalApplicable = value),
                  title: const Text('Medical action প্রযোজ্য'),
                ),
                if (_medicalApplicable) ...<Widget>[
                  _timeField(_medicalTime, 'Medical action-এর সময়'),
                  const SizedBox(height: 10),
                  _textField(_medicalPerson, 'কার medical examination'),
                  const SizedBox(height: 10),
                  _textField(
                    _medicalFacility,
                    'Hospital/Medical Officer',
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    _medicalResult,
                    'Requisition/report/treatment status',
                    maxLines: 3,
                  ),
                ],
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _evidenceApplicable,
                  onChanged: (value) =>
                      setState(() => _evidenceApplicable = value),
                  title: const Text('অন্য Evidence সংগ্রহ/সংরক্ষণ হয়েছে'),
                ),
                if (_evidenceApplicable) ...<Widget>[
                  _timeField(_evidenceTime, 'Evidence collection-এর সময়'),
                  const SizedBox(height: 10),
                  _textField(
                    _evidenceDescription,
                    'Evidence-এর পূর্ণ বিবরণ',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  _textField(_evidenceSource, 'Evidence-এর উৎস/স্থান'),
                  const SizedBox(height: 10),
                  _textField(
                    _evidencePreservation,
                    'কীভাবে সংরক্ষণ/প্যাকেটবন্দি করেছেন',
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text('Return, ভাষা ও Review'),
            isActive: _step >= 4,
            content: Column(
              children: <Widget>[
                _timeField(
                  _returnTime,
                  'PS return/দিনের কাজ বন্ধের সময়',
                ),
                const SizedBox(height: 10),
                _textField(
                  _returnStatus,
                  'ফেরার পর নথি/আলামত জমা ও দিনের closure details',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DocumentLanguage>(
                  value: _language,
                  decoration: const InputDecoration(
                    labelText: 'CD-I-এর document language',
                    border: OutlineInputBorder(),
                  ),
                  items: DocumentLanguage.values
                      .map(
                        (item) => DropdownMenuItem<DocumentLanguage>(
                          value: item,
                          child: Text(item.displayLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _language = value ?? DocumentLanguage.bangla,
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Final button চাপলে chronology validation হবে। একই তথ্য '
                      'আগে থাকলে duplicate save হবে না। CD editor খুলে Officer '
                      'review করার আগে document Final হবে না।',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WitnessDraft {
  final String time;
  final String identity;
  final String statement;

  const _WitnessDraft({
    required this.time,
    required this.identity,
    required this.statement,
  });
}
