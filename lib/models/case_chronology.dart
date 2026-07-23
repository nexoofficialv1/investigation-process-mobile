enum ChronologyEventStatus {
  verified,
  needsVerification,
  supplementary,
  repeated,
}

enum ChecklistState {
  done,
  pending,
  partial,
  repeated,
  notApplicable,
  needsVerification,
}

class ChronologyEvent {
  final String id;
  final String caseId;
  final String actionDate;
  final String time;
  final String type;
  final String place;
  final String entityKey;
  final String facts;
  final String sourceType;
  final String sourceEntryId;
  final String sourceActionId;
  final String fingerprint;
  final ChronologyEventStatus status;
  final String? parentEventId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChronologyEvent({
    required this.id,
    required this.caseId,
    required this.actionDate,
    required this.time,
    required this.type,
    required this.place,
    required this.entityKey,
    required this.facts,
    required this.sourceType,
    required this.sourceEntryId,
    required this.sourceActionId,
    required this.fingerprint,
    required this.status,
    required this.parentEventId,
    required this.createdAt,
    required this.updatedAt,
  });

  ChronologyEvent copyWith({
    String? actionDate,
    String? time,
    String? type,
    String? place,
    String? entityKey,
    String? facts,
    String? sourceType,
    String? sourceEntryId,
    String? sourceActionId,
    String? fingerprint,
    ChronologyEventStatus? status,
    String? parentEventId,
  }) {
    return ChronologyEvent(
      id: id,
      caseId: caseId,
      actionDate: actionDate ?? this.actionDate,
      time: time ?? this.time,
      type: type ?? this.type,
      place: place ?? this.place,
      entityKey: entityKey ?? this.entityKey,
      facts: facts ?? this.facts,
      sourceType: sourceType ?? this.sourceType,
      sourceEntryId: sourceEntryId ?? this.sourceEntryId,
      sourceActionId: sourceActionId ?? this.sourceActionId,
      fingerprint: fingerprint ?? this.fingerprint,
      status: status ?? this.status,
      parentEventId: parentEventId ?? this.parentEventId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'caseId': caseId,
        'actionDate': actionDate,
        'time': time,
        'type': type,
        'place': place,
        'entityKey': entityKey,
        'facts': facts,
        'sourceType': sourceType,
        'sourceEntryId': sourceEntryId,
        'sourceActionId': sourceActionId,
        'fingerprint': fingerprint,
        'status': status.name,
        'parentEventId': parentEventId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ChronologyEvent.fromJson(Map<String, dynamic> json) {
    return ChronologyEvent(
      id: (json['id'] ?? '').toString(),
      caseId: (json['caseId'] ?? '').toString(),
      actionDate: (json['actionDate'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      type: (json['type'] ?? 'other').toString(),
      place: (json['place'] ?? '').toString(),
      entityKey: (json['entityKey'] ?? '').toString(),
      facts: (json['facts'] ?? '').toString(),
      sourceType: (json['sourceType'] ?? '').toString(),
      sourceEntryId: (json['sourceEntryId'] ?? '').toString(),
      sourceActionId: (json['sourceActionId'] ?? '').toString(),
      fingerprint: (json['fingerprint'] ?? '').toString(),
      status: ChronologyEventStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => ChronologyEventStatus.needsVerification,
      ),
      parentEventId: json['parentEventId']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class ChronologyChecklistItem {
  final String id;
  final String group;
  final String title;
  final ChecklistState state;
  final String sourceReference;
  final String reason;
  final bool mandatory;

  const ChronologyChecklistItem({
    required this.id,
    required this.group,
    required this.title,
    required this.state,
    this.sourceReference = '',
    this.reason = '',
    this.mandatory = true,
  });

  bool get isComplete =>
      state == ChecklistState.done ||
      state == ChecklistState.repeated ||
      state == ChecklistState.notApplicable;
}

class ChronologyIssue {
  final String code;
  final String message;
  final bool blocksFinalization;

  const ChronologyIssue({
    required this.code,
    required this.message,
    required this.blocksFinalization,
  });
}

class ChronologyAssessment {
  final List<dynamic> acceptedActions;
  final List<ChronologyEvent> acceptedEvents;
  final List<ChronologyEvent> exactDuplicates;
  final List<ChronologyEvent> supplementaryParents;

  const ChronologyAssessment({
    required this.acceptedActions,
    required this.acceptedEvents,
    required this.exactDuplicates,
    required this.supplementaryParents,
  });

  bool get hasNewFacts => acceptedActions.isNotEmpty;
}

class DocumentReadiness {
  final bool caseDiaryReady;
  final bool memoOfEvidenceReady;
  final bool finalReportReady;
  final bool chargeSheetReady;
  final List<String> blockers;

  const DocumentReadiness({
    required this.caseDiaryReady,
    required this.memoOfEvidenceReady,
    required this.finalReportReady,
    required this.chargeSheetReady,
    required this.blockers,
  });
}

class CaseChronologySnapshot {
  final List<ChronologyEvent> events;
  final List<ChronologyChecklistItem> checklist;
  final List<ChronologyIssue> issues;
  final String nextQuestion;
  final DocumentReadiness readiness;

  const CaseChronologySnapshot({
    required this.events,
    required this.checklist,
    required this.issues,
    required this.nextQuestion,
    required this.readiness,
  });

  int get completeCount =>
      checklist.where((item) => item.isComplete).length;

  int get totalCount => checklist.length;

  double get progress =>
      totalCount == 0 ? 0 : completeCount / totalCount;
}
