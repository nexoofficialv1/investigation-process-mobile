import '../core/document_language.dart';
import 'document_translation_service.dart';

/// Translates narrative text while masking identifiers that must remain exact.
class ProtectedTranslationService {
  ProtectedTranslationService._();

  static final ProtectedTranslationService instance =
      ProtectedTranslationService._();

  Future<String> translate(
    String source, {
    required DocumentLanguage target,
    Iterable<String> protectedTerms = const <String>[],
  }) async {
    if (source.trim().isEmpty) return source;

    var masked = source;
    final replacements = <String, String>{};
    var index = 0;

    void protect(String value) {
      final term = value.trim();
      if (term.isEmpty || !masked.contains(term)) return;
      final token = '__INVESTIGO_KEEP_${index++}__';
      masked = masked.replaceAll(term, token);
      replacements[token] = term;
    }

    final automaticPatterns = <RegExp>[
      RegExp(r'\b(?:IMEI|IMSI|IPDR|CDR|CAF|GDE|GD|UD|FIR)\s*[-:/#.]?\s*[A-Za-z0-9_./()-]+', caseSensitive: false),
      RegExp(r'\b[A-Z]{1,4}\s*[-/]?\s*\d{1,4}\s*[A-Z]{0,3}\s*[-/]?\s*\d{1,6}\b'),
      RegExp(r'\b\d{5,18}\b'),
      RegExp(r'\b\d{1,4}/\d{2,4}\b'),
      RegExp(r'\b\d{1,3}(?:\([0-9A-Za-z]+\))?(?:/\d{1,3}(?:\([0-9A-Za-z]+\))?)*\s*(?:BNS|BNSS|IPC|CrPC|BSA|POCSO)?\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}[:.]\d{2}\b'),
      RegExp(r'\b\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}\b'),
    ];

    final automaticMatches = <String>{};
    for (final pattern in automaticPatterns) {
      automaticMatches.addAll(
        pattern.allMatches(masked).map((match) => match.group(0) ?? ''),
      );
    }
    for (final match in automaticMatches.toList()
      ..sort((a, b) => b.length.compareTo(a.length))) {
      protect(match);
    }

    final terms = protectedTerms
        .where((term) => term.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final term in terms) {
      protect(term);
    }

    var translated = await DocumentTranslationService.instance.translate(
      masked,
      target: target,
    );

    for (final entry in replacements.entries) {
      translated = translated.replaceAll(entry.key, entry.value);
      translated = translated.replaceAll(
        entry.key.replaceAll('_', ' '),
        entry.value,
      );
    }
    return translated;
  }
}
