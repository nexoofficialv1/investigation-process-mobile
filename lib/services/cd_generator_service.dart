import '../models/case_file.dart';

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
    final paragraphs = <String>[fixedOpening, ''];

    for (final pending in answers.pendingActionParagraphs) {
      if (pending.trim().isNotEmpty) paragraphs.add(pending.trim());
    }

    if (cdNumber == 1) {
      final start = caseFile.investigationStart;
      if (caseFile.firGist.trim().isNotEmpty) {
        paragraphs.add('Perused the case record and FIR. The brief fact of the case is that ${caseFile.firGist.trim()}');
      }
      if (start.visitedPo && start.poDetails.trim().isNotEmpty) {
        paragraphs.add('Visited the place of occurrence and noted the following details: ${start.poDetails.trim()}');
      }
      if (start.sketchPrepared && start.sketchDetails.trim().isNotEmpty) {
        paragraphs.add('Prepared rough sketch map of the PO with index. Details: ${start.sketchDetails.trim()}');
      }
      if (start.witnessExamined && start.witnessDetails.trim().isNotEmpty) {
        paragraphs.add('Examined available witness/witnesses and recorded statement u/s 180 BNSS. Details: ${start.witnessDetails.trim()}');
      }
      if (start.medicalRequired && start.medicalDetails.trim().isNotEmpty) {
        paragraphs.add('Took steps regarding medical papers/injury report/BHT. Details: ${start.medicalDetails.trim()}');
      }
      if (start.seizureRequired && start.seizureDetails.trim().isNotEmpty) {
        paragraphs.add('Took steps regarding seizure of relevant article/document. Details: ${start.seizureDetails.trim()}');
      }
    }

    if (answers.examinedWitness && answers.witnessDetails.trim().isNotEmpty) {
      paragraphs.add('Examined witness/witnesses and recorded statement u/s 180 BNSS. Details: ${answers.witnessDetails.trim()}');
    }
    if (answers.visitedPo && answers.poDetails.trim().isNotEmpty) {
      paragraphs.add('Visited the place of occurrence, held local enquiry and noted the relevant facts. Details: ${answers.poDetails.trim()}');
    }
    if (answers.sketchMap && answers.sketchDetails.trim().isNotEmpty) {
      paragraphs.add('Prepared/updated rough sketch map of the PO with index. Details: ${answers.sketchDetails.trim()}');
    }
    if (answers.medicalPaper && answers.medicalDetails.trim().isNotEmpty) {
      paragraphs.add('Collected/took steps for collection of medical papers. Details: ${answers.medicalDetails.trim()}');
    }
    if (answers.requisition && answers.requisitionDetails.trim().isNotEmpty) {
      paragraphs.add('Sent requisition for the purpose of investigation. Details: ${answers.requisitionDetails.trim()}');
    }
    if (answers.seizure && answers.seizureDetails.trim().isNotEmpty) {
      paragraphs.add('Seized relevant article/document under proper seizure list in presence of witnesses. Details: ${answers.seizureDetails.trim()}');
    }
    if (answers.arrest && answers.arrestDetails.trim().isNotEmpty) {
      paragraphs.add('Arrested accused person after observing legal formalities. Details: ${answers.arrestDetails.trim()}');
    }
    if (answers.notice && answers.noticeDetails.trim().isNotEmpty) {
      paragraphs.add('Served notice upon concerned person/persons. Details: ${answers.noticeDetails.trim()}');
    }
    if (answers.courtPrayer && answers.courtPrayerDetails.trim().isNotEmpty) {
      paragraphs.add('Submitted prayer before the Ld. Court. Details: ${answers.courtPrayerDetails.trim()}');
    }
    if (answers.receivedDocument && answers.receivedDocumentDetails.trim().isNotEmpty) {
      paragraphs.add('Received/perused relevant document/order/report. Details: ${answers.receivedDocumentDetails.trim()}');
    }
    if (answers.localEnquiry && answers.localEnquiryDetails.trim().isNotEmpty) {
      paragraphs.add('Conducted local enquiry. During enquiry it came to learn that ${answers.localEnquiryDetails.trim()}');
    }
    if (answers.verification && answers.verificationDetails.trim().isNotEmpty) {
      paragraphs.add('Verified relevant particulars during investigation. Details: ${answers.verificationDetails.trim()}');
    }
    if (answers.digitalEvidence && answers.digitalEvidenceDetails.trim().isNotEmpty) {
      paragraphs.add('Took steps for collection/verification of digital/electronic evidence. Details: ${answers.digitalEvidenceDetails.trim()}');
    }
    if (answers.importantDevelopment && answers.importantDevelopmentDetails.trim().isNotEmpty) {
      paragraphs.add('During investigation, important development surfaced. Details: ${answers.importantDevelopmentDetails.trim()}');
    }

    paragraphs.add('');
    paragraphs.add(fixedClosing);
    return paragraphs.join('\n\n');
  }
}
