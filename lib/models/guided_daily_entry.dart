enum DailyEntrySource {
  investigation,
  evidence,
}

extension DailyEntrySourceX on DailyEntrySource {
  String get code => name;

  String get banglaLabel => this == DailyEntrySource.investigation
      ? 'ইনভেস্টিগেশন'
      : 'এভিডেন্স';

  String get englishLabel => this == DailyEntrySource.investigation
      ? 'Investigation'
      : 'Evidence';
}

DailyEntrySource dailyEntrySourceFromCode(String? value) {
  return value == DailyEntrySource.evidence.code
      ? DailyEntrySource.evidence
      : DailyEntrySource.investigation;
}

class GuidedAction {
  final String id;
  final String type;
  final String time;
  final String place;
  final String details;
  final int sequence;
  final bool includeInCd;
  final Map<String, String> answers;

  const GuidedAction({
    required this.id,
    required this.type,
    required this.time,
    required this.place,
    required this.details,
    required this.sequence,
    this.includeInCd = true,
    this.answers = const <String, String>{},
  });

  GuidedAction copyWith({
    String? time,
    String? place,
    String? details,
    int? sequence,
    bool? includeInCd,
    Map<String, String>? answers,
  }) {
    return GuidedAction(
      id: id,
      type: type,
      time: time ?? this.time,
      place: place ?? this.place,
      details: details ?? this.details,
      sequence: sequence ?? this.sequence,
      includeInCd: includeInCd ?? this.includeInCd,
      answers: answers ?? this.answers,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'time': time,
        'place': place,
        'details': details,
        'sequence': sequence,
        'includeInCd': includeInCd,
        'answers': answers,
      };

  factory GuidedAction.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    return GuidedAction(
      id: (json['id'] ??
              'guided_action_${DateTime.now().microsecondsSinceEpoch}')
          .toString(),
      type: (json['type'] ?? 'other').toString(),
      time: (json['time'] ?? '').toString(),
      place: (json['place'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      includeInCd: json['includeInCd'] != false,
      answers: rawAnswers is Map
          ? rawAnswers.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
    );
  }
}

class GuidedDailyEntry {
  final String id;
  final String caseId;
  final String actionDate;
  final DailyEntrySource source;
  final String narration;
  final String inputLanguageCode;
  final String documentLanguageCode;
  final List<GuidedAction> actions;
  final bool includeInCd;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuidedDailyEntry({
    required this.id,
    required this.caseId,
    required this.actionDate,
    required this.source,
    required this.narration,
    required this.inputLanguageCode,
    required this.documentLanguageCode,
    required this.actions,
    required this.includeInCd,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuidedDailyEntry.create({
    required String caseId,
    required String actionDate,
    required DailyEntrySource source,
    required String narration,
    required String inputLanguageCode,
    required String documentLanguageCode,
    required List<GuidedAction> actions,
    bool includeInCd = true,
  }) {
    final now = DateTime.now();
    return GuidedDailyEntry(
      id: 'guided_${source.code}_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      actionDate: actionDate,
      source: source,
      narration: narration,
      inputLanguageCode: inputLanguageCode,
      documentLanguageCode: documentLanguageCode,
      actions: actions,
      includeInCd: includeInCd,
      createdAt: now,
      updatedAt: now,
    );
  }

  GuidedDailyEntry copyWith({
    String? actionDate,
    String? narration,
    String? inputLanguageCode,
    String? documentLanguageCode,
    List<GuidedAction>? actions,
    bool? includeInCd,
  }) {
    return GuidedDailyEntry(
      id: id,
      caseId: caseId,
      actionDate: actionDate ?? this.actionDate,
      source: source,
      narration: narration ?? this.narration,
      inputLanguageCode: inputLanguageCode ?? this.inputLanguageCode,
      documentLanguageCode:
          documentLanguageCode ?? this.documentLanguageCode,
      actions: actions ?? this.actions,
      includeInCd: includeInCd ?? this.includeInCd,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'caseId': caseId,
        'actionDate': actionDate,
        'source': source.code,
        'narration': narration,
        'inputLanguageCode': inputLanguageCode,
        'documentLanguageCode': documentLanguageCode,
        'actions': actions.map((item) => item.toJson()).toList(),
        'includeInCd': includeInCd,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GuidedDailyEntry.fromJson(Map<String, dynamic> json) {
    return GuidedDailyEntry(
      id: (json['id'] ??
              'guided_${DateTime.now().microsecondsSinceEpoch}')
          .toString(),
      caseId: (json['caseId'] ?? '').toString(),
      actionDate: (json['actionDate'] ?? '').toString(),
      source: dailyEntrySourceFromCode(json['source']?.toString()),
      narration: (json['narration'] ?? '').toString(),
      inputLanguageCode: (json['inputLanguageCode'] ?? 'bn').toString(),
      documentLanguageCode:
          (json['documentLanguageCode'] ?? 'bn').toString(),
      actions: ((json['actions'] as List?) ?? const <dynamic>[])
          .map((item) =>
              GuidedAction.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      includeInCd: json['includeInCd'] != false,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
              DateTime.now(),
    );
  }
}
