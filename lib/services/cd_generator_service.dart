import '../models/case_file.dart';
import '../models/cd_entry.dart';

class CdQuestionAnswer {
  List<String> pendingActionParagraphs = <String>[];
  bool examinedWitness = false;
  String witnessDetails = '';
  bool visitedPo = false;
  String poDetails = '';
  bool sketchMap = false;
  String sketchDetails = '';
  bool medicalPaper = false;
  String medicalDetails = '';
  bool requisition = false;
  String requisitionDetails = '';
  bool seizure = false;
  String seizureDetails = '';
  bool arrest = false;
  String arrestDetails = '';
  bool notice = false;
  String noticeDetails = '';
  bool courtPrayer = false;
  String courtPrayerDetails = '';
  bool receivedDocument = false;
  String receivedDocumentDetails = '';
  bool localEnquiry = false;
  String localEnquiryDetails = '';
  bool verification = false;
  String verificationDetails = '';
  bool digitalEvidence = false;
  String digitalEvidenceDetails = '';
  bool importantDevelopment = false;
  String importantDevelopmentDetails = '';
}

class CdGeneratorService {
  static const String fixedOpening = 'Resumed further investigation of the case.';
  static const String fixedClosing = 'Closed the diary pending for further investigation of this case.';

  String generateCdDraft({
    required CaseFile caseFile,
    required int cdNumber,
    required CdQuestionAnswer answers,
  }) {
    final lines = generateOfficialCdTableLines(
      caseFile: caseFile,
      cdNumber: cdNumber,
      time: _nowTime(),
      defaultPlace: 'Kalna PS',
      answers: answers,
    );
    return lines.map((e) => e.proceedings).where((e) => e.trim().isNotEmpty).join('\n\n');
  }

