import '../core/document_language.dart';
import '../models/guided_daily_entry.dart';
import 'daily_narration_service.dart';

class GuidedQuestion {
  final String id;
  final String actionId;
  final String fieldKey;
  final String promptBangla;
  final String promptEnglish;
  final List<String> options;
  final bool required;

  const GuidedQuestion({
    required this.id,
    required this.actionId,
    required this.fieldKey,
    required this.promptBangla,
    required this.promptEnglish,
    this.options = const <String>[],
    this.required = true,
  });

  String prompt(String languageCode) =>
      languageCode == 'en' ? promptEnglish : promptBangla;
}

class GuidedQuestionEngine {
  final DailyNarrationService _narrationService = DailyNarrationService();

  List<GuidedAction> analyse(
    String narration,
    DailyEntrySource source,
  ) {
    final detected = _narrationService.analyse(narration);
    if (detected.isEmpty && narration.trim().isNotEmpty) {
      return <GuidedAction>[
        GuidedAction(
          id: 'guided_action_${DateTime.now().microsecondsSinceEpoch}',
          type: source == DailyEntrySource.evidence
              ? 'evidence_collection'
              : 'other',
          time: '',
          place: '',
          details: narration.trim(),
          sequence: 0,
        ),
      ];
    }
    return detected
        .map((item) => GuidedAction(
              id: item.id,
              type: item.type,
              time: item.time,
              place: item.place,
              details: item.details.trim().isEmpty
                  ? item.sourceSentence.trim()
                  : item.details.trim(),
              sequence: item.order,
            ))
        .toList();
  }

  GuidedQuestion? nextQuestion(
    List<GuidedAction> actions,
    DailyEntrySource source,
  ) {
    for (final action in actions.where((item) => item.includeInCd)) {
      final questions = questionsForAction(action, source);
      for (final question in questions) {
        final answer = action.answers[question.fieldKey]?.trim() ?? '';
        if (answer.isEmpty) return question;
      }
    }
    return null;
  }

