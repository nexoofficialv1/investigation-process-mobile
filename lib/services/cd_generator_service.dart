import '../core/document_language.dart';
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
  static const String fixedOpeningBn = 'মামলাটির পুনরায় তদন্ত শুরু করলাম।';
  static const String fixedClosingBn =
      'মামলাটির পরবর্তী তদন্তের জন্য কেস ডায়েরি বন্ধ রাখলাম।';
  static const String fixedOpeningEn =
      'Resumed further investigation of the case.';
  static const String fixedClosingEn =
      'Closed the diary pending further investigation of the case.';

  String generateCdDraft({
    required CaseFile caseFile,
    required int cdNumber,
    required CdQuestionAnswer answers,
    DocumentLanguage language = DocumentLanguage.bangla,
  }) {
    final lines = generateOfficialCdTableLines(
      caseFile: caseFile,
      cdNumber: cdNumber,
      time: _nowTime(language),
      defaultPlace: language.isBangla ? 'থানা' : 'Police Station',
      answers: answers,
      language: language,
    );
    return lines
        .map((e) => e.proceedings)
        .where((e) => e.trim().isNotEmpty)
        .join('\n\n');
  }

  List<CdTableLine> generateOfficialCdTableLines({
    required CaseFile caseFile,
    required int cdNumber,
    required String time,
    required String defaultPlace,
    required CdQuestionAnswer answers,
    DocumentLanguage language = DocumentLanguage.bangla,
  }) {
    return language.isBangla
        ? _generateBangla(
            caseFile: caseFile,
            cdNumber: cdNumber,
            time: time,
            defaultPlace: defaultPlace,
            answers: answers,
          )
        : _generateEnglish(
            caseFile: caseFile,
            cdNumber: cdNumber,
            time: time,
            defaultPlace: defaultPlace,
            answers: answers,
          );
  }

  List<CdTableLine> _generateBangla({
    required CaseFile caseFile,
    required int cdNumber,
    required String time,
    required String defaultPlace,
    required CdQuestionAnswer answers,
  }) {
    String place(String value) =>
        value.trim().isEmpty ? defaultPlace : value.trim();
    String present(String value) =>
        value.trim().isEmpty ? 'উল্লেখ নেই' : value.trim();
    final lines = <CdTableLine>[];

    void add(String number, String where, String synopsis, String text) {
      final clean = text.trim();
      if (clean.isEmpty) return;
      lines.add(
        CdTableLine(
          noAndHour: '$number\n$time',
          placeOfEntry: where,
          synopsis: synopsis,
          proceedings: clean,
        ),
      );
    }

    if (cdNumber == 1) {
      final start = caseFile.investigationStart;
      final topNotes = <String>[
        'ঘটনাস্থল: -${present(caseFile.placeOfOccurrence)}।',
        'ঘটনার তারিখ ও সময়: -${present(caseFile.dateTimeOccurrence)}।',
        'রিপোর্টের তারিখ ও সময়: -${present(caseFile.dateTimeReporting)}।',
        'মামলা রুজুর তারিখ: -${caseFile.caseDate}।',
        'তদন্তভার গ্রহণের তারিখ: -${start.tookUpDate.trim().isEmpty ? caseFile.caseDate : start.tookUpDate.trim()}।',
        'মামলা রুজুকারী অফিসার: -উল্লেখ করতে হবে।',
        'তদন্তকারী অফিসার: -${start.ioName.trim().isEmpty ? 'উল্লেখ করতে হবে' : start.ioName.trim()}।',
      ].join('\n');
      final firText = <String>[
        topNotes,
        if (caseFile.firGist.trim().isNotEmpty)
          'প্রান্তে উল্লিখিত সময়ে থানা সেরেস্তা মারফত এফআইআর ও লিখিত অভিযোগের অনুলিপি পেলাম। একইটি মনোযোগসহ পাঠ করে দেখলাম যে, ${caseFile.firGist.trim()} উক্ত অভিযোগের ভিত্তিতে উপরোক্ত মামলা রুজু হয়েছে এবং নির্দেশক্রমে আমি মামলাটির তদন্তভার গ্রহণ করলাম।',
      ].join('\n\n');
      add(
        '১',
        defaultPlace,
        'এফআইআর-এর\nঅনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা',
        firText,
      );
      if (start.visitedPo && start.poDetails.trim().isNotEmpty) {
        add(
          '২',
          place(caseFile.placeOfOccurrence),
          'থানা থেকে রওনা\n+\nঘটনাস্থল পরিদর্শন',
          'এই সময়ে ঘটনাস্থলে উপস্থিত হয়ে নিম্নলিখিত বিষয়গুলি লক্ষ্য করলাম: ${start.poDetails.trim()}',
        );
      }
      if (start.sketchPrepared && start.sketchDetails.trim().isNotEmpty) {
        add(
          '৩',
          place(caseFile.placeOfOccurrence),
          'খসড়া নকশা',
          'অভিযোগকারী/সাক্ষীর দেখানো মতে ঘটনাস্থল পরিদর্শন করে সূচিসহ ঘটনাস্থলের একটি খসড়া নকশা প্রস্তুত করলাম, যা কেস ডায়েরির সঙ্গে রাখা হলো। বিস্তারিত: ${start.sketchDetails.trim()}',
        );
      }
      if (start.witnessExamined && start.witnessDetails.trim().isNotEmpty) {
        add(
          '৪',
          defaultPlace,
          'সাক্ষী পরীক্ষা\n+\nবিবৃতি লিপিবদ্ধ',
          'প্রান্তে উল্লিখিত সময়ে উপলব্ধ সাক্ষী/সাক্ষীদের পরীক্ষা করে বিএনএসএস-এর ১৮০ ধারায় তাঁদের বিবৃতি লিপিবদ্ধ করলাম। বিস্তারিত: ${start.witnessDetails.trim()}',
        );
      }
      if (start.medicalRequired && start.medicalDetails.trim().isNotEmpty) {
        add(
          '৫',
          defaultPlace,
          'চিকিৎসা সংক্রান্ত',
          'চিকিৎসা নথি/আঘাতের প্রতিবেদন/বিএইচটি সংগ্রহের জন্য প্রয়োজনীয় ব্যবস্থা গ্রহণ করলাম। বিস্তারিত: ${start.medicalDetails.trim()}',
        );
      }
      if (start.seizureRequired && start.seizureDetails.trim().isNotEmpty) {
        add(
          '৬',
          defaultPlace,
          'জব্দ',
          'প্রাসঙ্গিক আলামত/নথি জব্দের জন্য প্রয়োজনীয় ব্যবস্থা গ্রহণ করলাম। বিস্তারিত: ${start.seizureDetails.trim()}',
        );
      }
      if (start.evidenceRequired && start.evidenceDetails.trim().isNotEmpty) {
        add(
          '৭',
          defaultPlace,
          'প্রমাণ সংগ্রহ',
          'প্রাসঙ্গিক প্রমাণ সংগ্রহ ও সংরক্ষণের জন্য প্রয়োজনীয় ব্যবস্থা গ্রহণ করলাম। বিস্তারিত: ${start.evidenceDetails.trim()}',
        );
      }
    } else {
      add('১', defaultPlace, 'পরবর্তী তদন্ত', fixedOpeningBn);
    }

    final numberList = <String>[
      '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', '১০',
      '১১', '১২', '১৩', '১৪', '১৫', '১৬', '১৭', '১৮', '১৯', '২০',
    ];
    var index = lines.length;
    void autoLine(String synopsis, String text, {String? where}) {
      final number =
          index < numberList.length ? numberList[index] : '${index + 1}';
      index++;
      add(number, where ?? defaultPlace, synopsis, text);
    }

    for (final pending in answers.pendingActionParagraphs) {
      if (pending.trim().isNotEmpty) {
        autoLine('রিকুইজিশন/ফর্ম', pending.trim());
      }
    }
    if (answers.examinedWitness && answers.witnessDetails.trim().isNotEmpty) {
      autoLine(
        'সাক্ষী পরীক্ষা\n+\nবিবৃতি লিপিবদ্ধ',
        'সাক্ষী/সাক্ষীদের পরীক্ষা করে বিএনএসএস-এর ১৮০ ধারায় তাঁদের বিবৃতি লিপিবদ্ধ করলাম। বিস্তারিত: ${answers.witnessDetails.trim()}',
      );
    }
    if (answers.visitedPo && answers.poDetails.trim().isNotEmpty) {
      autoLine(
        'ঘটনাস্থল পরিদর্শন\n+\nস্থানীয় অনুসন্ধান',
        'ঘটনাস্থল পরিদর্শন করে স্থানীয় অনুসন্ধান চালালাম এবং প্রাসঙ্গিক বিষয়গুলি নোট করলাম। বিস্তারিত: ${answers.poDetails.trim()}',
        where: place(caseFile.placeOfOccurrence),
      );
    }
    if (answers.sketchMap && answers.sketchDetails.trim().isNotEmpty) {
      autoLine(
        'খসড়া নকশা',
        'সূচিসহ ঘটনাস্থলের খসড়া নকশা প্রস্তুত/হালনাগাদ করলাম। বিস্তারিত: ${answers.sketchDetails.trim()}',
        where: place(caseFile.placeOfOccurrence),
      );
    }
    if (answers.medicalPaper && answers.medicalDetails.trim().isNotEmpty) {
      autoLine(
        'চিকিৎসা সংক্রান্ত',
        'চিকিৎসা সংক্রান্ত কাগজপত্র সংগ্রহ/সংগ্রহের ব্যবস্থা করলাম। বিস্তারিত: ${answers.medicalDetails.trim()}',
      );
    }
    if (answers.requisition && answers.requisitionDetails.trim().isNotEmpty) {
      autoLine(
        'রিকুইজিশন',
        'তদন্তের স্বার্থে প্রয়োজনীয় রিকুইজিশন পাঠালাম। বিস্তারিত: ${answers.requisitionDetails.trim()}',
      );
    }
    if (answers.seizure && answers.seizureDetails.trim().isNotEmpty) {
      autoLine(
        'জব্দ',
        'সাক্ষীদের উপস্থিতিতে যথাযথ জব্দতালিকার মাধ্যমে প্রাসঙ্গিক আলামত/নথি জব্দ করলাম। বিস্তারিত: ${answers.seizureDetails.trim()}',
      );
    }
    if (answers.arrest && answers.arrestDetails.trim().isNotEmpty) {
      autoLine(
        'গ্রেপ্তার',
        'আইনগত সমস্ত নিয়ম মেনে অভিযুক্ত ব্যক্তিকে গ্রেপ্তার/আটক করলাম। বিস্তারিত: ${answers.arrestDetails.trim()}',
      );
    }
    if (answers.notice && answers.noticeDetails.trim().isNotEmpty) {
      autoLine(
        'নোটিশ',
        'সংশ্লিষ্ট ব্যক্তি/ব্যক্তিদের উপর প্রয়োজনীয় নোটিশ জারি ও তামিল করলাম। বিস্তারিত: ${answers.noticeDetails.trim()}',
      );
    }
    if (answers.courtPrayer &&
        answers.courtPrayerDetails.trim().isNotEmpty) {
      autoLine(
        'আদালতে প্রার্থনা',
        'বিজ্ঞ আদালতে প্রয়োজনীয় প্রার্থনাপত্র দাখিল করলাম। বিস্তারিত: ${answers.courtPrayerDetails.trim()}',
      );
    }
    if (answers.receivedDocument &&
        answers.receivedDocumentDetails.trim().isNotEmpty) {
      autoLine(
        'নথি গ্রহণ',
        'প্রাসঙ্গিক নথি/আদেশ/প্রতিবেদন গ্রহণ করে পর্যালোচনা করলাম। বিস্তারিত: ${answers.receivedDocumentDetails.trim()}',
      );
    }
    if (answers.localEnquiry &&
        answers.localEnquiryDetails.trim().isNotEmpty) {
      autoLine(
        'স্থানীয় অনুসন্ধান',
        'স্থানীয় অনুসন্ধান চালিয়ে জানা গেল যে, ${answers.localEnquiryDetails.trim()}',
      );
    }
    if (answers.verification &&
        answers.verificationDetails.trim().isNotEmpty) {
      autoLine(
        'যাচাই',
        'তদন্তকালে প্রাসঙ্গিক তথ্যাদি যাচাই করলাম। বিস্তারিত: ${answers.verificationDetails.trim()}',
      );
    }
    if (answers.digitalEvidence &&
        answers.digitalEvidenceDetails.trim().isNotEmpty) {
      autoLine(
        'প্রমাণ সংগ্রহ',
        'ভৌত/ডিজিটাল/ইলেকট্রনিক প্রমাণ সংগ্রহ ও যাচাইয়ের জন্য প্রয়োজনীয় ব্যবস্থা গ্রহণ করলাম। বিস্তারিত: ${answers.digitalEvidenceDetails.trim()}',
      );
    }
    if (answers.importantDevelopment &&
        answers.importantDevelopmentDetails.trim().isNotEmpty) {
      autoLine(
        'গুরুত্বপূর্ণ অগ্রগতি',
        'তদন্তকালে নিম্নলিখিত গুরুত্বপূর্ণ বিষয় প্রকাশ্যে এলো। বিস্তারিত: ${answers.importantDevelopmentDetails.trim()}',
      );
    }

    autoLine('প্রত্যাবর্তন\n+\nসমাপ্তি', fixedClosingBn);
    return lines;
  }

  List<CdTableLine> _generateEnglish({
    required CaseFile caseFile,
    required int cdNumber,
    required String time,
    required String defaultPlace,
    required CdQuestionAnswer answers,
  }) {
    String place(String value) =>
        value.trim().isEmpty ? defaultPlace : value.trim();
    String present(String value) =>
        value.trim().isEmpty ? 'Not mentioned' : value.trim();
    final lines = <CdTableLine>[];

    void add(String number, String where, String synopsis, String text) {
      final clean = text.trim();
      if (clean.isEmpty) return;
      lines.add(
        CdTableLine(
          noAndHour: '$number\n$time',
          placeOfEntry: where,
          synopsis: synopsis,
          proceedings: clean,
        ),
      );
    }

    if (cdNumber == 1) {
      final start = caseFile.investigationStart;
      final topNotes = <String>[
        'Place of occurrence: ${present(caseFile.placeOfOccurrence)}.',
        'Date and time of occurrence: ${present(caseFile.dateTimeOccurrence)}.',
        'Date and time of reporting: ${present(caseFile.dateTimeReporting)}.',
        'Date of registration: ${caseFile.caseDate}.',
        'Date of taking up investigation: ${start.tookUpDate.trim().isEmpty ? caseFile.caseDate : start.tookUpDate.trim()}.',
        'Recording Officer: To be mentioned.',
        'Investigating Officer: ${start.ioName.trim().isEmpty ? 'To be mentioned' : start.ioName.trim()}.',
      ].join('\n');
      final firText = <String>[
        topNotes,
        if (caseFile.firGist.trim().isNotEmpty)
          'At the time noted in the margin, I received the copy of the FIR and written complaint through the Police Station office. On carefully perusing the same, it appeared that ${caseFile.firGist.trim()} On the basis of the said complaint, the above-noted case was registered and, as directed, I took up its investigation.',
      ].join('\n\n');
      add(
        '1',
        defaultPlace,
        'Receipt of FIR copy\n+\nBrief facts',
        firText,
      );
      if (start.visitedPo && start.poDetails.trim().isNotEmpty) {
        add(
          '2',
          place(caseFile.placeOfOccurrence),
          'Departure from PS\n+\nVisit to PO',
          'At this time I reached the place of occurrence and observed the following facts: ${start.poDetails.trim()}',
        );
      }
      if (start.sketchPrepared && start.sketchDetails.trim().isNotEmpty) {
        add(
          '3',
          place(caseFile.placeOfOccurrence),
          'Rough sketch map',
          'On inspection of the place of occurrence as shown by the complainant/witness, I prepared a rough sketch map with index and kept the same with the case diary. Details: ${start.sketchDetails.trim()}',
        );
      }
      if (start.witnessExamined && start.witnessDetails.trim().isNotEmpty) {
        add(
          '4',
          defaultPlace,
          'Examination of witness\n+\nRecording statement',
          'At the time noted in the margin, I examined the available witness/witnesses and recorded their statements under Section 180 BNSS. Details: ${start.witnessDetails.trim()}',
        );
      }
      if (start.medicalRequired && start.medicalDetails.trim().isNotEmpty) {
        add(
          '5',
          defaultPlace,
          'Medical papers',
          'I took necessary steps for collection of medical records/injury report/BHT. Details: ${start.medicalDetails.trim()}',
        );
      }
      if (start.seizureRequired && start.seizureDetails.trim().isNotEmpty) {
        add(
          '6',
          defaultPlace,
          'Seizure',
          'I took necessary steps for seizure of the relevant articles/documents. Details: ${start.seizureDetails.trim()}',
        );
      }
      if (start.evidenceRequired && start.evidenceDetails.trim().isNotEmpty) {
        add(
          '7',
          defaultPlace,
          'Collection of evidence',
          'I took necessary steps for collection and preservation of relevant evidence. Details: ${start.evidenceDetails.trim()}',
        );
      }
    } else {
      add('1', defaultPlace, 'Further investigation', fixedOpeningEn);
    }

    var index = lines.length;
    void autoLine(String synopsis, String text, {String? where}) {
      index++;
      add('$index', where ?? defaultPlace, synopsis, text);
    }

    for (final pending in answers.pendingActionParagraphs) {
      if (pending.trim().isNotEmpty) {
        autoLine('Requisition/Form', pending.trim());
      }
    }
    if (answers.examinedWitness && answers.witnessDetails.trim().isNotEmpty) {
      autoLine(
        'Examination of witness\n+\nRecording statement',
        'I examined the witness/witnesses and recorded their statements under Section 180 BNSS. Details: ${answers.witnessDetails.trim()}',
      );
    }
    if (answers.visitedPo && answers.poDetails.trim().isNotEmpty) {
      autoLine(
        'Visit to PO\n+\nLocal enquiry',
        'I visited the place of occurrence, conducted local enquiry and noted the relevant facts. Details: ${answers.poDetails.trim()}',
        where: place(caseFile.placeOfOccurrence),
      );
    }
    if (answers.sketchMap && answers.sketchDetails.trim().isNotEmpty) {
      autoLine(
        'Rough sketch map',
        'I prepared/updated the rough sketch map of the place of occurrence with index. Details: ${answers.sketchDetails.trim()}',
        where: place(caseFile.placeOfOccurrence),
      );
    }
    if (answers.medicalPaper && answers.medicalDetails.trim().isNotEmpty) {
      autoLine(
        'Medical papers',
        'I collected/took steps to collect the relevant medical papers. Details: ${answers.medicalDetails.trim()}',
      );
    }
    if (answers.requisition && answers.requisitionDetails.trim().isNotEmpty) {
      autoLine(
        'Requisition',
        'I sent the necessary requisition in the interest of investigation. Details: ${answers.requisitionDetails.trim()}',
      );
    }
    if (answers.seizure && answers.seizureDetails.trim().isNotEmpty) {
      autoLine(
        'Seizure',
        'I seized the relevant articles/documents under a proper seizure list in presence of witnesses. Details: ${answers.seizureDetails.trim()}',
      );
    }
    if (answers.arrest && answers.arrestDetails.trim().isNotEmpty) {
      autoLine(
        'Arrest',
        'I arrested/detained the accused person after complying with all legal formalities. Details: ${answers.arrestDetails.trim()}',
      );
    }
    if (answers.notice && answers.noticeDetails.trim().isNotEmpty) {
      autoLine(
        'Notice',
        'I issued and served the necessary notice upon the person/persons concerned. Details: ${answers.noticeDetails.trim()}',
      );
    }
    if (answers.courtPrayer &&
        answers.courtPrayerDetails.trim().isNotEmpty) {
      autoLine(
        'Prayer before Court',
        'I submitted the necessary prayer before the Learned Court. Details: ${answers.courtPrayerDetails.trim()}',
      );
    }
    if (answers.receivedDocument &&
        answers.receivedDocumentDetails.trim().isNotEmpty) {
      autoLine(
        'Receipt of document',
        'I received and examined the relevant document/order/report. Details: ${answers.receivedDocumentDetails.trim()}',
      );
    }
    if (answers.localEnquiry &&
        answers.localEnquiryDetails.trim().isNotEmpty) {
      autoLine(
        'Local enquiry',
        'During local enquiry it came to light that ${answers.localEnquiryDetails.trim()}',
      );
    }
    if (answers.verification &&
        answers.verificationDetails.trim().isNotEmpty) {
      autoLine(
        'Verification',
        'During investigation I verified the relevant facts and information. Details: ${answers.verificationDetails.trim()}',
      );
    }
    if (answers.digitalEvidence &&
        answers.digitalEvidenceDetails.trim().isNotEmpty) {
      autoLine(
        'Collection of evidence',
        'I took necessary steps for collection and verification of physical/digital/electronic evidence. Details: ${answers.digitalEvidenceDetails.trim()}',
      );
    }
    if (answers.importantDevelopment &&
        answers.importantDevelopmentDetails.trim().isNotEmpty) {
      autoLine(
        'Important development',
        'During investigation the following important facts came to light. Details: ${answers.importantDevelopmentDetails.trim()}',
      );
    }

    autoLine('Return\n+\nClosing', fixedClosingEn);
    return lines;
  }

  String _nowTime(DocumentLanguage language) {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return language.isBangla ? '$hour.$minute ঘণ্টা' : '$hour:$minute hrs';
  }
}
