enum DocumentLanguage {
  bangla('bn', 'বাংলা', 'Bangla'),
  english('en', 'ইংরেজি', 'English');

  const DocumentLanguage(this.code, this.banglaLabel, this.englishLabel);

  final String code;
  final String banglaLabel;
  final String englishLabel;

  bool get isBangla => this == DocumentLanguage.bangla;
  bool get isEnglish => this == DocumentLanguage.english;

  String get displayLabel => isBangla ? 'বাংলা' : 'English';

  static DocumentLanguage fromCode(String? code) {
    return code == 'en' ? DocumentLanguage.english : DocumentLanguage.bangla;
  }
}