  List<GuidedQuestion> questionsForAction(
    GuidedAction action,
    DailyEntrySource source,
  ) {
    final questions = <GuidedQuestion>[];
    void add(
      String key,
      String bn,
      String en, {
      List<String> options = const <String>[],
      bool required = true,
    }) {
      questions.add(GuidedQuestion(
        id: '${action.id}_$key',
        actionId: action.id,
        fieldKey: key,
        promptBangla: bn,
        promptEnglish: en,
        options: options,
        required: required,
      ));
    }

    if (action.time.trim().isEmpty) {
      add('time', 'এই কাজটি কখন করেছেন?', 'At what time was this action done?');
    }

    final needsPlace = <String>{
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
    }.contains(action.type);
    if (needsPlace && action.place.trim().isEmpty) {
      add('place', 'কাজটি কোথায় করেছেন?', 'Where was the action done?');
    }

    switch (action.type) {
      case 'departure':
        add('purpose', 'থানা থেকে রওনা হওয়ার উদ্দেশ্য কী ছিল?',
            'What was the purpose of departure from the Police Station?');
        break;
      case 'po_visit':
        add('po_observation',
            'ঘটনাস্থল পরিদর্শনে কী কী গুরুত্বপূর্ণ বিষয় দেখেছেন?',
            'What material features or observations were noticed at the place of occurrence?');
        break;
      case 'complainant_examination':
        add('person_identity', 'অভিযোগকারীর নাম ও পরিচয় লিখুন।',
            'Enter the complainant’s name and identity.');
        add('statement_substance',
            'অভিযোগকারী সংক্ষেপে কী জানিয়েছেন?',
            'What did the complainant state in substance?');
        break;
      case 'witness_examination':
        add('person_identity', 'সাক্ষীর নাম, পিতৃপরিচয় ও ঠিকানা লিখুন।',
            'Enter the witness’s name, parentage and address.');
        add('statement_substance', 'সাক্ষী সংক্ষেপে কী জানিয়েছেন?',
            'What did the witness state in substance?');
        add('statement_recorded', '১৮০ BNSS অনুযায়ী বক্তব্য লিপিবদ্ধ করেছেন?',
            'Was the statement recorded under section 180 BNSS?',
            options: const <String>['হ্যাঁ', 'না']);
        break;
      case 'search':
        add('search_target', 'কোন স্থান/ব্যক্তি/বস্তু তল্লাশি করেছেন?',
            'What place, person or object was searched?');
        add('search_result', 'তল্লাশির ফলাফল কী ছিল?',
            'What was the result of the search?');
        add('search_witness', 'তল্লাশির সাক্ষী কারা ছিলেন?',
            'Who witnessed the search?');
        break;
      case 'seizure':
        add('article_description',
            'জব্দ করা বস্তু/নথির সম্পূর্ণ বিবরণ লিখুন।',
            'Enter the complete description of the seized article/document.');
        add('seized_from', 'কার কাছ থেকে বা কোথা থেকে জব্দ করেছেন?',
            'From whom or from where was it seized?');
        add('seizure_witness', 'জব্দ সাক্ষীদের নাম লিখুন।',
            'Enter the names of seizure witnesses.');
        add('seizure_list', 'Seizure List প্রস্তুত করেছেন?',
            'Was a seizure list prepared?',
            options: const <String>['হ্যাঁ', 'না']);
        if (_isYes(action.answers['seizure_list'])) {
          add('seizure_reference',
              'Seizure List-এর তারিখ/সময় বা রেফারেন্স লিখুন।',
              'Enter the date/time or reference of the seizure list.');
        }
        break;
      case 'evidence_collection':
        add('evidence_category', 'এটি কোন ধরনের Evidence?',
            'What category of evidence is this?',
            options: const <String>[
              'Physical',
              'Digital',
              'Documentary',
              'Medical',
              'Other'
            ]);
        add('evidence_description', 'Evidence-এর পূর্ণ বিবরণ লিখুন।',
            'Enter the complete description of the evidence.');
        add('evidence_source', 'Evidence কোথা থেকে/কার কাছ থেকে পাওয়া গেছে?',
            'From where or from whom was the evidence obtained?');
        add('preservation', 'Evidence কীভাবে সংরক্ষণ/প্যাকেটবন্দি করেছেন?',
            'How was the evidence preserved or packed?');
        if ((action.answers['evidence_category'] ?? '') == 'Digital') {
          add('digital_identifier',
              'ডিভাইস/ফাইলের IMEI, serial, file name বা অন্য identifier লিখুন।',
              'Enter the IMEI, serial number, file name or other identifier.');
          add('hash_status', 'SHA-256 hash তৈরি করেছেন?',
              'Was a SHA-256 hash generated?',
              options: const <String>['হ্যাঁ', 'না', 'প্রযোজ্য নয়']);
          if (_isYes(action.answers['hash_status'])) {
            add('hash_value', 'SHA-256 hash value লিখুন।',
                'Enter the SHA-256 hash value.');
          }
        }
        break;
      case 'arrest':
        add('accused_identity', 'গ্রেপ্তার ব্যক্তির নাম ও পরিচয় লিখুন।',
            'Enter the arrested person’s name and identity.');
        add('arrest_ground', 'গ্রেপ্তারের কারণ/ভিত্তি লিখুন।',
            'Enter the grounds/basis of arrest.');
        add('arrest_compliance',
            'Arrest Memo, information to nominated person ও medical formalities-এর অবস্থা লিখুন।',
            'State the status of arrest memo, information to nominated person and medical formalities.');
        break;
      case 'medical':
        add('person_identity', 'কার medical examination/treatment হয়েছে?',
            'Whose medical examination or treatment was conducted?');
        add('medical_facility', 'কোন হাসপাতাল/চিকিৎসকের কাছে পাঠানো হয়েছিল?',
            'To which hospital or medical officer was the person sent?');
        add('medical_result', 'Requisition/report/treatment-এর অবস্থা লিখুন।',
            'State the status of requisition, report or treatment.');
        break;
      case 'court':
        add('court_action', 'কোন আদালতে কী কাজ করেছেন?',
            'What action was taken before which Court?');
        break;
      case 'requisition':
        add('requisition_details',
            'কোন কর্তৃপক্ষকে কী উদ্দেশ্যে requisition পাঠিয়েছেন?',
            'To which authority and for what purpose was the requisition sent?');
        break;
      case 'local_enquiry':
        add('enquiry_persons', 'স্থানীয় অনুসন্ধানে কাদের সঙ্গে কথা বলেছেন?',
            'Whom did you speak to during local enquiry?');
        add('enquiry_result', 'স্থানীয় অনুসন্ধানে কী জানা গেল?',
            'What was learnt during local enquiry?');
        break;
      case 'return_ps':
        add('return_status', 'থানায় ফিরে কী কী মালামাল/নথি জমা বা সংরক্ষণ করেছেন?',
            'What articles or documents were deposited or secured after return to the Police Station?',
            required: false);
        break;
      case 'sketch_map':
        add('sketch_reference', 'Sketch Map-এর সংক্ষিপ্ত রেফারেন্স লিখুন।',
            'Enter a brief reference to the sketch map.');
        break;
      default:
        if (source == DailyEntrySource.evidence) {
          add('evidence_description', 'Evidence সংক্রান্ত কাজটি বিস্তারিত লিখুন।',
              'Describe the evidence-related action in detail.');
        } else {
          add('official_details', 'তদন্তের কাজটি বিস্তারিত লিখুন।',
              'Describe the investigation action in detail.');
        }
    }
    return questions;
  }

