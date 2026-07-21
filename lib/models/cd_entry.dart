class CdTableLine {
  final String noAndHour;
  final String placeOfEntry;
  final String synopsis;
  final String proceedings;

  const CdTableLine({
    required this.noAndHour,
    required this.placeOfEntry,
    required this.synopsis,
    required this.proceedings,
  });

  Map<String, dynamic> toJson() => {
        'noAndHour': noAndHour,
        'placeOfEntry': placeOfEntry,
        'synopsis': synopsis,
        'proceedings': proceedings,
      };

  factory CdTableLine.fromJson(Map<String, dynamic> json) => CdTableLine(
        noAndHour: json['noAndHour'] ?? '',
        placeOfEntry: json['placeOfEntry'] ?? '',
        synopsis: json['synopsis'] ?? '',
        proceedings: json['proceedings'] ?? '',
      );
}

class CdEntry {
  final String id;
  final String caseId;
  final int cdNumber;
  final String cdDate;
  final String startTime;
  final String endTime;
  final String placeOfEntry;
  final String body;
  final List<CdTableLine> tableLines;
  final String languageCode;
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
    this.tableLines = const <CdTableLine>[],
    this.languageCode = 'bn',
    required this.isFinal,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEnglish => languageCode == 'en';

  factory CdEntry.newDraft({
    required String caseId,
    required int cdNumber,
    required String body,
    String placeOfEntry = 'কালনা থানা',
    List<CdTableLine>? tableLines,
    String languageCode = 'bn',
  }) {
    final now = DateTime.now();
    final date = now.toIso8601String().split('T').first;
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final isEnglish = languageCode == 'en';
    final time = isEnglish ? '$hour:$minute hrs' : '$hour.$minute ঘণ্টা';
    return CdEntry(
      id: 'cd_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      cdNumber: cdNumber,
      cdDate: date,
      startTime: time,
      endTime: time,
      placeOfEntry: placeOfEntry,
      body: body,
      tableLines: tableLines ?? [
        CdTableLine(
          noAndHour: '${isEnglish ? '1' : '১'}\n$time',
          placeOfEntry: placeOfEntry,
          synopsis: cdNumber == 1
              ? (isEnglish
                  ? 'Receipt of FIR copy\n+\nBrief facts'
                  : 'এফআইআরের অনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা')
              : (isEnglish ? 'Further investigation' : 'পরবর্তী তদন্ত'),
          proceedings: body,
        ),
      ],
      languageCode: languageCode,
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
    List<CdTableLine>? tableLines,
    String? languageCode,
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
      tableLines: tableLines ?? this.tableLines,
      languageCode: languageCode ?? this.languageCode,
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
        'tableLines': tableLines.map((e) => e.toJson()).toList(),
        'languageCode': languageCode,
        'isFinal': isFinal,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CdEntry.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['tableLines'];
    final parsedLines = linesRaw is List
        ? linesRaw
            .map((e) => CdTableLine.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CdTableLine>[];
    final languageCode = (json['languageCode'] ?? 'bn').toString();
    final cd = CdEntry(
      id: json['id'] ?? 'cd_${DateTime.now().microsecondsSinceEpoch}',
      caseId: json['caseId'] ?? '',
      cdNumber: json['cdNumber'] ?? 1,
      cdDate: json['cdDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      placeOfEntry: json['placeOfEntry'] ?? '',
      body: json['body'] ?? '',
      tableLines: parsedLines,
      languageCode: languageCode,
      isFinal: json['isFinal'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
    if (cd.tableLines.isNotEmpty) return cd;
    final isEnglish = languageCode == 'en';
    return cd.copyWith(
      tableLines: [
        CdTableLine(
          noAndHour: '${isEnglish ? '1' : '১'}\n${cd.startTime}',
          placeOfEntry: cd.placeOfEntry,
          synopsis: cd.cdNumber == 1
              ? (isEnglish
                  ? 'Receipt of FIR copy\n+\nBrief facts'
                  : 'এফআইআরের অনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা')
              : (isEnglish ? 'Further investigation' : 'পরবর্তী তদন্ত'),
          proceedings: cd.body,
        )
      ],
    );
  }
}
