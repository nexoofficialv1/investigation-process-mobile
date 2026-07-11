class CdEntry {
  final String id;
  final String caseId;
  final int cdNumber;
  final String cdDate;
  final String startTime;
  final String endTime;
  final String placeOfEntry;
  final String body;
  final bool isFinal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CdEntry({
    required this.id,
    required this.caseId,
    required this.cdNumber,
    required this.cdDate,
    required this.startTime,
    required this.endTime,
    required this.placeOfEntry,
    required this.body,
    required this.isFinal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CdEntry.newDraft({
    required String caseId,
    required int cdNumber,
    required String body,
    String placeOfEntry = 'Kalna Police Station',
  }) {
    final now = DateTime.now();
    final date = now.toIso8601String().split('T').first;
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return CdEntry(
      id: 'cd_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      cdNumber: cdNumber,
      cdDate: date,
      startTime: '$hour:$minute hrs',
      endTime: '$hour:$minute hrs',
      placeOfEntry: placeOfEntry,
      body: body,
      isFinal: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  CdEntry copyWith({
    int? cdNumber,
    String? cdDate,
    String? startTime,
    String? endTime,
    String? placeOfEntry,
    String? body,
    bool? isFinal,
  }) {
    return CdEntry(
      id: id,
      caseId: caseId,
      cdNumber: cdNumber ?? this.cdNumber,
      cdDate: cdDate ?? this.cdDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      placeOfEntry: placeOfEntry ?? this.placeOfEntry,
      body: body ?? this.body,
      isFinal: isFinal ?? this.isFinal,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'cdNumber': cdNumber,
        'cdDate': cdDate,
        'startTime': startTime,
        'endTime': endTime,
        'placeOfEntry': placeOfEntry,
        'body': body,
        'isFinal': isFinal,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CdEntry.fromJson(Map<String, dynamic> json) {
    return CdEntry(
      id: json['id'] ?? 'cd_${DateTime.now().microsecondsSinceEpoch}',
      caseId: json['caseId'] ?? '',
      cdNumber: json['cdNumber'] ?? 1,
      cdDate: json['cdDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      placeOfEntry: json['placeOfEntry'] ?? '',
      body: json['body'] ?? '',
      isFinal: json['isFinal'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