  GuidedAction applyAnswer(
    GuidedAction action,
    GuidedQuestion question,
    String answer,
  ) {
    final cleaned = answer.trim();
    final updatedAnswers = Map<String, String>.from(action.answers)
      ..[question.fieldKey] = cleaned;
    if (question.fieldKey == 'time') {
      return action.copyWith(time: cleaned, answers: updatedAnswers);
    }
    if (question.fieldKey == 'place') {
      return action.copyWith(place: cleaned, answers: updatedAnswers);
    }
    return action.copyWith(answers: updatedAnswers);
  }

  String factSummary(GuidedAction action) {
    final parts = <String>[];
    final original = action.details.trim();
    if (original.isNotEmpty) parts.add(original);
    for (final entry in action.answers.entries) {
      if (<String>{'time', 'place', 'sketch_map_decision'}.contains(entry.key)) {
        continue;
      }
      final value = entry.value.trim();
      if (value.isNotEmpty) parts.add(value);
    }
    return parts.toSet().join(' ');
  }

  String synopsis(GuidedAction action, DocumentLanguage language) {
    const bn = <String, String>{
      'departure': 'থানা থেকে রওনা',
      'po_visit': 'ঘটনাস্থল পরিদর্শন',
      'sketch_map': 'খসড়া নকশা প্রস্তুত',
      'complainant_examination': 'অভিযোগকারী পরীক্ষা',
      'witness_examination': 'সাক্ষী পরীক্ষা',
      'search': 'তল্লাশি',
      'seizure': 'জব্দ',
      'arrest': 'গ্রেপ্তার',
      'medical': 'চিকিৎসা সংক্রান্ত কার্যক্রম',
      'court': 'আদালত সংক্রান্ত কার্যক্রম',
      'requisition': 'Requisition প্রেরণ',
      'local_enquiry': 'স্থানীয় অনুসন্ধান',
      'evidence_collection': 'Evidence সংগ্রহ/সংরক্ষণ',
      'return_ps': 'থানায় প্রত্যাবর্তন',
      'other': 'পরবর্তী তদন্ত',
    };
    const en = <String, String>{
      'departure': 'Departure from Police Station',
      'po_visit': 'Visit and inspection of place of occurrence',
      'sketch_map': 'Preparation of rough sketch map',
      'complainant_examination': 'Examination of complainant',
      'witness_examination': 'Examination of witness',
      'search': 'Search conducted',
      'seizure': 'Seizure of article/evidence',
      'arrest': 'Arrest of accused',
      'medical': 'Medical-related action',
      'court': 'Court-related action',
      'requisition': 'Requisition sent',
      'local_enquiry': 'Local enquiry',
      'evidence_collection': 'Collection/preservation of evidence',
      'return_ps': 'Return to Police Station',
      'other': 'Further investigation',
    };
    return language.isBangla
        ? (bn[action.type] ?? bn['other']!)
        : (en[action.type] ?? en['other']!);
  }

