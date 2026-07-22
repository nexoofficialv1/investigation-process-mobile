import '../core/document_language.dart';
import 'document_translation_service.dart';

class WritingAssistService {
  Future<String> translate(String text, DocumentLanguage target) async {
    if (text.trim().isEmpty) return text;
    return DocumentTranslationService.instance.translate(text, target: target);
  }

  String gist(String text) {
    final sentences = text
        .trim()
        .split(RegExp(r'(?<=[।.!?])\s+|\n+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (sentences.length <= 2) return text.trim();
    return sentences.take(2).join(' ');
  }

  String chronological(String text) {
    final pieces = text
        .split(RegExp(r'[।.!?\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return pieces.asMap().entries.map((entry) {
      return '${entry.key + 1}. ${entry.value}';
    }).join('\n');
  }

  String officialDraft(String text, DocumentLanguage language) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (language.isBangla) {
      return 'জিজ্ঞাসাবাদে/অনুসন্ধানে প্রাপ্ত তথ্য অনুযায়ী, $trimmed';
    }
    return 'On examination/enquiry, it was stated that $trimmed';
  }
}
