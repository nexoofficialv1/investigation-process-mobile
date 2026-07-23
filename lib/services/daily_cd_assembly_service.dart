import '../core/document_language.dart';
import '../models/cd_entry.dart';
import '../models/case_file.dart';
import '../models/guided_daily_entry.dart';
import '../models/officer_profile.dart';
import 'guided_question_engine.dart';
import 'protected_translation_service.dart';

class DailyCdAssemblyResult {
  final CdEntry cd;
  final int investigationActionCount;
  final int evidenceActionCount;

  const DailyCdAssemblyResult({
    required this.cd,
    required this.investigationActionCount,
    required this.evidenceActionCount,
  });
}

class DailyCdAssemblyService {
  final GuidedQuestionEngine _engine = GuidedQuestionEngine();

  Future<DailyCdAssemblyResult?> build({
    required String caseId,
    required CaseFile caseFile,
    required String actionDate,
    required int cdNumber,
    required OfficerProfile profile,
    required DocumentLanguage language,
    required List<GuidedDailyEntry> entries,
  }) async {
    final valid = entries
        .where((item) =>
            item.caseId == caseId &&
            item.actionDate == actionDate &&
            item.includeInCd)
        .toList();
    if (valid.isEmpty) return null;

    final investigationEntries = valid
        .where((item) => item.source == DailyEntrySource.investigation)
        .toList();
    final evidenceEntries = valid
        .where((item) => item.source == DailyEntrySource.evidence)
        .toList();
    final actions = _engine.deduplicateAndSort(
      valid.expand((item) => item.actions).toList(),
    );
    if (actions.isEmpty) return null;

    final station = profile.policeStation.trim().isEmpty
        ? (language.isBangla ? 'থানা' : 'Police Station')
        : profile.policeStation.trim();
    final firstTime = actions.first.time.trim();
    final lastTime = actions.last.time.trim();
    final rows = <CdTableLine>[];
    var serial = 1;

    final isFirstCd = cdNumber == 1;
    rows.add(CdTableLine(
      noAndHour: '${_number(serial++, language)}\n$firstTime',
      placeOfEntry: station,
      synopsis: isFirstCd
          ? (language.isBangla
              ? 'এফআইআর ও মামলার কাগজপত্র গ্রহণ এবং তদন্তভার গ্রহণ'
              : 'Receipt of FIR and case papers and taking up investigation')
          : (language.isBangla
              ? 'পরবর্তী তদন্ত পুনরায় শুরু'
              : 'Resumption of further investigation'),
      proceedings: isFirstCd
          ? (language.isBangla
              ? '${caseFile.displayTitle}, ধারা ${caseFile.sections}-এর এফআইআর ও মামলার কাগজপত্র গ্রহণ করে নির্দেশমতো মামলার তদন্তভার গ্রহণ করলাম।'
              : 'Received the FIR and case papers of ${caseFile.displayTitle} under sections ${caseFile.sections} and, as endorsed, took up investigation of the case.')
          : (language.isBangla
              ? 'মামলার পরবর্তী তদন্ত পুনরায় শুরু করলাম।'
              : 'Resumed further investigation of the case.'),
    ));

    for (final action in actions) {
      final protectedTerms = <String>[
        action.place,
        ...action.answers.values,
      ].where((item) => item.trim().isNotEmpty);
      final originalFacts = _engine.factSummary(action);
      String translatedFacts = originalFacts;
      try {
        translatedFacts = await ProtectedTranslationService.instance.translate(
          originalFacts,
          target: language,
          protectedTerms: protectedTerms,
        );
      } catch (_) {
        // Never block the diary or invent facts if translation is unavailable.
        translatedFacts = originalFacts;
      }
      rows.add(CdTableLine(
        noAndHour: '${_number(serial++, language)}\n${action.time.trim()}',
        placeOfEntry: action.place.trim(),
        synopsis: _engine.synopsis(action, language),
        proceedings: _engine.officialProceeding(
          action: action,
          language: language,
          translatedFacts: translatedFacts,
        ),
      ));
    }

    rows.add(CdTableLine(
      noAndHour: '${_number(serial, language)}\n$lastTime',
      placeOfEntry: station,
      synopsis: language.isBangla
          ? 'কেস ডায়েরি বন্ধ'
          : 'Closure of Case Diary',
      proceedings: language.isBangla
          ? 'এই মামলার পরবর্তী তদন্তের জন্য কেস ডায়েরি বন্ধ রাখলাম।'
          : 'Closed the diary pending for further investigation of this case.',
    ));

    final body = rows.map((item) => item.proceedings).join('\n\n');
    final draft = CdEntry.newDraft(
      caseId: caseId,
      cdNumber: cdNumber,
      body: body,
      placeOfEntry: station,
      tableLines: rows,
      languageCode: language.code,
    ).copyWith(
      cdDate: actionDate,
      startTime: firstTime,
      endTime: lastTime,
      placeOfEntry: station,
    );

    return DailyCdAssemblyResult(
      cd: draft,
      investigationActionCount: investigationEntries
          .expand((item) => item.actions)
          .where((item) => item.includeInCd)
          .length,
      evidenceActionCount: evidenceEntries
          .expand((item) => item.actions)
          .where((item) => item.includeInCd)
          .length,
    );
  }

  String _number(int number, DocumentLanguage language) {
    if (language.isEnglish) return '$number';
    const digits = <String>['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return '$number'.split('').map((item) => digits[int.parse(item)]).join();
  }
}