  List<CdTableLine> generateOfficialCdTableLines({
    required CaseFile caseFile,
    required int cdNumber,
    required String time,
    required String defaultPlace,
    required CdQuestionAnswer answers,
  }) {
    String place(String value) => value.trim().isEmpty ? defaultPlace : value.trim();
    final lines = <CdTableLine>[];

    void add(String roman, String where, String synopsis, String text) {
      final clean = text.trim();
      if (clean.isEmpty) return;
      lines.add(CdTableLine(noAndHour: '$roman\n$time', placeOfEntry: where, synopsis: synopsis, proceedings: clean));
    }

    if (cdNumber == 1) {
      final start = caseFile.investigationStart;
      final firText = <String>[
        fixedOpening,
        if (caseFile.placeOfOccurrence.trim().isNotEmpty) 'PO: ${caseFile.placeOfOccurrence.trim()}.',
        if (caseFile.dateTimeOccurrence.trim().isNotEmpty) 'DO: ${caseFile.dateTimeOccurrence.trim()}.',
        if (caseFile.dateTimeReporting.trim().isNotEmpty) 'DR: ${caseFile.dateTimeReporting.trim()}.',
        if (caseFile.firGist.trim().isNotEmpty) 'By this marginally noted time I perused the FIR/complaint. The brief fact of the case is that ${caseFile.firGist.trim()}',
      ].join('\n\n');
      add('I', defaultPlace, 'Received copy of FIR\n+\nGist', firText);
      if (start.visitedPo && start.poDetails.trim().isNotEmpty) add('II', place(caseFile.placeOfOccurrence), 'PO Visit', 'Visited the place of occurrence and noted the following details: ${start.poDetails.trim()}');
      if (start.sketchPrepared && start.sketchDetails.trim().isNotEmpty) add('III', place(caseFile.placeOfOccurrence), 'Rough sketch map', 'Prepared rough sketch map of the PO with index. Details: ${start.sketchDetails.trim()}');
      if (start.witnessExamined && start.witnessDetails.trim().isNotEmpty) add('IV', defaultPlace, 'Examine witness\n+\nStatement record', 'Examined available witness/witnesses and recorded statement u/s 180 BNSS. Details: ${start.witnessDetails.trim()}');
      if (start.medicalRequired && start.medicalDetails.trim().isNotEmpty) add('V', defaultPlace, 'Medical', 'Took steps regarding medical papers/injury report/BHT. Details: ${start.medicalDetails.trim()}');
      if (start.seizureRequired && start.seizureDetails.trim().isNotEmpty) add('VI', defaultPlace, 'Seizure', 'Took steps regarding seizure of relevant article/document. Details: ${start.seizureDetails.trim()}');
      if (start.evidenceRequired && start.evidenceDetails.trim().isNotEmpty) add('VII', defaultPlace, 'Evidence', 'Took steps regarding evidence collection/preservation. Details: ${start.evidenceDetails.trim()}');
    } else {
      add('I', defaultPlace, 'Further investigation', fixedOpening);
    }

    final romanList = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII','XIII','XIV','XV','XVI','XVII','XVIII','XIX','XX'];
    int idx = lines.length;
    void autoLine(String synopsis, String text, {String? where}) {
      final roman = idx < romanList.length ? romanList[idx] : '${idx + 1}';
      idx++;
      add(roman, where ?? defaultPlace, synopsis, text);
    }

    for (final pending in answers.pendingActionParagraphs) {
      if (pending.trim().isNotEmpty) autoLine('Requisition/Form', pending.trim());
    }
    if (answers.examinedWitness && answers.witnessDetails.trim().isNotEmpty) autoLine('Examine witness\n+\nStatement record', 'Examined witness/witnesses and recorded statement u/s 180 BNSS. Details: ${answers.witnessDetails.trim()}');
    if (answers.visitedPo && answers.poDetails.trim().isNotEmpty) autoLine('PO Visit\n+\nLocal enquiry', 'Visited the place of occurrence, held local enquiry and noted the relevant facts. Details: ${answers.poDetails.trim()}', where: place(caseFile.placeOfOccurrence));
    if (answers.sketchMap && answers.sketchDetails.trim().isNotEmpty) autoLine('Rough sketch map', 'Prepared/updated rough sketch map of the PO with index. Details: ${answers.sketchDetails.trim()}', where: place(caseFile.placeOfOccurrence));
    if (answers.medicalPaper && answers.medicalDetails.trim().isNotEmpty) autoLine('Medical', 'Collected/took steps for collection of medical papers. Details: ${answers.medicalDetails.trim()}');
    if (answers.requisition && answers.requisitionDetails.trim().isNotEmpty) autoLine('Requisition', 'Sent requisition for the purpose of investigation. Details: ${answers.requisitionDetails.trim()}');
    if (answers.seizure && answers.seizureDetails.trim().isNotEmpty) autoLine('Seizure', 'Seized relevant article/document under proper seizure list in presence of witnesses. Details: ${answers.seizureDetails.trim()}');
    if (answers.arrest && answers.arrestDetails.trim().isNotEmpty) autoLine('Arrest', 'Arrested/apprehended accused person after observing legal formalities. Details: ${answers.arrestDetails.trim()}');
    if (answers.notice && answers.noticeDetails.trim().isNotEmpty) autoLine('Notice', 'Served notice upon concerned person/persons. Details: ${answers.noticeDetails.trim()}');
    if (answers.courtPrayer && answers.courtPrayerDetails.trim().isNotEmpty) autoLine('Court prayer', 'Submitted prayer before the Ld. Court. Details: ${answers.courtPrayerDetails.trim()}');
    if (answers.receivedDocument && answers.receivedDocumentDetails.trim().isNotEmpty) autoLine('Document received', 'Received/perused relevant document/order/report. Details: ${answers.receivedDocumentDetails.trim()}');
    if (answers.localEnquiry && answers.localEnquiryDetails.trim().isNotEmpty) autoLine('Local enquiry', 'Conducted local enquiry. During enquiry it came to learn that ${answers.localEnquiryDetails.trim()}');
    if (answers.verification && answers.verificationDetails.trim().isNotEmpty) autoLine('Verification', 'Verified relevant particulars during investigation. Details: ${answers.verificationDetails.trim()}');
    if (answers.digitalEvidence && answers.digitalEvidenceDetails.trim().isNotEmpty) autoLine('Evidence', 'Took steps for collection/verification of physical/digital/electronic evidence. Details: ${answers.digitalEvidenceDetails.trim()}');
    if (answers.importantDevelopment && answers.importantDevelopmentDetails.trim().isNotEmpty) autoLine('Note', 'During investigation, important development surfaced. Details: ${answers.importantDevelopmentDetails.trim()}');

    autoLine('Retd\n+\nClosing', fixedClosing);
    return lines;
  }

  String _nowTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour.$minute hrs.';
  }
}
