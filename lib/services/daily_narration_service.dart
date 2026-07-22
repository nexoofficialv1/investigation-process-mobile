import '../core/document_language.dart';

class DetectedDailyAction {
  final String id;
  final String type;
  final String time;
  final String place;
  final String details;
  final String sourceSentence;
  final int order;
  final int witnessCount;
  final bool selected;
  final bool isRepeat;
  final String repeatReason;

  const DetectedDailyAction({
    required this.id,
    required this.type,
    required this.time,
    required this.place,
    required this.details,
    required this.sourceSentence,
    required this.order,
    this.witnessCount = 0,
    this.selected = true,
    this.isRepeat = false,
    this.repeatReason = '',
  });

  DetectedDailyAction copyWith({
    String? time,
    String? place,
    String? details,
    bool? selected,
    int? witnessCount,
    bool? isRepeat,
    String? repeatReason,
  }) {
    return DetectedDailyAction(
      id: id,
      type: type,
      time: time ?? this.time,
      place: place ?? this.place,
      details: details ?? this.details,
      sourceSentence: sourceSentence,
      order: order,
      witnessCount: witnessCount ?? this.witnessCount,
      selected: selected ?? this.selected,
      isRepeat: isRepeat ?? this.isRepeat,
      repeatReason: repeatReason ?? this.repeatReason,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'time': time,
        'place': place,
        'details': details,
        'sourceSentence': sourceSentence,
        'order': order,
        'witnessCount': witnessCount,
        'selected': selected,
        'isRepeat': isRepeat,
        'repeatReason': repeatReason,
      };
}

class DailyNarrationService {
  static const Map<String, String> _banglaDigits = <String, String>{
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };

