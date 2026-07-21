class FormNotice {
  final String id;
  final String caseId;
  final String templateId;
  final String title;
  final String body;
  final String languageCode;
  final bool isFinal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FormNotice({
    required this.id,
    required this.caseId,
    required this.templateId,
    required this.title,
    required this.body,
    this.languageCode = 'bn',
    required this.isFinal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FormNotice.create({
    required String caseId,
    required String templateId,
    required String title,
    required String body,
    String languageCode = 'bn',
  }) {
    final now = DateTime.now();
    return FormNotice(
      id: 'form_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      templateId: templateId,
      title: title,
      body: body,
      languageCode: languageCode,
      isFinal: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  FormNotice copyWith({
    String? title,
    String? body,
    String? languageCode,
    bool? isFinal,
  }) {
    return FormNotice(
      id: id,
      caseId: caseId,
      templateId: templateId,
      title: title ?? this.title,
      body: body ?? this.body,
      languageCode: languageCode ?? this.languageCode,
      isFinal: isFinal ?? this.isFinal,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'templateId': templateId,
        'title': title,
        'body': body,
        'languageCode': languageCode,
        'isFinal': isFinal,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FormNotice.fromJson(Map<String, dynamic> json) {
    return FormNotice(
      id: json['id'] ?? 'form_${DateTime.now().microsecondsSinceEpoch}',
      caseId: json['caseId'] ?? '',
      templateId: json['templateId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      languageCode: json['languageCode'] == 'en' ? 'en' : 'bn',
      isFinal: json['isFinal'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
