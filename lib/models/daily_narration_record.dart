class DailyNarrationRecord {
  final String id;
  final String caseId;
  final String actionDate;
  final String inputLanguageCode;
  final String documentLanguageCode;
  final String originalNarration;
  final String generatedBody;
  final List<Map<String, dynamic>> actions;
  final DateTime createdAt;

  const DailyNarrationRecord({
    required this.id,
    required this.caseId,
    required this.actionDate,
    required this.inputLanguageCode,
    required this.documentLanguageCode,
    required this.originalNarration,
    required this.generatedBody,
    required this.actions,
    required this.createdAt,
  });

  factory DailyNarrationRecord.create({
    required String caseId,
    required String actionDate,
    required String inputLanguageCode,
    required String documentLanguageCode,
    required String originalNarration,
    required String generatedBody,
    required List<Map<String, dynamic>> actions,
  }) {
    final now = DateTime.now();
    return DailyNarrationRecord(
      id: 'daily_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      actionDate: actionDate,
      inputLanguageCode: inputLanguageCode,
      documentLanguageCode: documentLanguageCode,
      originalNarration: originalNarration,
      generatedBody: generatedBody,
      actions: actions,
      createdAt: now,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'caseId': caseId,
        'actionDate': actionDate,
        'inputLanguageCode': inputLanguageCode,
        'documentLanguageCode': documentLanguageCode,
        'originalNarration': originalNarration,
        'generatedBody': generatedBody,
        'actions': actions,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DailyNarrationRecord.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];
    final parsedActions = rawActions is List
        ? rawActions
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
        : <Map<String, dynamic>>[];

    return DailyNarrationRecord(
      id: (json['id'] ?? 'daily_${DateTime.now().microsecondsSinceEpoch}')
          .toString(),
      caseId: (json['caseId'] ?? '').toString(),
      actionDate: (json['actionDate'] ?? '').toString(),
      inputLanguageCode: (json['inputLanguageCode'] ?? 'bn').toString(),
      documentLanguageCode:
          (json['documentLanguageCode'] ?? 'bn').toString(),
      originalNarration: (json['originalNarration'] ?? '').toString(),
      generatedBody: (json['generatedBody'] ?? '').toString(),
      actions: parsedActions,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
              DateTime.now(),
    );
  }
}
