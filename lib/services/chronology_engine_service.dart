import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/case_chronology.dart';
import '../models/case_file.dart';
import '../models/guided_daily_entry.dart';
import 'guided_daily_entry_store.dart';
import 'guided_question_engine.dart';
import 'local_store_service.dart';

class ChronologyEngineService {
  static const String _storageKey = 'case_chronology_events_v1';

  final GuidedDailyEntryStore _entryStore = GuidedDailyEntryStore();
  final GuidedQuestionEngine _questionEngine = GuidedQuestionEngine();
  final LocalStoreService _localStore = LocalStoreService();

  Future<List<ChronologyEvent>> _loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return <ChronologyEvent>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <ChronologyEvent>[];
      return decoded
          .whereType<Map>()
          .map((item) => ChronologyEvent.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (_) {
      return <ChronologyEvent>[];
    }
  }

  Future<void> _saveAll(List<ChronologyEvent> events) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(events.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<ChronologyEvent>> loadForCase(String caseId) async {
    final events = (await _loadAll())
        .where((item) => item.caseId == caseId)
        .toList();
    events.sort(_compareEvents);
    return events;
  }

  Future<ChronologyAssessment> assessEntry(GuidedDailyEntry entry) async {
    final all = await _loadAll();
    final caseEvents =
        all.where((item) => item.caseId == entry.caseId).toList();
    final acceptedActions = <GuidedAction>[];
    final acceptedEvents = <ChronologyEvent>[];
    final exactDuplicates = <ChronologyEvent>[];
    final supplementaryParents = <ChronologyEvent>[];

    for (final action in entry.actions.where((item) => item.includeInCd)) {
      final candidate = _eventFromAction(entry, action);
      final sameSource = caseEvents.where(
        (item) =>
            item.sourceEntryId == entry.id &&
            item.sourceActionId == action.id,
      );
      if (sameSource.isNotEmpty) {
        acceptedActions.add(action);
        acceptedEvents.add(candidate.copyWith(
          status: sameSource.first.status,
          parentEventId: sameSource.first.parentEventId,
        ));
        continue;
      }

      final exact = caseEvents.where(
        (item) => item.fingerprint == candidate.fingerprint,
      );
      if (exact.isNotEmpty) {
        exactDuplicates.add(exact.first);
        continue;
      }

      final candidateRelation = candidate.entityKey.isNotEmpty
          ? candidate.entityKey
          : _normalize(candidate.place);
      final related = caseEvents.where((item) {
        final existingRelation = item.entityKey.isNotEmpty
            ? item.entityKey
            : _normalize(item.place);
        return item.type == candidate.type &&
            candidateRelation.isNotEmpty &&
            existingRelation == candidateRelation;
      });
      if (related.isNotEmpty) {
        final parent = related.last;
        supplementaryParents.add(parent);
        acceptedActions.add(action);
        acceptedEvents.add(candidate.copyWith(
          status: ChronologyEventStatus.supplementary,
          parentEventId: parent.id,
        ));
      } else {
        acceptedActions.add(action);
        acceptedEvents.add(candidate);
      }
    }

    return ChronologyAssessment(
      acceptedActions: acceptedActions,
      acceptedEvents: acceptedEvents,
      exactDuplicates: exactDuplicates,
      supplementaryParents: supplementaryParents,
    );
  }

  Future<void> commitEntry(
    GuidedDailyEntry entry,
    ChronologyAssessment assessment,
  ) async {
    final all = await _loadAll();
    all.removeWhere((item) => item.sourceEntryId == entry.id);
    all.addAll(assessment.acceptedEvents);
    await _saveAll(all);
  }

  Future<void> syncCase(String caseId) async {
    final entries = await _entryStore.loadForCase(caseId);
    final all = await _loadAll();
    final retained =
        all.where((item) => item.caseId != caseId).toList();

    final rebuilt = <ChronologyEvent>[];
    for (final entry in entries) {
      for (final action in entry.actions.where((item) => item.includeInCd)) {
        final candidate = _eventFromAction(entry, action);
        final exact = rebuilt.where(
          (item) => item.fingerprint == candidate.fingerprint,
        );
        if (exact.isNotEmpty) continue;

        final candidateRelation = candidate.entityKey.isNotEmpty
            ? candidate.entityKey
            : _normalize(candidate.place);
        final related = rebuilt.where((item) {
          final existingRelation = item.entityKey.isNotEmpty
              ? item.entityKey
              : _normalize(item.place);
          return item.type == candidate.type &&
              candidateRelation.isNotEmpty &&
              existingRelation == candidateRelation;
        });
        rebuilt.add(
          related.isEmpty
              ? candidate
              : candidate.copyWith(
                  status: ChronologyEventStatus.supplementary,
                  parentEventId: related.last.id,
                ),
        );
      }
    }

    retained.addAll(rebuilt);
    await _saveAll(retained);
  }

  Future<CaseChronologySnapshot> buildSnapshot(CaseFile caseFile) async {
    await syncCase(caseFile.id);
    final events = await loadForCase(caseFile.id);
    final statements = await _localStore.loadStatements(caseFile.id);
    final forms = await _localStore.loadForms(caseFile.id);
    final sketchMap = await _localStore.loadSketchMap(caseFile.id);
    final cds = await _localStore.loadCds(caseFile.id);

    bool hasType(String type) => events.any((item) => item.type == type);
    ChronologyEvent? firstType(String type) {
      for (final event in events) {
        if (event.type == type) return event;
      }
      return null;
    }

    String referenceFor(String type) {
      final event = firstType(type);
      if (event == null) return '';
      final time = event.time.trim().isEmpty ? '' : ' ${event.time}';
      return '${event.actionDate}$time • ${event.sourceType}';
    }

    final sectionText = caseFile.sections.toLowerCase();
    final needsMedical = sectionText.contains('pocso') ||
        sectionText.contains('109') ||
        sectionText.contains('115') ||
        sectionText.contains('117') ||
        sectionText.contains('118');
    final propertyCase = sectionText.contains('303') ||
        sectionText.contains('305') ||
        sectionText.contains('309') ||
        sectionText.contains('310') ||
        sectionText.contains('317') ||
        sectionText.contains('318');

    final sketchNotApplicable = events.any(
      (item) =>
          item.type == 'sketch_map' &&
          (item.facts.contains('প্রস্তুত করা হয়নি') ||
              item.facts.toLowerCase().contains('not prepared')),
    );
    final witnessNotAvailable = events.any(
      (item) =>
          item.type == 'witness_examination' &&
          (item.facts.contains('পাওয়া যায়নি') ||
              item.facts.toLowerCase().contains('not available')),
    );

    final checklist = <ChronologyChecklistItem>[
      _item(
        id: 'case_particulars',
        group: 'মামলার সূচনা',
        title: 'মামলার নম্বর, তারিখ, ধারা ও ঘটনার স্থান লিপিবদ্ধ',
        done: caseFile.psCaseNo.trim().isNotEmpty &&
            caseFile.caseDate.trim().isNotEmpty &&
            caseFile.sections.trim().isNotEmpty &&
            caseFile.placeOfOccurrence.trim().isNotEmpty,
        source: 'Case Form',
      ),
      _item(
        id: 'taking_up',
        group: 'মামলার সূচনা',
        title: 'FIR/Case Papers গ্রহণ ও তদন্তভার গ্রহণ',
        done: events.any(
          (item) =>
              item.type == 'taking_up_investigation' ||
              item.facts.toLowerCase().contains('taking up') ||
              item.facts.contains('তদন্তভার'),
        ),
        source: referenceFor('taking_up_investigation'),
      ),
      _item(
        id: 'departure',
        group: 'প্রথম সিডি',
        title: 'থানা থেকে রওনা',
        done: hasType('departure'),
        source: referenceFor('departure'),
      ),
      _item(
        id: 'po_visit',
        group: 'প্রথম সিডি',
        title: 'PO visit ও বিস্তারিত পর্যবেক্ষণ',
        done: hasType('po_visit'),
        source: referenceFor('po_visit'),
      ),
      _item(
        id: 'sketch_map',
        group: 'প্রথম সিডি',
        title: 'Rough Sketch Map প্রস্তুত/কারণসহ প্রযোজ্য নয়',
        done: hasType('sketch_map') || sketchMap != null,
        source: hasType('sketch_map')
            ? referenceFor('sketch_map')
            : (sketchMap == null ? '' : 'Saved Sketch Map'),
        notApplicable: sketchNotApplicable,
      ),
      _item(
        id: 'complainant',
        group: 'বিবৃতি',
        title: 'অভিযোগকারীর প্রাথমিক বয়ান',
        done: hasType('complainant_examination'),
        source: referenceFor('complainant_examination'),
      ),
      _item(
        id: 'witness',
        group: 'বিবৃতি',
        title: 'প্রাথমিক সাক্ষীর পরিচয় ও বয়ান/কারণসহ সাক্ষী অনুপলব্ধ',
        done: hasType('witness_examination') || statements.isNotEmpty,
        source: hasType('witness_examination')
            ? referenceFor('witness_examination')
            : (statements.isEmpty ? '' : '${statements.length} statement(s)'),
        notApplicable: witnessNotAvailable,
      ),
      _item(
        id: 'seizure',
        group: 'Evidence',
        title: propertyCase
            ? 'প্রাসঙ্গিক জব্দ/উদ্ধার ও seizure details'
            : 'প্রযোজ্য জব্দ/উদ্ধার যাচাই',
        done: hasType('seizure') || !propertyCase,
        source: referenceFor('seizure'),
        mandatory: propertyCase,
        notApplicable: !propertyCase,
      ),
      _item(
        id: 'evidence',
        group: 'Evidence',
        title: 'Physical/Digital/Documentary Evidence নথিভুক্ত',
        done: hasType('evidence_collection') || !propertyCase,
        source: referenceFor('evidence_collection'),
        mandatory: propertyCase,
        notApplicable: !propertyCase,
      ),
      _item(
        id: 'medical',
        group: 'Medical',
        title: 'Medical examination/report সংক্রান্ত ব্যবস্থা',
        done: hasType('medical') || !needsMedical,
        source: referenceFor('medical'),
        mandatory: needsMedical,
        notApplicable: !needsMedical,
      ),
      _item(
        id: 'forms',
        group: 'নথি ও প্রক্রিয়া',
        title: 'প্রয়োজনীয় Form/Notice/Requisition সংরক্ষিত',
        done: forms.isNotEmpty,
        source: forms.isEmpty ? '' : '${forms.length} form(s)/notice(s)',
        mandatory: false,
      ),
      _item(
        id: 'return',
        group: 'প্রথম সিডি',
        title: 'PS return/দিনের কাজ বন্ধের বিবরণ',
        done: hasType('return_ps'),
        source: referenceFor('return_ps'),
      ),
      _item(
        id: 'cd',
        group: 'নথি প্রস্তুতি',
        title: 'Chronology থেকে Case Diary প্রস্তুত',
        done: cds.isNotEmpty,
        source: cds.isEmpty ? '' : '${cds.length} unique date CD(s)',
      ),
    ];

    final issues = _buildIssues(events);
    final nextQuestion = _nextQuestion(checklist);
    final blockers = checklist
        .where((item) => item.mandatory && !item.isComplete)
        .map((item) => item.title)
        .toList();
    blockers.addAll(
      issues
          .where((item) => item.blocksFinalization)
          .map((item) => item.message),
    );

    final noVerificationPending = !events.any(
      (item) => item.status == ChronologyEventStatus.needsVerification,
    );
    final firstCdReady = <String>[
      'taking_up',
      'departure',
      'po_visit',
      'complainant',
      'witness',
      'return',
    ].every(
      (id) => checklist.firstWhere((item) => item.id == id).isComplete,
    );

    final hasWitness = hasType('witness_examination') || statements.isNotEmpty;
    final hasEvidence = hasType('evidence_collection') ||
        hasType('seizure') ||
        forms.isNotEmpty;
    final allMandatoryDone = checklist
        .where((item) => item.mandatory)
        .every((item) => item.isComplete);

    return CaseChronologySnapshot(
      events: events,
      checklist: checklist,
      issues: issues,
      nextQuestion: nextQuestion,
      readiness: DocumentReadiness(
        caseDiaryReady:
            firstCdReady && noVerificationPending && issues.isEmpty,
        memoOfEvidenceReady: hasEvidence && hasWitness && noVerificationPending,
        finalReportReady:
            allMandatoryDone && cds.isNotEmpty && issues.isEmpty,
        chargeSheetReady: allMandatoryDone &&
            cds.isNotEmpty &&
            hasWitness &&
            caseFile.accusedName.trim().isNotEmpty &&
            issues.isEmpty,
        blockers: blockers.toSet().toList(),
      ),
    );
  }

  ChronologyChecklistItem _item({
    required String id,
    required String group,
    required String title,
    required bool done,
    required String source,
    bool mandatory = true,
    bool notApplicable = false,
  }) {
    return ChronologyChecklistItem(
      id: id,
      group: group,
      title: title,
      state: notApplicable
          ? ChecklistState.notApplicable
          : done
              ? ChecklistState.done
              : ChecklistState.pending,
      sourceReference: source,
      mandatory: mandatory,
    );
  }

  List<ChronologyIssue> _buildIssues(List<ChronologyEvent> events) {
    final issues = <ChronologyIssue>[];
    for (final event in events) {
      if (event.time.trim().isEmpty) {
        issues.add(ChronologyIssue(
          code: 'missing_time_${event.id}',
          message: '${event.actionDate}: ${event.type}-এর সময় অনুপস্থিত।',
          blocksFinalization: true,
        ));
      }
      if (_needsPlace(event.type) && event.place.trim().isEmpty) {
        issues.add(ChronologyIssue(
          code: 'missing_place_${event.id}',
          message: '${event.actionDate}: ${event.type}-এর স্থান অনুপস্থিত।',
          blocksFinalization: true,
        ));
      }
    }

    final byDate = <String, List<ChronologyEvent>>{};
    for (final event in events) {
      byDate.putIfAbsent(event.actionDate, () => <ChronologyEvent>[]).add(event);
    }
    for (final entry in byDate.entries) {
      final departure = entry.value
          .where((item) => item.type == 'departure')
          .map((item) => _timeValue(item.time))
          .where((value) => value < 99999)
          .toList();
      final po = entry.value
          .where((item) => item.type == 'po_visit')
          .map((item) => _timeValue(item.time))
          .where((value) => value < 99999)
          .toList();
      if (departure.isNotEmpty &&
          po.isNotEmpty &&
          po.reduce((a, b) => a < b ? a : b) <
              departure.reduce((a, b) => a < b ? a : b)) {
        issues.add(ChronologyIssue(
          code: 'po_before_departure_${entry.key}',
          message:
              '${entry.key}: PO arrival time, PS departure-এর আগের সময় দেখাচ্ছে।',
          blocksFinalization: true,
        ));
      }
    }
    return issues;
  }

  String _nextQuestion(List<ChronologyChecklistItem> checklist) {
    final pending = checklist.where(
      (item) => item.mandatory && !item.isComplete,
    );
    if (pending.isEmpty) {
      return 'Mandatory chronology সম্পূর্ণ। নতুন তদন্তমূলক কাজ বা Evidence থাকলে তা লিখুন।';
    }
    final id = pending.first.id;
    const questions = <String, String>{
      'case_particulars':
          'মামলার নম্বর, তারিখ, ধারা এবং PO-এর তথ্য সম্পূর্ণ করুন।',
      'taking_up':
          'কখন FIR/Case Papers গ্রহণ করে মামলার তদন্তভার নিলেন?',
      'departure':
          'কখন, কোথা থেকে এবং কী উদ্দেশ্যে PO-এর দিকে রওনা হলেন?',
      'po_visit':
          'কখন PO-তে পৌঁছালেন এবং সেখানে কী কী গুরুত্বপূর্ণ বিষয় দেখলেন?',
      'sketch_map':
          'Rough Sketch Map তৈরি করেছেন? না হলে প্রযোজ্য নয় হওয়ার কারণ লিখুন।',
      'complainant':
          'অভিযোগকারী সংক্ষেপে কী জানিয়েছেন?',
      'witness':
          'প্রথম সাক্ষীর নাম, পরিচয়, ঠিকানা এবং বক্তব্যের সারাংশ কী?',
      'seizure':
          'কী বস্তু/নথি, কোথা থেকে, কার উপস্থিতিতে জব্দ করেছেন?',
      'evidence':
          'কী Evidence পাওয়া গেছে এবং কীভাবে সংরক্ষণ করেছেন?',
      'medical':
          'কার medical examination হয়েছে, কোথায় এবং report-এর অবস্থা কী?',
      'return':
          'কখন থানায় ফিরলেন এবং কী নথি/আলামত জমা বা সংরক্ষণ করলেন?',
      'cd':
          'Verified chronology থেকে এই দিনের Case Diary তৈরি করুন।',
    };
    return questions[id] ?? pending.first.title;
  }

  ChronologyEvent _eventFromAction(
    GuidedDailyEntry entry,
    GuidedAction action,
  ) {
    final facts = _questionEngine.factSummary(action).trim();
    final entity = _entityFor(action);
    final fingerprint = _fingerprint(
      entry.caseId,
      entry.actionDate,
      action.type,
      action.time,
      action.place,
      entity,
      facts,
    );
    final now = DateTime.now();
    return ChronologyEvent(
      id: 'chronology_${entry.id}_${action.id}',
      caseId: entry.caseId,
      actionDate: entry.actionDate,
      time: action.time.trim(),
      type: action.type,
      place: action.place.trim(),
      entityKey: entity,
      facts: facts,
      sourceType: entry.source.englishLabel,
      sourceEntryId: entry.id,
      sourceActionId: action.id,
      fingerprint: fingerprint,
      status: _isCompleteAction(action)
          ? ChronologyEventStatus.verified
          : ChronologyEventStatus.needsVerification,
      parentEventId: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  bool _isCompleteAction(GuidedAction action) {
    if (action.time.trim().isEmpty) return false;
    if (_needsPlace(action.type) && action.place.trim().isEmpty) return false;
    final questions = _questionEngine.questionsForAction(
      action,
      DailyEntrySource.investigation,
    );
    for (final question in questions.where((item) => item.required)) {
      final answer = action.answers[question.fieldKey]?.trim() ?? '';
      if (answer.isEmpty) return false;
    }
    return true;
  }

  String _entityFor(GuidedAction action) {
    const keys = <String>[
      'person_identity',
      'accused_identity',
      'article_description',
      'evidence_description',
      'search_target',
    ];
    for (final key in keys) {
      final value = action.answers[key]?.trim() ?? '';
      if (value.isNotEmpty) return _normalize(value);
    }
    return '';
  }

  String _fingerprint(
    String caseId,
    String _date,
    String type,
    String time,
    String place,
    String entity,
    String facts,
  ) {
    return <String>[
      caseId,
      type,
      _normalize(time),
      _normalize(place),
      entity,
      _normalize(facts),
    ].join('|');
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^A-Za-z0-9\u0980-\u09FF]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _needsPlace(String type) {
    return <String>{
      'po_visit',
      'search',
      'seizure',
      'arrest',
      'medical',
      'court',
      'local_enquiry',
      'evidence_collection',
      'witness_examination',
      'complainant_examination',
    }.contains(type);
  }

  int _compareEvents(ChronologyEvent a, ChronologyEvent b) {
    final date = a.actionDate.compareTo(b.actionDate);
    if (date != 0) return date;
    final time = _timeValue(a.time).compareTo(_timeValue(b.time));
    if (time != 0) return time;
    return a.createdAt.compareTo(b.createdAt);
  }

  int _timeValue(String value) {
    final normalized = value
        .replaceAll('ঘটিকা', '')
        .replaceAll('ঘণ্টা', '')
        .replaceAll('hrs', '')
        .trim();
    final match =
        RegExp(r'(\d{1,2})\s*[:.]\s*(\d{2})').firstMatch(normalized);
    if (match != null) {
      return (int.tryParse(match.group(1)!) ?? 99) * 60 +
          (int.tryParse(match.group(2)!) ?? 0);
    }
    return 99999;
  }
}