  String officialProceeding({
    required GuidedAction action,
    required DocumentLanguage language,
    required String translatedFacts,
  }) {
    final timePart = action.time.trim().isEmpty
        ? ''
        : language.isBangla
            ? '${action.time.trim()} ঘটিকায় '
            : 'At ${action.time.trim()} hrs, ';
    final place = action.place.trim();
    final facts = translatedFacts.trim();
    String appendFacts() {
      if (facts.isEmpty) return '';
      return language.isBangla ? ' বিবরণ: $facts' : ' Details: $facts';
    }

    if (language.isBangla) {
      switch (action.type) {
        case 'departure':
          return '${timePart}মামলার তদন্তের স্বার্থে ${place.isEmpty ? 'থানা' : place} থেকে রওনা হলাম।${appendFacts()}';
        case 'po_visit':
          return '${timePart}${place.isEmpty ? 'ঘটনাস্থলে' : '$place-এ'} উপস্থিত হয়ে ঘটনাস্থল পরিদর্শন করলাম।${appendFacts()}';
        case 'sketch_map':
          return '${timePart}ঘটনাস্থলের অবস্থান ও পারিপার্শ্বিকতা প্রদর্শন করে সূচিসহ খসড়া নকশা প্রস্তুত করলাম।${appendFacts()}';
        case 'complainant_examination':
          return '${timePart}অভিযোগকারীকে পরীক্ষা করলাম।${appendFacts()}';
        case 'witness_examination':
          return '${timePart}সাক্ষীকে পরীক্ষা করলাম।${appendFacts()}';
        case 'search':
          return '${timePart}${place.isEmpty ? 'সংশ্লিষ্ট স্থানে' : '$place-এ'} তল্লাশি কার্যক্রম পরিচালনা করলাম।${appendFacts()}';
        case 'seizure':
          return '${timePart}${place.isEmpty ? 'সংশ্লিষ্ট স্থান থেকে' : '$place থেকে'} বর্ণিত বস্তু/নথি জব্দ করলাম।${appendFacts()}';
        case 'evidence_collection':
          return '${timePart}${place.isEmpty ? 'মামলার তদন্তকালে' : '$place-এ'} প্রাসঙ্গিক Evidence সংগ্রহ/সংরক্ষণ করলাম।${appendFacts()}';
        case 'arrest':
          return '${timePart}${place.isEmpty ? 'মামলার তদন্তকালে' : '$place-এ'} বর্ণিত ব্যক্তিকে গ্রেপ্তার করলাম।${appendFacts()}';
        case 'medical':
          return '${timePart}মামলার স্বার্থে প্রয়োজনীয় চিকিৎসা/medical examination সংক্রান্ত ব্যবস্থা গ্রহণ করলাম।${appendFacts()}';
        case 'court':
          return '${timePart}মামলা সংক্রান্ত প্রয়োজনীয় আদালতীয় কার্যক্রম সম্পন্ন করলাম।${appendFacts()}';
        case 'requisition':
          return '${timePart}মামলার তদন্তের স্বার্থে প্রয়োজনীয় requisition প্রেরণ করলাম।${appendFacts()}';
        case 'local_enquiry':
          return '${timePart}${place.isEmpty ? 'সংশ্লিষ্ট এলাকায়' : '$place-এ'} স্থানীয় অনুসন্ধান পরিচালনা করলাম।${appendFacts()}';
        case 'return_ps':
          return '${timePart}তদন্তমূলক কার্যক্রম শেষে থানায় প্রত্যাবর্তন করলাম।${appendFacts()}';
        default:
          return '${timePart}মামলার পরবর্তী তদন্তমূলক কার্যক্রম সম্পন্ন করলাম।${appendFacts()}';
      }
    }

    switch (action.type) {
      case 'departure':
        return '${timePart}I left ${place.isEmpty ? 'the Police Station' : place} in connection with the investigation of the case.${appendFacts()}';
      case 'po_visit':
        return '${timePart}I arrived at and inspected ${place.isEmpty ? 'the place of occurrence' : place}.${appendFacts()}';
      case 'sketch_map':
        return '${timePart}I prepared the rough sketch map with index showing the place of occurrence and its surroundings.${appendFacts()}';
      case 'complainant_examination':
        return '${timePart}I examined the complainant.${appendFacts()}';
      case 'witness_examination':
        return '${timePart}I examined the witness.${appendFacts()}';
      case 'search':
        return '${timePart}I conducted search at ${place.isEmpty ? 'the relevant place' : place}.${appendFacts()}';
      case 'seizure':
        return '${timePart}I seized the described article/document ${place.isEmpty ? '' : 'from $place'}.${appendFacts()}';
      case 'evidence_collection':
        return '${timePart}I collected/preserved relevant evidence ${place.isEmpty ? '' : 'at $place'}.${appendFacts()}';
      case 'arrest':
        return '${timePart}I arrested the described person ${place.isEmpty ? '' : 'at $place'}.${appendFacts()}';
      case 'medical':
        return '${timePart}I took the necessary steps relating to medical examination/treatment for the purpose of investigation.${appendFacts()}';
      case 'court':
        return '${timePart}I completed the necessary Court-related action in connection with the case.${appendFacts()}';
      case 'requisition':
        return '${timePart}I sent the necessary requisition for the purpose of investigation.${appendFacts()}';
      case 'local_enquiry':
        return '${timePart}I conducted local enquiry ${place.isEmpty ? '' : 'at $place'}.${appendFacts()}';
      case 'return_ps':
        return '${timePart}I returned to the Police Station after completing the investigation-related action.${appendFacts()}';
      default:
        return '${timePart}I carried out further investigation of the case.${appendFacts()}';
    }
  }