  List<DetectedDailyAction> analyse(String narration) {
    final cleaned = narration.trim();
    if (cleaned.isEmpty) return <DetectedDailyAction>[];

    final sentences = cleaned
        .split(RegExp(r'[।.!?\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final actions = <DetectedDailyAction>[];
    var sequence = 0;

    for (final sentence in sentences) {
      final normalized = _normalize(sentence);
      final time = _extractTime(sentence);
      final place = _extractPlace(sentence, normalized);
      final types = _detectTypes(normalized);

      if (types.isEmpty) {
        actions.add(
          DetectedDailyAction(
            id: 'action_${DateTime.now().microsecondsSinceEpoch}_${sequence++}',
            type: 'other',
            time: time,
            place: place,
            details: sentence,
            sourceSentence: sentence,
            order: sequence,
          ),
        );
        continue;
      }

      for (final type in types) {
        actions.add(
          DetectedDailyAction(
            id: 'action_${DateTime.now().microsecondsSinceEpoch}_${sequence++}',
            type: type,
            time: time,
            place: _placeForType(type, place, normalized),
            details: sentence,
            sourceSentence: sentence,
            order: sequence,
            witnessCount: type == 'witness_examination'
                ? _extractWitnessCount(normalized)
                : 0,
          ),
        );
      }
    }

    return _deduplicate(actions);
  }

  String synopsis(String type, DocumentLanguage language) {
    final bangla = <String, String>{
      'departure': 'থানা থেকে রওনা',
      'po_visit': 'ঘটনাস্থলে উপস্থিতি ও পরিদর্শন',
      'sketch_map': 'খসড়া নকশা প্রস্তুত/সংশোধন',
      'complainant_examination': 'অভিযোগকারীকে জিজ্ঞাসাবাদ',
      'witness_examination': 'সাক্ষীকে জিজ্ঞাসাবাদ',
      'search': 'তল্লাশি পরিচালনা',
      'seizure': 'আলামত/বস্তু জব্দ',
      'arrest': 'অভিযুক্ত গ্রেপ্তার',
      'medical': 'চিকিৎসা/মেডিক্যাল সংক্রান্ত কার্যক্রম',
      'court': 'আদালত সংক্রান্ত কার্যক্রম',
      'requisition': 'রিকুইজিশন প্রেরণ',
      'local_enquiry': 'স্থানীয় অনুসন্ধান',
      'evidence_collection': 'প্রমাণ সংগ্রহ/সংরক্ষণ',
      'return_ps': 'থানায় প্রত্যাবর্তন',
      'other': 'অন্যান্য তদন্তমূলক কার্যক্রম',
    };

    final english = <String, String>{
      'departure': 'Departure from Police Station',
      'po_visit': 'Visit and inspection of place of occurrence',
      'sketch_map': 'Preparation/update of rough sketch map',
      'complainant_examination': 'Examination of complainant',
      'witness_examination': 'Examination of witness',
      'search': 'Conduct of search',
      'seizure': 'Seizure of article/evidence',
      'arrest': 'Arrest of accused',
      'medical': 'Medical-related action',
      'court': 'Court-related action',
      'requisition': 'Sending requisition',
      'local_enquiry': 'Local enquiry',
      'evidence_collection': 'Collection/preservation of evidence',
      'return_ps': 'Return to Police Station',
      'other': 'Other investigation action',
    };

    return language.isBangla
        ? (bangla[type] ?? bangla['other']!)
        : (english[type] ?? english['other']!);
  }

  String officialProceeding({
    required DetectedDailyAction action,
    required DocumentLanguage language,
    required String translatedDetails,
  }) {
    final detail = translatedDetails.trim();
    final timePart = action.time.trim().isEmpty
        ? ''
        : language.isBangla
            ? '${action.time.trim()} ঘটিকায় '
            : 'At ${action.time.trim()} hrs, ';
    final place = action.place.trim();

    if (language.isBangla) {
      switch (action.type) {
        case 'departure':
          return '${timePart}মামলার তদন্তের স্বার্থে ${place.isEmpty ? 'থানা' : place} থেকে রওনা হলাম।${_appendDetail(detail)}';
        case 'po_visit':
          return '${timePart}${place.isEmpty ? 'ঘটনাস্থলে' : '$place-এ'} উপস্থিত হয়ে স্থানটি পরিদর্শন করলাম এবং মামলার ঘটনার সঙ্গে সংশ্লিষ্ট বিষয়সমূহ পর্যবেক্ষণ করলাম।${_appendDetail(detail)}';
        case 'sketch_map':
          return '${timePart}ঘটনাস্থলের অবস্থান ও পারিপার্শ্বিকতা প্রদর্শন করে সূচিসহ খসড়া নকশা প্রস্তুত/সংশোধন করলাম।${_appendDetail(detail)}';
        case 'complainant_examination':
          return '${timePart}অভিযোগকারীকে পৃথকভাবে জিজ্ঞাসাবাদ করলাম এবং তাঁর বয়ান ধারা ১৮০ BNSS অনুসারে লিপিবদ্ধ করলাম।${_appendDetail(detail)}';
        case 'witness_examination':
          return '${timePart}সাক্ষী/সাক্ষীদের পৃথকভাবে জিজ্ঞাসাবাদ করলাম এবং তাঁদের বয়ান ধারা ১৮০ BNSS অনুসারে লিপিবদ্ধ করলাম।${_appendDetail(detail)}';
        case 'search':
          return '${timePart}${place.isEmpty ? 'সংশ্লিষ্ট স্থানে' : '$place-এ'} উপস্থিত হয়ে মামলার তদন্তের স্বার্থে তল্লাশি পরিচালনা করলাম।${_appendDetail(detail)}';
        case 'seizure':
          return '${timePart}তদন্তকালে পাওয়া প্রাসঙ্গিক বস্তু/আলামত যথাযথ জব্দ তালিকামূলে সাক্ষীদের উপস্থিতিতে জব্দ করলাম।${_appendDetail(detail)}';
        case 'arrest':
          return '${timePart}প্রাপ্ত তথ্য ও সাক্ষ্যপ্রমাণের ভিত্তিতে সংশ্লিষ্ট অভিযুক্তকে আইনানুগভাবে গ্রেপ্তার করলাম এবং গ্রেপ্তার-সংক্রান্ত বিধি অনুসরণ করলাম।${_appendDetail(detail)}';
        case 'medical':
          return '${timePart}মামলার তদন্তের স্বার্থে প্রয়োজনীয় চিকিৎসা/মেডিক্যাল সংক্রান্ত কার্যক্রম সম্পন্ন করলাম।${_appendDetail(detail)}';
        case 'court':
          return '${timePart}মামলার প্রয়োজনীয় প্রার্থনা/নথি মাননীয় আদালতে পেশ করলাম এবং আদেশ সংগ্রহের ব্যবস্থা নিলাম।${_appendDetail(detail)}';
        case 'requisition':
          return '${timePart}মামলার তদন্তের স্বার্থে সংশ্লিষ্ট কর্তৃপক্ষের নিকট প্রয়োজনীয় রিকুইজিশন প্রেরণ করলাম।${_appendDetail(detail)}';
        case 'local_enquiry':
          return '${timePart}${place.isEmpty ? 'এলাকায়' : '$place-এ'} স্থানীয় অনুসন্ধান পরিচালনা করে প্রাসঙ্গিক তথ্য সংগ্রহ করলাম।${_appendDetail(detail)}';
        case 'evidence_collection':
          return '${timePart}প্রাসঙ্গিক প্রমাণ/ডিজিটাল উপাদান সংগ্রহ ও সংরক্ষণের প্রয়োজনীয় ব্যবস্থা গ্রহণ করলাম।${_appendDetail(detail)}';
        case 'return_ps':
          return '${timePart}তদন্তমূলক কার্যক্রম সম্পন্ন করে থানায় প্রত্যাবর্তন করলাম এবং সংগৃহীত নথি/আলামত যথাযথভাবে সংরক্ষণের ব্যবস্থা নিলাম।${_appendDetail(detail)}';
        default:
          return detail.isEmpty
              ? 'মামলার তদন্তের স্বার্থে প্রয়োজনীয় কার্যক্রম গ্রহণ করলাম।'
              : detail;
      }
    }

    switch (action.type) {
      case 'departure':
        return '${timePart}I left ${place.isEmpty ? 'the Police Station' : place} in connection with the investigation of this case.${_appendDetail(detail)}';
      case 'po_visit':
        return '${timePart}I reached ${place.isEmpty ? 'the place of occurrence' : place}, inspected the place and observed the relevant circumstances of the case.${_appendDetail(detail)}';
      case 'sketch_map':
        return '${timePart}I prepared/updated a rough sketch map with index showing the place of occurrence and its surroundings.${_appendDetail(detail)}';
      case 'complainant_examination':
        return '${timePart}I examined the complainant separately and recorded the statement under Section 180 BNSS.${_appendDetail(detail)}';
      case 'witness_examination':
        return '${timePart}I examined the witness/witnesses separately and recorded their statements under Section 180 BNSS.${_appendDetail(detail)}';
      case 'search':
        return '${timePart}I reached ${place.isEmpty ? 'the relevant place' : place} and conducted a lawful search in connection with the investigation.${_appendDetail(detail)}';
      case 'seizure':
        return '${timePart}I seized the relevant article/evidence under a proper seizure list in the presence of witnesses.${_appendDetail(detail)}';
      case 'arrest':
        return '${timePart}On the basis of the materials collected, I lawfully arrested the concerned accused and complied with the arrest formalities.${_appendDetail(detail)}';
      case 'medical':
        return '${timePart}I completed the necessary medical-related action for the purpose of investigation.${_appendDetail(detail)}';
      case 'court':
        return '${timePart}I submitted the necessary prayer/document before the Learned Court and took steps for obtaining the order.${_appendDetail(detail)}';
      case 'requisition':
        return '${timePart}I sent the necessary requisition to the concerned authority for the purpose of investigation.${_appendDetail(detail)}';
      case 'local_enquiry':
        return '${timePart}I conducted local enquiry at ${place.isEmpty ? 'the locality' : place} and collected relevant information.${_appendDetail(detail)}';
      case 'evidence_collection':
        return '${timePart}I took necessary steps to collect and preserve the relevant evidence/digital material.${_appendDetail(detail)}';
      case 'return_ps':
        return '${timePart}After completion of the investigation-related activities, I returned to the Police Station and arranged proper custody of the collected documents/evidence.${_appendDetail(detail)}';
      default:
        return detail.isEmpty
            ? 'I took the necessary action in connection with the investigation of this case.'
            : detail;
    }
  }

  String _appendDetail(String detail) {
    if (detail.isEmpty) return '';
    return ' $detail';
  }

  List<String> _detectTypes(String normalized) {
    final types = <String>[];

    bool hasAny(List<String> terms) => terms.any(normalized.contains);

    if (hasAny(<String>['রওনা', 'থানা থেকে বের', 'left the police station', 'departed from'])) {
      types.add('departure');
    }
    if (hasAny(<String>['ঘটনাস্থল', 'place of occurrence', 'scene of crime']) &&
        hasAny(<String>['যাই', 'গিয়ে', 'পৌঁছে', 'পরিদর্শন', 'visit', 'reached', 'inspected'])) {
      types.add('po_visit');
    }
    if (hasAny(<String>['খসড়া নকশা', 'খসড়া নকশা', 'স্কেচ ম্যাপ', 'sketch map', 'rough sketch'])) {
      types.add('sketch_map');
    }
    if (hasAny(<String>['অভিযোগকারী', 'complainant']) &&
        hasAny(<String>['জিজ্ঞাসাবাদ', 'বয়ান', 'বয়ান', 'examined', 'statement'])) {
      types.add('complainant_examination');
    }
    if (hasAny(<String>['সাক্ষী', 'witness']) &&
        hasAny(<String>['জিজ্ঞাসাবাদ', 'বয়ান', 'বয়ান', 'examined', 'statement'])) {
      types.add('witness_examination');
    }
    if (hasAny(<String>['তল্লাশি', 'search', 'searched'])) {
      types.add('search');
    }
    if (hasAny(<String>['জব্দ', 'উদ্ধার', 'seiz', 'recovered'])) {
      types.add('seizure');
    }
    if (hasAny(<String>['গ্রেপ্তার', 'অ্যারেস্ট', 'arrest'])) {
      types.add('arrest');
    }
    if (hasAny(<String>['হাসপাতাল', 'চিকিৎসা', 'মেডিক্যাল', 'medical', 'hospital'])) {
      types.add('medical');
    }
    if (hasAny(<String>['আদালত', 'কোর্ট', 'court', 'magistrate'])) {
      types.add('court');
    }
    if (hasAny(<String>['রিকুইজিশন', 'requisition'])) {
      types.add('requisition');
    }
    if (hasAny(<String>['স্থানীয় অনুসন্ধান', 'স্থানীয় অনুসন্ধান', 'local enquiry', 'local inquiry'])) {
      types.add('local_enquiry');
    }
    if (hasAny(<String>['সিসিটিভি', 'ডিজিটাল প্রমাণ', 'ভিডিও', 'cctv', 'digital evidence', 'electronic evidence'])) {
      types.add('evidence_collection');
    }
    if (hasAny(<String>['থানায় ফিরে', 'থানায় ফিরে', 'প্রত্যাবর্তন', 'returned to the police station', 'returned to ps'])) {
      types.add('return_ps');
    }

    return types;
  }

  String _normalize(String value) {
    var normalized = value.toLowerCase();
    for (final entry in _banglaDigits.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized;
  }

  String _extractTime(String sentence) {
    final normalized = _normalize(sentence);
    final match = RegExp(
      r'(?:(সকাল|দুপুর|বিকাল|বিকেল|সন্ধ্যা|রাত|am|pm)\s*)?(\d{1,2})(?:[:.](\d{2}))?\s*(?:টা|ঘটিকা|hours?|hrs?)?',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match == null) return '';

    var hour = int.tryParse(match.group(2) ?? '') ?? 0;
    final minute = int.tryParse(match.group(3) ?? '0') ?? 0;
    final period = (match.group(1) ?? '').toLowerCase();

    if (<String>['বিকাল', 'বিকেল', 'সন্ধ্যা', 'রাত', 'pm'].contains(period) &&
        hour > 0 &&
        hour < 12) {
      hour += 12;
    }
    if (period == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return '';

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _extractPlace(String sentence, String normalized) {
    if (normalized.contains('ঘটনাস্থল') ||
        normalized.contains('place of occurrence') ||
        normalized.contains('scene of crime')) {
      return normalized.contains('ঘটনাস্থল')
          ? 'ঘটনাস্থল'
          : 'Place of occurrence';
    }
    if (normalized.contains('অভিযুক্তের বাড়ি') ||
        normalized.contains('অভিযুক্তের বাড়ি')) {
      return 'অভিযুক্তের বাড়ি';
    }
    if (normalized.contains('house of the accused')) {
      return 'House of the accused';
    }
    if (normalized.contains('থানা') || normalized.contains('police station')) {
      return normalized.contains('থানা') ? 'থানা' : 'Police Station';
    }
    if (normalized.contains('আদালত') || normalized.contains('court')) {
      return normalized.contains('আদালত') ? 'আদালত' : 'Court';
    }
    if (normalized.contains('হাসপাতাল') || normalized.contains('hospital')) {
      return normalized.contains('হাসপাতাল') ? 'হাসপাতাল' : 'Hospital';
    }

    final atMatch = RegExp(
      r'(?:at|to|from)\s+([a-z][a-z\s-]{2,40})',
      caseSensitive: false,
    ).firstMatch(sentence);
    return atMatch?.group(1)?.trim() ?? '';
  }

  String _placeForType(
    String type,
    String detectedPlace,
    String normalizedSentence,
  ) {
    if (type == 'departure' || type == 'return_ps') {
      if (normalizedSentence.contains('থানা')) return 'থানা';
      if (normalizedSentence.contains('police station') ||
          normalizedSentence.contains(' ps')) {
        return 'Police Station';
      }
      return detectedPlace.isEmpty ? 'থানা' : detectedPlace;
    }

    if (type == 'po_visit' ||
        type == 'sketch_map' ||
        type == 'complainant_examination' ||
        type == 'witness_examination') {
      if (normalizedSentence.contains('ঘটনাস্থল')) return 'ঘটনাস্থল';
      if (normalizedSentence.contains('place of occurrence') ||
          normalizedSentence.contains('scene of crime')) {
        return 'Place of occurrence';
      }
      return detectedPlace.isEmpty ? 'ঘটনাস্থল' : detectedPlace;
    }

    return detectedPlace;
  }

  int _extractWitnessCount(String normalized) {
    final direct = RegExp(r'(\d+)\s*(?:জন\s*)?সাক্ষী').firstMatch(normalized);
    if (direct != null) {
      return int.tryParse(direct.group(1) ?? '') ?? 1;
    }

    const words = <String, int>{
      'একজন সাক্ষী': 1,
      'দুইজন সাক্ষী': 2,
      'দুজন সাক্ষী': 2,
      'তিনজন সাক্ষী': 3,
      'চারজন সাক্ষী': 4,
      'পাঁচজন সাক্ষী': 5,
      'one witness': 1,
      'two witnesses': 2,
      'three witnesses': 3,
      'four witnesses': 4,
      'five witnesses': 5,
    };
    for (final entry in words.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return 1;
  }

  List<DetectedDailyAction> _deduplicate(List<DetectedDailyAction> actions) {
    final result = <DetectedDailyAction>[];
    final keys = <String>{};
    for (final action in actions) {
      final key = '${action.type}|${action.time}|${action.details.toLowerCase()}';
      if (keys.add(key)) result.add(action);
    }
    return result;
  }
}