  List<GuidedAction> deduplicateAndSort(List<GuidedAction> input) {
    final result = <GuidedAction>[];
    final seen = <String>{};
    for (final action in input.where((item) => item.includeInCd)) {
      final detailKey = factSummary(action)
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final compactDetail = detailKey.length > 120
          ? detailKey.substring(0, 120)
          : detailKey;
      final key = <String>[
        action.type,
        action.time.trim().toLowerCase(),
        action.place.trim().toLowerCase(),
        compactDetail,
      ].join('|');
      if (seen.add(key)) result.add(action);
    }
    result.sort((a, b) {
      final timeCompare = _timeValue(a.time).compareTo(_timeValue(b.time));
      return timeCompare != 0
          ? timeCompare
          : a.sequence.compareTo(b.sequence);
    });
    return result;
  }

  int _timeValue(String value) {
    final normalized = value
        .replaceAll('ঘটিকা', '')
        .replaceAll('ঘণ্টা', '')
        .replaceAll('hrs', '')
        .trim();
    final match = RegExp(r'(\d{1,2})\s*[:.]\s*(\d{2})').firstMatch(normalized);
    if (match != null) {
      return (int.tryParse(match.group(1)!) ?? 99) * 60 +
          (int.tryParse(match.group(2)!) ?? 0);
    }
    final hourOnly = RegExp(r'\b(\d{1,2})\b').firstMatch(normalized);
    if (hourOnly != null) {
      return (int.tryParse(hourOnly.group(1)!) ?? 99) * 60;
    }
    return 99999;
  }

  static bool _isYes(String? value) {
    final text = (value ?? '').trim().toLowerCase();
    return text == 'হ্যাঁ' || text == 'হ্যা' || text == 'yes' || text == 'y';
  }
}
