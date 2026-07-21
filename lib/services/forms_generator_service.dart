import '../core/document_language.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';

class FormTemplateInfo {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String englishTitle;
  final String englishSubtitle;
  final String englishCategory;

  const FormTemplateInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.englishTitle,
    required this.englishSubtitle,
    required this.englishCategory,
  });

  String titleFor(DocumentLanguage language) =>
      language.isBangla ? title : englishTitle;

  String subtitleFor(DocumentLanguage language) =>
      language.isBangla ? subtitle : englishSubtitle;

  String categoryFor(DocumentLanguage language) =>
      language.isBangla ? category : englishCategory;
}

class FormsGeneratorService {
  static const List<FormTemplateInfo> templates = [
    FormTemplateInfo(
      id: 'bnss_179_notice',
      title: 'বিএনএসএস ১৭৯ ধারার হাজিরার নোটিশ',
      subtitle: 'সাক্ষী/ঘটনা সম্পর্কে অবগত ব্যক্তিকে তদন্তে হাজিরার নোটিশ',
      category: 'নোটিশ',
      englishTitle: 'Notice under Section 179 BNSS',
      englishSubtitle: 'Notice requiring attendance of witness/person acquainted with the case',
      englishCategory: 'Notice',
    ),
    FormTemplateInfo(
      id: 'bnss_195_notice',
      title: 'বিএনএসএস ১৯৫ ধারার হাজিরার নোটিশ',
      subtitle: 'সুরতহাল/অস্বাভাবিক মৃত্যু অনুসন্ধানে হাজিরার নোটিশ',
      category: 'ইউডি নোটিশ',
      englishTitle: 'Notice under Section 195 BNSS',
      englishSubtitle: 'Attendance notice for inquest/unnatural-death enquiry',
      englishCategory: 'UD Notice',
    ),
    FormTemplateInfo(
      id: 'bnss_35_3',
      title: 'বিএনএসএস ৩৫(৩) ধারার নোটিশ',
      subtitle: 'অভিযুক্ত/ব্যক্তিকে হাজিরা ও তদন্তে সহযোগিতার নোটিশ',
      category: 'নোটিশ',
      englishTitle: 'Notice under Section 35(3) BNSS',
      englishSubtitle: 'Notice to appear before police and cooperate with investigation',
      englishCategory: 'Notice',
    ),
    FormTemplateInfo(
      id: 'bnss_94',
      title: 'বিএনএসএস ৯৪ ধারার নোটিশ/রিকুইজিশন',
      subtitle: 'নথি, তথ্য, ইলেকট্রনিক রেকর্ড বা বস্তু উপস্থাপনের নির্দেশ',
      category: 'নোটিশ/রিকুইজিশন',
      englishTitle: 'Notice/Requisition under Section 94 BNSS',
      englishSubtitle: 'Direction to produce documents, information, electronic records or articles',
      englishCategory: 'Notice/Requisition',
    ),
    FormTemplateInfo(
      id: 'bnss_183',
      title: 'বিএনএসএস ১৮৩ ধারার প্রার্থনা',
      subtitle: 'বিজ্ঞ আদালতে বিচারবিভাগীয় বিবৃতি লিপিবদ্ধের প্রার্থনা',
      category: 'আদালতের প্রার্থনা',
      englishTitle: 'Prayer under Section 183 BNSS',
      englishSubtitle: 'Prayer before the Learned Court for recording judicial statement',
      englishCategory: 'Court Prayer',
    ),
    FormTemplateInfo(
      id: 'arrest_memo',
      title: 'গ্রেপ্তার মেমো',
      subtitle: 'গ্রেপ্তারের কারণ, সাক্ষী, মনোনীত ব্যক্তি ও অন্যান্য আবশ্যিক বিবরণ',
      category: 'গ্রেপ্তার/অভিযুক্ত',
      englishTitle: 'Arrest Memo',
      englishSubtitle: 'Official arrest memo with grounds, witnesses and nominated-person details',
      englishCategory: 'Arrest/Accused',
    ),
    FormTemplateInfo(
      id: 'arrest_information',
      title: 'মনোনীত ব্যক্তি/আত্মীয়কে গ্রেপ্তারের সংবাদ',
      subtitle: 'গ্রেপ্তারের সংবাদ ও সংশ্লিষ্ট বিবরণ প্রদানের নোটিশ',
      category: 'গ্রেপ্তার/অভিযুক্ত',
      englishTitle: 'Arrest Information to Nominated Person/Relative',
      englishSubtitle: 'Intimation of arrest and connected particulars',
      englishCategory: 'Arrest/Accused',
    ),
    FormTemplateInfo(
      id: 'medical_exam',
      title: 'চিকিৎসা পরীক্ষার রিকুইজিশন',
      subtitle: 'ভিকটিম/আহত/অভিযুক্তের চিকিৎসা পরীক্ষা ও প্রতিবেদন',
      category: 'চিকিৎসা',
      englishTitle: 'Medical Examination Requisition',
      englishSubtitle: 'Medical examination and report of victim/injured/accused',
      englishCategory: 'Medical',
    ),
    FormTemplateInfo(
      id: 'bht_injury',
      title: 'বিএইচটি/আঘাতের প্রতিবেদন রিকুইজিশন',
      subtitle: 'হাসপাতালের নথি, বিএইচটি ও আঘাতের প্রতিবেদন সংগ্রহ',
      category: 'চিকিৎসা',
      englishTitle: 'Requisition for BHT/Injury Report',
      englishSubtitle: 'Collection of hospital records, BHT and injury report',
      englishCategory: 'Medical',
    ),
    FormTemplateInfo(
      id: 'cdr_caf',
      title: 'সিডিআর/এসডিআর/সিএএফ/আইএমইআই রিকুইজিশন',
      subtitle: 'টেলিকম ও ডিজিটাল তথ্য সংগ্রহের সরকারি আবেদন',
      category: 'ডিজিটাল প্রমাণ',
      englishTitle: 'CDR/SDR/CAF/IMEI Requisition',
      englishSubtitle: 'Official requisition for telecom and digital records',
      englishCategory: 'Digital Evidence',
    ),
    FormTemplateInfo(
      id: 'bank_details',
      title: 'ব্যাংক হিসাব ও লেনদেনের তথ্য চেয়ে রিকুইজিশন',
      subtitle: 'কেওয়াইসি, বিবরণী, ইউটিআর, লিয়েন ও ফ্রিজ সংক্রান্ত তথ্য',
      category: 'সাইবার/ব্যাংক',
      englishTitle: 'Requisition for Bank Account and Transaction Details',
      englishSubtitle: 'KYC, statement, UTR, lien and freeze-related information',
      englishCategory: 'Cyber/Bank',
    ),
    FormTemplateInfo(
      id: 'fsl',
      title: 'এফএসএল ফর্ম, চালান ও লেবেল প্যাকেজ',
      subtitle: 'ফর্ম ৫২০৩, আলামত তালিকা, পরীক্ষার প্রশ্ন, চালান ও লেবেল',
      category: 'বিশেষজ্ঞ মতামত',
      englishTitle: 'FSL Form, Challan and Label Package',
      englishSubtitle: 'Form 5203, exhibit list, examination queries, challan and labels',
      englishCategory: 'Expert Opinion',
    ),
    FormTemplateInfo(
      id: 'forwarding',
      title: 'গ্রেপ্তারকৃত অভিযুক্তের ফরওয়ার্ডিং রিপোর্ট',
      subtitle: 'বিজ্ঞ আদালতে অভিযুক্তকে প্রেরণ ও হেফাজতের প্রার্থনা',
      category: 'আদালত',
      englishTitle: 'Forwarding Report of Arrested Accused',
      englishSubtitle: 'Forwarding of accused before the Learned Court with custody prayer',
      englishCategory: 'Court',
    ),
    FormTemplateInfo(
      id: 'further_investigation',
      title: 'পরবর্তী তদন্ত/সময় বৃদ্ধির প্রার্থনা',
      subtitle: 'পরবর্তী তদন্ত, অনুবর্তিতা বা সময় বৃদ্ধির জন্য আদালতের প্রার্থনা',
      category: 'আদালতের প্রার্থনা',
      englishTitle: 'Prayer for Further Investigation/Extension of Time',
      englishSubtitle: 'Court prayer for further investigation, compliance or extension of time',
      englishCategory: 'Court Prayer',
    ),
    FormTemplateInfo(
      id: 'memo_evidence',
      title: 'সাক্ষ্য-প্রমাণের স্মারক',
      subtitle: 'মামলা, সাক্ষী, জব্দ, বিশেষজ্ঞ মতামত ও প্রমাণের সমন্বিত স্মারক',
      category: 'চূড়ান্ত নথি',
      englishTitle: 'Memo of Evidence',
      englishSubtitle: 'Consolidated memo of case facts, witnesses, seizure, expert opinion and evidence',
      englishCategory: 'Final Documents',
    ),
    FormTemplateInfo(
      id: 'form54_air',
      title: 'ফর্ম ৫৪ দুর্ঘটনা তথ্য প্রতিবেদন',
      subtitle: 'মোটর দুর্ঘটনা/এমএসিটি সংক্রান্ত তথ্য প্রতিবেদন',
      category: 'দুর্ঘটনা/এমএসিটি',
      englishTitle: 'Form 54 Accident Information Report',
      englishSubtitle: 'Motor accident/MACT information report',
      englishCategory: 'Accident/MACT',
    ),
    FormTemplateInfo(
      id: 'inquest_report_196',
      title: 'বিএনএসএস ১৯৬ ধারার সুরতহাল প্রতিবেদন',
      subtitle: 'অতিরিক্ত/আদালত-উপযোগী সুরতহাল প্রতিবেদন',
      category: 'ইউডি মামলা',
      englishTitle: 'Inquest Report under Section 196 BNSS',
      englishSubtitle: 'Additional/court-ready inquest report',
      englishCategory: 'UD Case',
    ),
    FormTemplateInfo(
      id: 'cs_checklist',
      title: 'অভিযোগপত্র/চূড়ান্ত প্রতিবেদন দাখিল-পূর্ব যাচাইতালিকা',
      subtitle: 'দাখিলের আগে নথি, প্রমাণ ও প্রক্রিয়াগত অনুবর্তিতা যাচাই',
      category: 'চূড়ান্ত প্রতিবেদন',
      englishTitle: 'Pre-submission Checklist for Charge Sheet/Final Report',
      englishSubtitle: 'Verification of records, evidence and procedural compliance before submission',
      englishCategory: 'Final Report',
    ),
  ];

  FormTemplateInfo templateById(String id) {
    return templates.firstWhere(
      (e) => e.id == id,
      orElse: () => templates.first,
    );
  }

  String titleFor(String templateId, DocumentLanguage language) =>
      templateById(templateId).titleFor(language);

  String generate({
    required String templateId,
    required OfficerProfile officer,
    required CaseFile caseFile,
    DocumentLanguage language = DocumentLanguage.bangla,
  }) {
    if (language.isEnglish) {
      return _generateEnglish(templateId, officer, caseFile);
    }
    return _generateBangla(templateId, officer, caseFile);
  }

  String _generateBangla(
    String templateId,
    OfficerProfile officer,
    CaseFile caseFile,
  ) {
    switch (templateId) {
      case 'bnss_179_notice':
        return _notice179Bn(officer, caseFile);
      case 'bnss_195_notice':
        return _notice195Bn(officer, caseFile);
      case 'bnss_35_3':
        return _notice35Bn(officer, caseFile);
      case 'bnss_94':
        return _requisition94Bn(officer, caseFile);
      case 'bnss_183':
        return _prayer183Bn(officer, caseFile);
      case 'arrest_memo':
        return _arrestMemoBn(officer, caseFile);
      case 'arrest_information':
        return _arrestInformationBn(officer, caseFile);
      case 'medical_exam':
        return _medicalExamBn(officer, caseFile);
      case 'bht_injury':
        return _bhtInjuryBn(officer, caseFile);
      case 'cdr_caf':
        return _cdrCafBn(officer, caseFile);
      case 'bank_details':
        return _bankDetailsBn(officer, caseFile);
      case 'fsl':
        return _fslBn(officer, caseFile);
      case 'forwarding':
        return _forwardingBn(officer, caseFile);
      case 'further_investigation':
        return _furtherInvestigationBn(officer, caseFile);
      case 'memo_evidence':
        return _memoEvidenceBn(officer, caseFile);
      case 'form54_air':
        return _form54Bn(officer, caseFile);
      case 'inquest_report_196':
        return _inquest196Bn(officer, caseFile);
      case 'cs_checklist':
        return _csChecklistBn(officer, caseFile);
      default:
        return _genericBn(officer, caseFile);
    }
  }

  String _generateEnglish(
    String templateId,
    OfficerProfile officer,
    CaseFile caseFile,
  ) {
    switch (templateId) {
      case 'bnss_179_notice':
        return _notice179En(officer, caseFile);
      case 'bnss_195_notice':
        return _notice195En(officer, caseFile);
      case 'bnss_35_3':
        return _notice35En(officer, caseFile);
      case 'bnss_94':
        return _requisition94En(officer, caseFile);
      case 'bnss_183':
        return _prayer183En(officer, caseFile);
      case 'arrest_memo':
        return _arrestMemoEn(officer, caseFile);
      case 'arrest_information':
        return _arrestInformationEn(officer, caseFile);
      case 'medical_exam':
        return _medicalExamEn(officer, caseFile);
      case 'bht_injury':
        return _bhtInjuryEn(officer, caseFile);
      case 'cdr_caf':
        return _cdrCafEn(officer, caseFile);
      case 'bank_details':
        return _bankDetailsEn(officer, caseFile);
      case 'fsl':
        return _fslEn(officer, caseFile);
      case 'forwarding':
        return _forwardingEn(officer, caseFile);
      case 'further_investigation':
        return _furtherInvestigationEn(officer, caseFile);
      case 'memo_evidence':
        return _memoEvidenceEn(officer, caseFile);
      case 'form54_air':
        return _form54En(officer, caseFile);
      case 'inquest_report_196':
        return _inquest196En(officer, caseFile);
      case 'cs_checklist':
        return _csChecklistEn(officer, caseFile);
      default:
        return _genericEn(officer, caseFile);
    }
  }

  String _caseRefBn(OfficerProfile officer, CaseFile caseFile) =>
      '${officer.policeStation} মামলা নং ${caseFile.psCaseNo}, তারিখ ${caseFile.caseDate}, ধারা ${caseFile.sections}';

  String _caseRefEn(OfficerProfile officer, CaseFile caseFile) =>
      '${officer.policeStation} Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate}, U/S ${caseFile.sections}';

  String _valueOrBlank(String value, String fallback) =>
      value.trim().isEmpty ? fallback : value.trim();

  String _notice179Bn(OfficerProfile officer, CaseFile caseFile) =>
      '''বিএনএসএস, ২০২৩-এর ১৭৯ ধারায় হাজিরার নোটিশ

মেমো নং: ____________________                 তারিখ: ____________________

প্রতি,
নাম: ________________________________________________
পিতা/মাতা/স্বামী: ____________________________________
ঠিকানা: ______________________________________________

বিষয়: ${_caseRefBn(officer, caseFile)}-এর তদন্তে হাজিরা প্রসঙ্গে।

মহাশয়/মহাশয়া,
উপরোক্ত মামলার তদন্ত নিম্নস্বাক্ষরকারী পরিচালনা করছেন। তদন্তে প্রতীয়মান হয়েছে যে, আপনি মামলার ঘটনা ও পরিস্থিতি সম্পর্কে অবগত এবং আপনার বক্তব্য সুষ্ঠু তদন্তের জন্য প্রয়োজনীয়। অতএব বিএনএসএস, ২০২৩-এর ১৭৯ ধারায় প্রদত্ত ক্ষমতাবলে আপনাকে __________ তারিখে ______ ঘটিকায় ${officer.policeStation}, জেলা–${officer.district}-এ নিম্নস্বাক্ষরকারীর নিকট হাজির হয়ে তদন্তে সহযোগিতা করার নির্দেশ দেওয়া হলো।

আপনি মামলার সঙ্গে সম্পর্কিত কোনো নথি, ছবি, ভিডিও, ডিজিটাল রেকর্ড বা বস্তু ধারণ করলে তা সঙ্গে আনবেন/আইনানুগভাবে উপস্থাপন করবেন। বয়স, লিঙ্গ, শারীরিক বা মানসিক অক্ষমতা, তীব্র অসুস্থতা অথবা আইনগত কোনো সুরক্ষা প্রযোজ্য হলে তা অবিলম্বে তদন্তকারী অফিসারকে জানাবেন, যাতে আইন অনুযায়ী উপযুক্ত স্থানে পরীক্ষা/জিজ্ঞাসাবাদের ব্যবস্থা করা যায়।

যথাযথ কারণ ছাড়া নোটিশ অমান্য করলে আইন অনুযায়ী প্রয়োজনীয় ব্যবস্থা গ্রহণ করা হতে পারে।

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}
মোবাইল: ${officer.mobile}''';

  String _notice179En(OfficerProfile officer, CaseFile caseFile) =>
      '''NOTICE OF ATTENDANCE UNDER SECTION 179 BNSS, 2023

Memo No.: ____________________                 Date: ____________________

To,
Name: ________________________________________________
Parent/Spouse: ________________________________________
Address: ______________________________________________

Subject: Attendance for investigation of ${_caseRefEn(officer, caseFile)}.

Sir/Madam,
The investigation of the above-noted case is being conducted by the undersigned. It appears that you are acquainted with the facts and circumstances of the case and that your examination is necessary for a fair investigation. You are therefore required, under Section 179 BNSS, 2023, to appear before the undersigned at ${officer.policeStation}, District ${officer.district}, on __________ at ______ hours and cooperate with the investigation.

If you possess any document, photograph, video, digital record or article connected with the case, you shall bring/produce the same in accordance with law. If any protection relating to age, gender, physical or mental disability, acute illness or any other lawful ground applies, you should immediately inform the Investigating Officer so that examination may be arranged at the place permitted by law.

Failure to comply without lawful justification may invite necessary action in accordance with law.

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}
Mobile: ${officer.mobile}''';

  String _notice195Bn(OfficerProfile officer, CaseFile caseFile) =>
      '''বিএনএসএস, ২০২৩-এর ১৯৫ ধারায় হাজিরার নোটিশ

মেমো নং: ____________________                 তারিখ: ____________________

প্রতি,
নাম: ________________________________________________
পিতা/মাতা/স্বামী: ____________________________________
ঠিকানা: ______________________________________________

বিষয়: মৃত/নিহত ${_valueOrBlank(caseFile.victimName, '____________________________')}-এর মৃত্যু সংক্রান্ত সুরতহাল/অনুসন্ধানে হাজিরা প্রসঙ্গে।

মহাশয়/মহাশয়া,
উপরোক্ত মৃত্যু সম্পর্কে মৃত্যুর কারণ ও পরিস্থিতি নির্ধারণের জন্য আইনানুগ সুরতহাল/অনুসন্ধান চলছে। প্রতীয়মান হয়েছে যে, আপনি ঘটনাটি সম্পর্কে অবগত অথবা অনুসন্ধানের জন্য প্রয়োজনীয় তথ্য/নথি দিতে সক্ষম। অতএব বিএনএসএস, ২০২৩-এর ১৯৫ ধারায় আপনাকে __________ তারিখে ______ ঘটিকায় ${officer.policeStation}, জেলা–${officer.district}-এ নিম্নস্বাক্ষরকারীর নিকট হাজির হয়ে সত্য ও সম্পূর্ণ তথ্য প্রদান করার জন্য নির্দেশ দেওয়া হলো।

আপনার নিকট থাকা চিকিৎসা নথি, পরিচয়পত্র, ছবি, ভিডিও, মোবাইল তথ্য বা মৃত্যু সংক্রান্ত অন্য কোনো প্রাসঙ্গিক নথি/বস্তু সঙ্গে আনবেন। যথাযথ কারণ ছাড়া নোটিশ অমান্য করলে আইন অনুযায়ী ব্যবস্থা গ্রহণ করা হতে পারে।

${officer.rank} ${officer.name}
অনুসন্ধানকারী অফিসার
${officer.policeStation}, ${officer.district}
মোবাইল: ${officer.mobile}''';

  String _notice195En(OfficerProfile officer, CaseFile caseFile) =>
      '''NOTICE OF ATTENDANCE UNDER SECTION 195 BNSS, 2023

Memo No.: ____________________                 Date: ____________________

To,
Name: ________________________________________________
Parent/Spouse: ________________________________________
Address: ______________________________________________

Subject: Attendance in connection with the inquest/enquiry into the death of ${_valueOrBlank(caseFile.victimName, '____________________________')}.

Sir/Madam,
A lawful inquest/enquiry is being conducted to ascertain the cause and circumstances of the above death. It appears that you are acquainted with the occurrence or are capable of producing information/records necessary for the enquiry. You are therefore required under Section 195 BNSS, 2023, to appear before the undersigned at ${officer.policeStation}, District ${officer.district}, on __________ at ______ hours and furnish true and complete information.

You should bring any medical record, identity document, photograph, video, mobile data or other document/article relevant to the death. Failure to comply without lawful justification may invite action in accordance with law.

${officer.rank} ${officer.name}
Enquiry Officer
${officer.policeStation}, ${officer.district}
Mobile: ${officer.mobile}''';

  String _notice35Bn(OfficerProfile officer, CaseFile caseFile) {
    final accused = _valueOrBlank(
      caseFile.accusedName,
      '____________________________',
    );
    return '''পুলিশ অফিসারের নিকট হাজির হওয়ার নোটিশ
[ভারতীয় নাগরিক সুরক্ষা সংহিতা, ২০২৩-এর ৩৫(৩) ধারা অনুযায়ী]

ক্রমিক নং: ____________                                      সংযোজনী–ক
তারিখ: ________________

প্রতি,
$accused
ঠিকানা: ________________________________________________

বিষয়: ${_caseRefBn(officer, caseFile)}-এর তদন্তে হাজিরা ও সহযোগিতা প্রসঙ্গে।

আপনাকে জানানো যাচ্ছে যে, উপরোক্ত মামলার তদন্তকালে প্রাপ্ত তথ্য ও উপকরণের ভিত্তিতে মামলার ঘটনা ও পরিস্থিতি সম্পর্কে আপনাকে জিজ্ঞাসাবাদ করা প্রয়োজন বলে যুক্তিসঙ্গত কারণ বিদ্যমান। অতএব ভারতীয় নাগরিক সুরক্ষা সংহিতা, ২০২৩-এর ৩৫(৩) ধারায় প্রদত্ত ক্ষমতাবলে আপনাকে এই নোটিশ প্রাপ্তির ______ দিনের মধ্যে, __________ তারিখে ______ ঘটিকায় ${officer.policeStation}, জেলা–${officer.district}-এ নিম্নস্বাক্ষরকারী তদন্তকারী অফিসারের নিকট হাজির হয়ে তদন্তে যোগদান ও পূর্ণ সহযোগিতা করার নির্দেশ দেওয়া হলো।

আপনাকে নিম্নলিখিত শর্তাবলি পালন করতে হবে:–
১। তদন্তকারী অফিসার যখনই নির্দেশ দেবেন, তখনই হাজির হবেন।
২। তদন্তের জন্য প্রয়োজনীয় প্রশ্নের সত্য ও সম্পূর্ণ উত্তর দেবেন এবং কোনো প্রাসঙ্গিক তথ্য গোপন করবেন না।
৩। মামলার কোনো প্রমাণ নষ্ট, পরিবর্তন, লুকিয়ে রাখা বা প্রভাবিত করবেন না।
৪। মামলার ঘটনা সম্পর্কে অবগত কোনো সাক্ষী বা ব্যক্তিকে ভয়, প্রলোভন, প্রতিশ্রুতি বা অন্য কোনোভাবে প্রভাবিত করবেন না।
৫। তদন্তের জন্য প্রয়োজনীয় নথি, ডিজিটাল ডিভাইস, বস্তু বা তথ্য আইনানুগভাবে উপস্থাপন করবেন।
৬। তদন্ত চলাকালে বর্তমান ঠিকানা ও মোবাইল নম্বর পরিবর্তন করলে অবিলম্বে তদন্তকারী অফিসারকে জানাবেন।
৭। আদালত বা তদন্তকারী অফিসার কর্তৃক আরোপিত অন্য কোনো বৈধ শর্ত পালন করবেন।

এই নোটিশ অনুযায়ী হাজির না হলে বা শর্তাবলি পালন না করলে আইনানুগভাবে আপনার বিরুদ্ধে প্রয়োজনীয় ব্যবস্থা গ্রহণ করা হতে পারে, যার মধ্যে প্রযোজ্য ক্ষেত্রে বিএনএসএস-এর ৩৫(৬) ধারা অনুযায়ী গ্রেপ্তারও অন্তর্ভুক্ত।

নোটিশ গ্রহণকারীর স্বাক্ষর: ____________________
তারিখ ও সময়: ________________________________

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}
মোবাইল: ${officer.mobile}''';
  }

  String _notice35En(OfficerProfile officer, CaseFile caseFile) {
    final accused = _valueOrBlank(
      caseFile.accusedName,
      '____________________________',
    );
    return '''NOTICE TO APPEAR BEFORE POLICE OFFICER
[Under Section 35(3) of the Bharatiya Nagarik Suraksha Sanhita, 2023]

Serial No.: ____________                                      Annexure–A
Date: ________________

To,
$accused
Address: ________________________________________________

Subject: Appearance and cooperation in connection with investigation of ${_caseRefEn(officer, caseFile)}.

Whereas, during investigation of the above-noted case, reasonable grounds have emerged to examine you regarding the facts and circumstances of the case. Therefore, in exercise of the power conferred under Section 35(3) of the Bharatiya Nagarik Suraksha Sanhita, 2023, you are hereby directed to appear before the undersigned Investigating Officer at ${officer.policeStation}, District ${officer.district}, on __________ at ______ hours, within ______ days from receipt of this notice, and to join and fully cooperate with the investigation.

You shall comply with the following conditions:–
1. You shall appear before the Investigating Officer whenever directed.
2. You shall truthfully and completely answer all lawful questions relevant to the investigation and shall not conceal any material fact.
3. You shall not destroy, alter, conceal or tamper with any evidence connected with the case.
4. You shall not directly or indirectly induce, threaten, promise or otherwise influence any witness or person acquainted with the facts of the case.
5. You shall produce such documents, digital devices, articles or information as may lawfully be required for investigation.
6. You shall immediately inform the Investigating Officer of any change in your present address or mobile number during the investigation.
7. You shall comply with any other lawful condition imposed by the Court or the Investigating Officer.

Failure to appear or comply with the conditions of this notice may invite action in accordance with law, including arrest under Section 35(6) BNSS wherever applicable.

Signature of recipient: ____________________
Date and time of receipt: __________________

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}
Mobile: ${officer.mobile}''';
  }

  String _requisition94Bn(OfficerProfile officer, CaseFile caseFile) {
    final complainant = _valueOrBlank(
      caseFile.complainantName,
      'অভিযোগকারী/তথ্যদাতা',
    );
    return '''ভারতীয় নাগরিক সুরক্ষা সংহিতা, ২০২৩-এর ৯৪ ধারার নোটিশ/রিকুইজিশন

মেমো নং: ____________________                 তারিখ: ____________________

প্রতি,
অধীক্ষক/শাখা ব্যবস্থাপক/নোডাল অফিসার/ভারপ্রাপ্ত আধিকারিক,
________________________________________________
ঠিকানা: ________________________________________

বিষয়: ${_caseRefBn(officer, caseFile)}-এর তদন্তের জন্য নথি/তথ্য/ইলেকট্রনিক রেকর্ড/বস্তু উপস্থাপন প্রসঙ্গে।

মহাশয়/মহাশয়া,
উপরোক্ত মামলার তদন্ত চলমান রয়েছে। অভিযোগকারী/তথ্যদাতা $complainant এবং মামলার ঘটনা ও পরিস্থিতির সঙ্গে সম্পর্কিত নিম্নলিখিত নথি, তথ্য, ইলেকট্রনিক রেকর্ড বা বস্তু সুষ্ঠু তদন্তের জন্য প্রয়োজনীয় বলে বিবেচিত হয়েছে। অতএব বিএনএসএস, ২০২৩-এর ৯৪ ধারার বিধান অনুযায়ী নিম্নোক্ত বিষয়গুলি যথাযথভাবে প্রত্যয়িত করে ______ তারিখের মধ্যে নিম্নস্বাক্ষরকারীর নিকট উপস্থাপন/সরবরাহ করার জন্য নির্দেশ/অনুরোধ করা হলো:–

১। ________________________________________________
২। ________________________________________________
৩। ________________________________________________
৪। সংশ্লিষ্ট রেজিস্টার/লগবুক/আবেদনপত্র/চুক্তিপত্র/কেওয়াইসি/ভর্তি রেকর্ড/চিকিৎসা নথির প্রত্যয়িত অনুলিপি।
৫। প্রাসঙ্গিক ইলেকট্রনিক রেকর্ড, সিসিটিভি ফুটেজ, ডিজিটাল লগ, ই-মেইল বা অন্য কোনো তথ্য, প্রযোজ্য ক্ষেত্রে আইনসম্মত সার্টিফিকেটসহ।
৬। সংশ্লিষ্ট কর্মকর্তা/কর্মচারী/ব্যক্তির নাম, পদবি, ঠিকানা ও যোগাযোগের বিবরণ।
৭। তদন্তের স্বার্থে প্রাসঙ্গিক অন্য কোনো রেকর্ড, প্রতিবেদন, নথি বা বস্তু।

সরবরাহকৃত প্রত্যেকটি নথির পৃষ্ঠায় যথাযথ সিল ও স্বাক্ষরসহ প্রত্যয়ন এবং ইলেকট্রনিক রেকর্ডের ক্ষেত্রে প্রযোজ্য আইন অনুসারে প্রয়োজনীয় সার্টিফিকেট সংযুক্ত করার অনুরোধ করা হলো।

বৈধ কারণ ছাড়া এই নোটিশ/নির্দেশ অমান্য করলে আইন অনুযায়ী প্রয়োজনীয় ব্যবস্থা গ্রহণ করা হতে পারে।

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}
মোবাইল: ${officer.mobile}''';
  }

  String _requisition94En(OfficerProfile officer, CaseFile caseFile) {
    final complainant = _valueOrBlank(
      caseFile.complainantName,
      'the complainant/informant',
    );
    return '''NOTICE/REQUISITION UNDER SECTION 94 OF THE BHARATIYA NAGARIK SURAKSHA SANHITA, 2023

Memo No.: ____________________                 Date: ____________________

To,
The Superintendent/Branch Manager/Nodal Officer/Officer-in-Charge,
________________________________________________
Address: ________________________________________

Subject: Production of documents/information/electronic records/articles for investigation of ${_caseRefEn(officer, caseFile)}.

Sir/Madam,
Investigation of the above-noted case is in progress. The following documents, information, electronic records or articles relating to $complainant and the facts and circumstances of the case are considered necessary for a fair and effective investigation. You are therefore directed/requested, under Section 94 BNSS, 2023, to produce or supply the following duly certified materials to the undersigned on or before __________:–

1. ________________________________________________
2. ________________________________________________
3. ________________________________________________
4. Certified copies of the relevant register, logbook, application, agreement, KYC, admission record, medical record or other connected record.
5. Relevant electronic record, CCTV footage, digital log, e-mail or other data, together with the certificate required by law wherever applicable.
6. Name, designation, address and contact details of the concerned officer, employee or person.
7. Any other record, report, document or article relevant to the investigation.

Each page of the supplied record should be duly certified with seal and signature. Electronic records should be accompanied by the certificate required under the applicable law.

Failure to comply without lawful justification may invite necessary action in accordance with law.

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}
Mobile: ${officer.mobile}''';
  }

  String _prayer183Bn(OfficerProfile officer, CaseFile caseFile) =>
      '''মাননীয় ${officer.courtName}-এর আদালতে

মারফত: জিআরও/কোর্ট অফিসার, সংশ্লিষ্ট আদালত

বিষয়: ${_caseRefBn(officer, caseFile)}-এর সূত্রে বিএনএসএস-এর ১৮৩ ধারায় ভিকটিম/সাক্ষীর বিবৃতি লিপিবদ্ধ করার প্রার্থনা।

মহামান্য,
সবিনয় নিবেদন এই যে, উপরোক্ত মামলার সুষ্ঠু, নিরপেক্ষ ও কার্যকর তদন্তের স্বার্থে ভিকটিম/সাক্ষী ______________________________, পিতা/মাতা/স্বামী ______________________________, ঠিকানা ________________________________________________-এর বিবৃতি ভারতীয় নাগরিক সুরক্ষা সংহিতা, ২০২৩-এর ১৮৩ ধারায় বিজ্ঞ বিচারবিভাগীয় ম্যাজিস্ট্রেটের নিকট লিপিবদ্ধ করা প্রয়োজন। উক্ত ব্যক্তি স্বেচ্ছায় বিজ্ঞ আদালতের নিকট উপস্থিত আছেন/উপস্থিত করানো হলো।

অতএব মহামান্যের নিকট প্রার্থনা, উক্ত ভিকটিম/সাক্ষীর বিবৃতি বিএনএসএস-এর ১৮৩ ধারায় লিপিবদ্ধ করার জন্য সদয় অনুমতি ও প্রয়োজনীয় ব্যবস্থা প্রদান করা হোক।

নিবেদক,

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}''';

  String _prayer183En(OfficerProfile officer, CaseFile caseFile) =>
      '''IN THE COURT OF THE LEARNED ${officer.courtName}

Through: GRO/Court Officer of the concerned Court

Subject: Prayer for recording the statement of the victim/witness under Section 183 BNSS in connection with ${_caseRefEn(officer, caseFile)}.

Most respectfully submitted that, for a fair, impartial and effective investigation of the above-noted case, it is necessary to record the statement of victim/witness ______________________________, son/daughter/wife of ______________________________, residing at ________________________________________________, before the Learned Judicial Magistrate under Section 183 of the Bharatiya Nagarik Suraksha Sanhita, 2023. The said person is present voluntarily before the Learned Court/has been produced before the Learned Court.

It is therefore prayed that the Learned Court may graciously record the statement of the said victim/witness under Section 183 BNSS and pass necessary orders.

Submitted by,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}''';

  String _arrestMemoBn(OfficerProfile officer, CaseFile caseFile) =>
      '''গ্রেপ্তার মেমো
[ভারতীয় নাগরিক সুরক্ষা সংহিতা, ২০২৩ এবং প্রযোজ্য নির্দেশনা অনুযায়ী]

১। গ্রেপ্তারকৃত ব্যক্তির নাম/উপনাম ও পিতা-মাতা/স্বামী-স্ত্রীর নাম:
${_valueOrBlank(caseFile.accusedName, '________________________________________________')}

২। বর্তমান ঠিকানা: ________________________________________________
৩। স্থায়ী ঠিকানা: _________________________________________________
৪। মোবাইল/হোয়াটসঅ্যাপ/ই-মেইল: ____________________________________
৫। মামলার সূত্র: ${_caseRefBn(officer, caseFile)}
৬। গ্রেপ্তারের স্থান: ______________________________________________
৭। গ্রেপ্তারের তারিখ ও সময়: ________________________________________
৮। গ্রেপ্তারের কারণ/ভিত্তি বিস্তারিতভাবে:
   (ক) পরবর্তী অপরাধ প্রতিরোধ: হ্যাঁ/না — ____________________________
   (খ) সুষ্ঠু তদন্তের প্রয়োজন: হ্যাঁ/না — ___________________________
   (গ) প্রমাণ নষ্ট/গোপন/পরিবর্তন রোধ: হ্যাঁ/না — ____________________
   (ঘ) সাক্ষীকে প্রভাবিত/ভয়/প্রলোভন দেওয়া রোধ: হ্যাঁ/না — __________
   (ঙ) আদালতে উপস্থিতি নিশ্চিত করা: হ্যাঁ/না — ______________________
৯। গ্রেপ্তারের কারণ গ্রেপ্তারকৃত ব্যক্তিকে বোধগম্য ভাষায় জানানো হয়েছে: হ্যাঁ/না
১০। গ্রেপ্তারের সংবাদ যাঁকে দেওয়া হয়েছে তাঁর নাম, সম্পর্ক, ঠিকানা ও ফোন:
_______________________________________________________________
সংবাদ প্রদানের তারিখ/সময় ও পদ্ধতি: ________________________________
১১। গ্রেপ্তারকারী অফিসারের নাম, পদবি ও ইউনিট:
${officer.rank} ${officer.name}, ${officer.policeStation}
১২। গ্রেপ্তারকৃত ব্যক্তির শারীরিক অবস্থা/দৃশ্যমান আঘাত:
_______________________________________________________________
১৩। ব্যক্তিগত তল্লাশির বিবরণ ও জব্দকৃত বস্তু: _________________________

গ্রেপ্তারকৃত ব্যক্তির স্বাক্ষর/বাম হাতের ছাপ: ________________________
সাক্ষী–১ (নাম, ঠিকানা ও স্বাক্ষর): __________________________________
সাক্ষী–২ (নাম, ঠিকানা ও স্বাক্ষর): __________________________________

স্থান: ____________________       তারিখ: ____________________

গ্রেপ্তারকারী/তদন্তকারী অফিসারের স্বাক্ষর
${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';

  String _arrestMemoEn(OfficerProfile officer, CaseFile caseFile) =>
      '''ARREST MEMO
[Under the Bharatiya Nagarik Suraksha Sanhita, 2023 and applicable directions]

1. Name/alias and parentage/spouse details of arrestee:
${_valueOrBlank(caseFile.accusedName, '________________________________________________')}

2. Present address: ________________________________________________
3. Permanent address: ______________________________________________
4. Mobile/WhatsApp/e-mail: _________________________________________
5. Case reference: ${_caseRefEn(officer, caseFile)}
6. Place of arrest: ________________________________________________
7. Date and time of arrest: ________________________________________
8. Detailed reasons/grounds of arrest:
   (a) To prevent commission of further offence: Yes/No — ___________
   (b) For proper investigation: Yes/No — ___________________________
   (c) To prevent destruction/concealment/tampering of evidence: _____
   (d) To prevent inducement, threat or influence upon witnesses: ____
   (e) To ensure presence before Court: Yes/No — ____________________
9. Grounds of arrest communicated to arrestee in a language understood: Yes/No
10. Name, relation, address and phone of person informed about arrest:
_______________________________________________________________
Date/time and mode of intimation: __________________________________
11. Name, rank and unit of arresting officer:
${officer.rank} ${officer.name}, ${officer.policeStation}
12. Physical condition/visible injuries of arrestee:
_______________________________________________________________
13. Personal search and articles recovered: _________________________

Signature/thumb impression of arrestee: _____________________________
Witness–1 (name, address and signature): ____________________________
Witness–2 (name, address and signature): ____________________________

Place: ____________________       Date: ____________________

Signature of Arresting/Investigating Officer
${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';

  String _arrestInformationBn(OfficerProfile officer, CaseFile caseFile) =>
      '''মনোনীত ব্যক্তি/আত্মীয়/বন্ধুকে গ্রেপ্তারের সংবাদ

মেমো নং: ____________________                 তারিখ: ____________________

প্রতি,
নাম: ________________________________________________
সম্পর্ক: _____________________________________________
ঠিকানা: ______________________________________________
মোবাইল: ______________________________________________

আপনাকে জানানো যাচ্ছে যে, ${_valueOrBlank(caseFile.accusedName, '____________________________')}-কে ${_caseRefBn(officer, caseFile)}-এর সূত্রে __________ তারিখে ______ ঘটিকায় ______________________________ স্থান থেকে সমস্ত আইনগত বিধান অনুসরণ করে গ্রেপ্তার করা হয়েছে।

গ্রেপ্তারকৃত ব্যক্তির বর্তমান অবস্থান/হেফাজতের স্থান: ____________________
গ্রেপ্তারের কারণ তাঁকে বোধগম্য ভাষায় জানানো হয়েছে। আপনার নাম গ্রেপ্তারকৃত ব্যক্তি মনোনীত ব্যক্তি/আত্মীয়/বন্ধু হিসেবে উল্লেখ করেছেন অথবা আইন অনুযায়ী আপনাকে সংবাদ দেওয়া হচ্ছে।

সংবাদ প্রদানের পদ্ধতি: সরাসরি/ফোন/হোয়াটসঅ্যাপ/ই-মেইল/অন্যান্য __________
সংবাদ প্রদানের তারিখ ও সময়: _______________________________________
গ্রহণকারীর স্বাক্ষর/প্রাপ্তিস্বীকার: _________________________________

${officer.rank} ${officer.name}
তদন্তকারী/গ্রেপ্তারকারী অফিসার
${officer.policeStation}, ${officer.district}
মোবাইল: ${officer.mobile}''';

  String _arrestInformationEn(OfficerProfile officer, CaseFile caseFile) =>
      '''INTIMATION OF ARREST TO NOMINATED PERSON/RELATIVE/FRIEND

Memo No.: ____________________                 Date: ____________________

To,
Name: ________________________________________________
Relationship: _________________________________________
Address: ______________________________________________
Mobile: _______________________________________________

You are hereby informed that ${_valueOrBlank(caseFile.accusedName, '____________________________')} has been arrested in connection with ${_caseRefEn(officer, caseFile)} on __________ at ______ hours from ______________________________ after compliance with all legal requirements.

Present place of custody of the arrestee: ____________________________
The grounds of arrest have been communicated to the arrestee in a language understood by him/her. You have been nominated by the arrestee as a relative/friend/person to be informed, or this intimation is being given to you as required by law.

Mode of intimation: In person/Phone/WhatsApp/E-mail/Other ____________
Date and time of intimation: _______________________________________
Signature/acknowledgement of recipient: _____________________________

${officer.rank} ${officer.name}
Investigating/Arresting Officer
${officer.policeStation}, ${officer.district}
Mobile: ${officer.mobile}''';

  String _medicalExamBn(OfficerProfile officer, CaseFile caseFile) =>
      '''প্রতি,
মেডিক্যাল অফিসার,
________________________________ হাসপাতাল

বিষয়: ${_caseRefBn(officer, caseFile)}-এর সূত্রে চিকিৎসা পরীক্ষার রিকুইজিশন।

মহাশয়/মহাশয়া,
উপরোক্ত মামলার সূত্রে ______________________________, পিতা/মাতা/স্বামী ______________________________, বয়স ______ বছর, লিঙ্গ ______, ঠিকানা ________________________________________________-কে চিকিৎসা পরীক্ষার জন্য প্রেরণ করা হলো।

অনুগ্রহ করে উক্ত ব্যক্তির বিস্তারিত চিকিৎসা পরীক্ষা করে নিম্নলিখিত বিষয়সহ স্বাক্ষরিত ও সিলযুক্ত প্রতিবেদন সরবরাহ করবেন:–
১। শরীরে দৃশ্যমান আঘাতের প্রকৃতি, সংখ্যা, অবস্থান, মাপ, আনুমানিক বয়স ও সম্ভাব্য কারণ।
২। প্রয়োজনীয় নমুনা/সোয়াব/রক্ত/মূত্র/অন্যান্য উপাদান সংগ্রহ ও সিলমোহর করে পুলিশের নিকট হস্তান্তরের বিবরণ।
৩। প্রয়োজনীয় পরীক্ষা, এক্স-রে, ইউএসজি বা বিশেষজ্ঞ মতামত।
৪। চিকিৎসা ও ভর্তি/ছুটির বিবরণ।
৫। আঘাতের চূড়ান্ত মতামত, প্রতিবেদন প্রস্তুত হলে।

পরীক্ষার সময়: ____________     তারিখ: ____________
পুলিশ এসকর্ট/বার্তাবাহক: ______________________________

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}''';

  String _medicalExamEn(OfficerProfile officer, CaseFile caseFile) =>
      '''To,
The Medical Officer,
________________________________ Hospital

Subject: Requisition for medical examination in connection with ${_caseRefEn(officer, caseFile)}.

Sir/Madam,
The following person is being sent for medical examination in connection with the above-noted case: ______________________________, son/daughter/wife of ______________________________, aged about ______ years, sex ______, residing at ________________________________________________.

You are requested to conduct a detailed medical examination and furnish a signed and sealed report covering, inter alia:–
1. Nature, number, site, dimension, approximate age and possible cause of all visible injuries.
2. Collection, sealing and handing over of necessary swab, blood, urine or other samples.
3. Necessary investigation, X-ray, USG or specialist opinion.
4. Treatment, admission and discharge particulars.
5. Final opinion regarding injuries when available.

Time of examination: ____________     Date: ____________
Police escort/messenger: ______________________________

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}''';

  String _bhtInjuryBn(OfficerProfile officer, CaseFile caseFile) =>
      '''প্রতি,
অধীক্ষক/মেডিক্যাল অফিসার,
________________________________ হাসপাতাল

বিষয়: ${_caseRefBn(officer, caseFile)}-এর সূত্রে বিএইচটি, আঘাতের প্রতিবেদন ও চিকিৎসা নথি সরবরাহের রিকুইজিশন।

মহাশয়/মহাশয়া,
উপরোক্ত মামলার তদন্তের স্বার্থে আপনার হাসপাতালে __________ তারিখে চিকিৎসাধীন/ভর্তি হওয়া ______________________________, পিতা/মাতা/স্বামী ______________________________-এর নিম্নলিখিত নথির প্রত্যয়িত অনুলিপি দ্রুত সরবরাহ করার জন্য অনুরোধ করা হলো:–

১। সম্পূর্ণ বেড হেড টিকিট/বিএইচটি ও কেস হিস্ট্রি।
২। ভর্তি, চিকিৎসা, অপারেশন, রেফারাল ও ছুটির নথি।
৩। প্রাথমিক ও চূড়ান্ত আঘাতের প্রতিবেদন।
৪। এক্স-রে/সিটি/এমআরআই/ইউএসজি/ল্যাব রিপোর্ট এবং বিশেষজ্ঞ মতামত।
৫। চিকিৎসকের নাম, পদবি ও স্বাক্ষর নমুনাসহ প্রয়োজনীয় প্রত্যয়ন।
৬। সংরক্ষিত থাকলে এমএলসি/পুলিশ ইনটিমেশন ও সংশ্লিষ্ট রেজিস্টার এন্ট্রি।

উক্ত নথি তদন্তের জন্য জরুরি প্রয়োজন। প্রতিটি পৃষ্ঠা হাসপাতালের সিল ও অনুমোদিত কর্মকর্তার স্বাক্ষরসহ প্রত্যয়িত করার অনুরোধ করা হলো।

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}''';

  String _bhtInjuryEn(OfficerProfile officer, CaseFile caseFile) =>
      '''To,
The Superintendent/Medical Officer,
________________________________ Hospital

Subject: Requisition for BHT, injury report and medical records in connection with ${_caseRefEn(officer, caseFile)}.

Sir/Madam,
For the purpose of investigation of the above-noted case, you are requested to supply at the earliest duly certified copies of the following records relating to ______________________________, son/daughter/wife of ______________________________, who was treated/admitted in your hospital on __________:–

1. Complete Bed Head Ticket/BHT and case history.
2. Admission, treatment, operation, referral and discharge records.
3. Preliminary and final injury reports.
4. X-ray/CT/MRI/USG/laboratory reports and specialist opinions.
5. Name and designation of the treating doctor together with necessary certification.
6. MLC/police intimation and relevant register entry, if maintained.

The above records are urgently required for investigation. Each page may kindly be certified with hospital seal and signature of the authorised officer.

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}''';

  String _cdrCafBn(OfficerProfile officer, CaseFile caseFile) {
    final gist = caseFile.firGist.trim().isEmpty
        ? '____________________________________________________________'
        : caseFile.firGist.trim();
    return '''সিডিআর/এসডিআর/সিএএফ/আইএমইআই রিকুইজিশনের কাঠামোবদ্ধ তথ্য

মামলার রেফারেন্স: ${_caseRefBn(officer, caseFile)}
সংক্ষিপ্ত ঘটনা: $gist
প্রয়োজনীয় মোবাইল নম্বর/আইএমইআই: ________________________________
প্রকৃত ব্যবহারকারী ও মামলার সঙ্গে সংশ্লিষ্টতা: ________________________________
তথ্য চাওয়ার সুনির্দিষ্ট কারণ: ________________________________
সিডিআর-এর সময়সীমা: ____________ থেকে ____________ পর্যন্ত
এসডিআর প্রয়োজন: হ্যাঁ / না
সিএএফ প্রয়োজন: হ্যাঁ / না
আইএমইআই অনুসন্ধান/টাওয়ার ডাম্পের সময়সীমা: ________________________________
প্রয়োজনীয় সেল আইডি/লোকেশন/আইপি ডিটেলস: ________________________________
তদন্তকারী অফিসারের নাম: ${officer.rank} ${officer.name}
তদন্তকারী অফিসারের ফোন: ${officer.mobile}
অন্যান্য বিষয়: প্রযোজ্য নয়

উপরোক্ত তথ্যের ভিত্তিতে সংশ্লিষ্ট নোডাল অফিসারের নিকট আইনানুগ রিকুইজিশন প্রেরণ করা হবে।''';
  }

  String _cdrCafEn(OfficerProfile officer, CaseFile caseFile) {
    final gist = caseFile.firGist.trim().isEmpty
        ? '____________________________________________________________'
        : caseFile.firGist.trim();
    return '''STRUCTURED DETAILS FOR CDR/SDR/CAF/IMEI REQUISITION

Case reference: ${_caseRefEn(officer, caseFile)}
Brief facts: $gist
Required mobile number/IMEI: ________________________________
Actual user and connection with the case: ________________________________
Specific justification for seeking the data: ________________________________
Period for CDR: ____________ to ____________
SDR required: Yes / No
CAF required: Yes / No
Period for IMEI search/tower dump: ________________________________
Required cell ID/location/IP details: ________________________________
Name of Investigating Officer: ${officer.rank} ${officer.name}
Phone of Investigating Officer: ${officer.mobile}
Other particulars: Not applicable

A lawful requisition shall be sent to the concerned Nodal Officer on the basis of the above particulars.''';
  }

  String _bankDetailsBn(OfficerProfile officer, CaseFile caseFile) =>
      '''প্রতি,
শাখা ব্যবস্থাপক/নোডাল অফিসার,
________________________________ ব্যাংক
শাখা: ________________________________

বিষয়: ${_caseRefBn(officer, caseFile)}-এর সূত্রে ব্যাংক হিসাব ও লেনদেন সংক্রান্ত তথ্য সরবরাহ প্রসঙ্গে।

মহাশয়/মহাশয়া,
উপরোক্ত মামলার তদন্তের স্বার্থে হিসাব নং/ইউপিআই আইডি/ওয়ালেট/কার্ড ______________________________ সম্পর্কে নিম্নলিখিত তথ্য দ্রুত সরবরাহ করার জন্য অনুরোধ করা হলো:–

১। হিসাবধারীর পূর্ণ নাম, পিতা/মাতা/স্বামীর নাম, বর্তমান ও স্থায়ী ঠিকানা, মোবাইল নম্বর, ই-মেইল এবং সম্পূর্ণ কেওয়াইসি নথি।
২। হিসাব খোলার ফর্ম, পরিচয় ও ঠিকানার প্রমাণ, নমিনি ও পরিচয়দাতার বিবরণ।
৩। __________ থেকে __________ পর্যন্ত পূর্ণ হিসাব বিবরণী, যেখানে তারিখ, সময়, মূল্য, ইউটিআর/আরআরএন, উৎস ও সুবিধাভোগীর বিবরণ থাকবে।
৪। বিতর্কিত লেনদেনের চ্যানেল, আইপি লগ, ডিভাইস আইডি, লগইন তথ্য, ইউপিআই ভিপিএ, মার্চেন্ট আইডি ও সংশ্লিষ্ট প্রযুক্তিগত তথ্য।
৫। সুবিধাভোগী/গন্তব্য হিসাবের নাম, হিসাব নম্বর, আইএফএসসি, ব্যাংক ও শাখার বিবরণ।
৬। বর্তমান স্থিতি, লিয়েন/হোল্ড/ডেবিট ফ্রিজ/সম্পূর্ণ ফ্রিজের পরিমাণ ও তারিখ।
৭। সংশ্লিষ্ট অন্য হিসাব, মোবাইল, ই-মেইল, ইউপিআই, কার্ড বা ওয়ালেটের বিবরণ।
৮। উপলব্ধ সিসিটিভি ফুটেজ/নগদ উত্তোলনের ছবি ও সংশ্লিষ্ট শাখা/এটিএমের বিবরণ।
৯। আইন অনুযায়ী প্রত্যয়িত ইলেকট্রনিক রেকর্ড ও প্রয়োজনীয় সার্টিফিকেট।

তদন্তের স্বার্থে তথ্যগুলি গোপনীয়ভাবে এবং দ্রুত সরবরাহ করার অনুরোধ করা হলো।

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}
মোবাইল: ${officer.mobile}''';

  String _bankDetailsEn(OfficerProfile officer, CaseFile caseFile) =>
      '''To,
The Branch Manager/Nodal Officer,
________________________________ Bank
Branch: ________________________________

Subject: Supply of bank account and transaction particulars in connection with ${_caseRefEn(officer, caseFile)}.

Sir/Madam,
For the purpose of investigation of the above-noted case, you are requested to furnish at the earliest the following particulars relating to Account No./UPI ID/Wallet/Card ______________________________:–

1. Full name of account holder, parent/spouse name, present and permanent address, mobile number, e-mail and complete KYC documents.
2. Account opening form, identity and address proof, nominee and introducer details.
3. Complete statement of account from __________ to __________ showing date, time, value, UTR/RRN, source and beneficiary details.
4. Channel used for the disputed transaction, IP logs, device ID, login information, UPI VPA, merchant ID and related technical details.
5. Name, account number, IFSC, bank and branch particulars of the beneficiary/destination account.
6. Present balance and particulars of lien/hold/debit freeze/total freeze, including amount and date.
7. Details of any linked account, mobile number, e-mail, UPI ID, card or wallet.
8. Available CCTV footage/image relating to cash withdrawal and particulars of the concerned branch/ATM.
9. Certified electronic records and the certificate required under the applicable law.

The information may kindly be supplied promptly and treated as confidential for the purpose of investigation.

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}
Mobile: ${officer.mobile}''';

  String _fslBn(OfficerProfile officer, CaseFile caseFile) {
    final gist = caseFile.firGist.trim().isEmpty
        ? 'মামলার সংক্ষিপ্ত ঘটনা: ________________________________________________'
        : caseFile.firGist.trim();
    return '''এফএসএল ফর্ম, আলামত তালিকা, পরীক্ষার প্রশ্ন, চালান ও লেবেলের কাঠামোবদ্ধ তথ্য

মামলার রেফারেন্স: ${_caseRefBn(officer, caseFile)}
অপরাধের প্রকৃতি/সংক্ষিপ্ত ঘটনা: $gist
আলামতসমূহ: ক | একটি সিলমোহরযুক্ত প্যাকেট/জার/পাত্র, যার মধ্যে ________________________________ আছে বলে উল্লেখ | __________ তারিখে ________________________________ স্থান থেকে ${officer.rank} ${officer.name} কর্তৃক জব্দ/________________ থেকে প্রাপ্ত | বিজ্ঞ সিজেএম/ম্যাজিস্ট্রেট, ${officer.district} | পরীক্ষার পরে রাষ্ট্রের অনুকূলে বাজেয়াপ্ত/ফেরতযোগ্য
প্রয়োজনীয় পরীক্ষার প্রকৃতি: ১) আলামত চিহ্ন “ক”-তে বিষ/রক্ত/বীর্য/জৈব পদার্থ/রাসায়নিক/বিস্ফোরক/মাদক/ডিজিটাল চিহ্ন বা অন্য কোনো প্রাসঙ্গিক উপাদান শনাক্ত করা যায় কি না।\n২) শনাক্ত হলে উক্ত উপাদানের প্রকৃতি, ধরন, উৎস এবং মামলার ঘটনার সঙ্গে প্রাসঙ্গিকতা কী।\n৩) পরীক্ষাকালে উদ্ভূত অন্য কোনো প্রাসঙ্গিক বিষয় সম্পর্কে মতামত।
হেফাজতে থাকা ব্যক্তিবর্গ: ${caseFile.accusedName.trim().isEmpty ? 'অভিযুক্তের নাম ও ঠিকানা' : caseFile.accusedName} | পেশা | বয়স | লিঙ্গ | গ্রেপ্তারের তারিখ ও সময় | বিচারবিভাগীয় হেফাজত/পুলিশ হেফাজত/জামিন/পলাতক | বিজ্ঞ আদালত
এফএসএল কার্যালয়: দপ্তর প্রধান ও সহকারী পরিচালক\nআঞ্চলিক ফরেনসিক বিজ্ঞানাগার\nশংকরপুর, দুর্গাপুর\nপশ্চিম বর্ধমান, ৭১৩২১২
আদালত: বিজ্ঞ সিজেএম/ম্যাজিস্ট্রেট, ${officer.district}
তদন্তকারী অফিসার/থানার যোগাযোগ: নাম–${officer.name}; পদবি–${officer.rank}; মোবাইল–${officer.mobile}; থানা–${officer.policeStation}; জেলা–${officer.district}

উপরোক্ত তথ্য অনুযায়ী ফর্ম ৫২০৩, আলামত তালিকা, পরীক্ষার প্রশ্ন, হেফাজতে থাকা ব্যক্তির বিবরণ, ম্যাজিস্ট্রেটের ফরওয়ার্ডিং/প্রত্যয়ন, চালান ও লেবেল প্রস্তুত হবে।''';
  }

  String _fslEn(OfficerProfile officer, CaseFile caseFile) {
    final gist = caseFile.firGist.trim().isEmpty
        ? 'Brief facts of the case: ________________________________________________'
        : caseFile.firGist.trim();
    return '''STRUCTURED DETAILS FOR FSL FORM, EXHIBIT LIST, EXAMINATION QUERIES, CHALLAN AND LABELS

Case reference: ${_caseRefEn(officer, caseFile)}
Nature of offence/brief facts: $gist
Exhibits: A | One sealed packet/jar/container stated to contain ________________________________ | Seized/received on __________ from ________________________________ by ${officer.rank} ${officer.name} | Learned CJM/Magistrate, ${officer.district} | To be confiscated to the State/returned after examination
Nature of examination required: 1) Whether poison/blood/semen/biological material/chemical/explosive/narcotic/digital trace or any other relevant material can be detected in Exhibit “A”.\n2) If detected, its nature, type, source and relevance to the facts of the case.\n3) Opinion on any other relevant matter arising during examination.
Persons in custody: ${caseFile.accusedName.trim().isEmpty ? 'Name and address of accused' : caseFile.accusedName} | Occupation | Age | Sex | Date and time of arrest | Judicial custody/police custody/bail/absconding | Learned Court
FSL office: Head of Office and Assistant Director\nRegional Forensic Science Laboratory\nShankarpur, Durgapur\nPaschim Bardhaman – 713212
Court: Learned CJM/Magistrate, ${officer.district}
Contact particulars of IO/Police Station: Name–${officer.name}; Rank–${officer.rank}; Mobile–${officer.mobile}; Police Station–${officer.policeStation}; District–${officer.district}

Form 5203, exhibit list, examination queries, custody particulars, Magistrate's forwarding/certification, challan and labels shall be prepared from the above particulars.''';
  }

  String _forwardingBn(OfficerProfile officer, CaseFile caseFile) {
    final complainant = caseFile.complainantName.trim().isEmpty
        ? '____________________________'
        : caseFile.complainantName.trim();
    final gist = caseFile.firGist.trim().isEmpty
        ? '____________________________________________________________________________'
        : caseFile.firGist.trim();
    return '''মাননীয় ${officer.courtName}-এর আদালতে
মারফত: জিআরও/কোর্ট অফিসার, সংশ্লিষ্ট আদালত

রেফারেন্স: ${_caseRefBn(officer, caseFile)}।

বিষয়: গ্রেপ্তারকৃত অভিযুক্ত ______________________________-কে বিজ্ঞ আদালতে প্রেরণ এবং বিচারবিভাগীয়/পুলিশ হেফাজতের প্রার্থনা।

মহামান্য,
সবিনয় জানাচ্ছি যে, গ্রেপ্তারকৃত অভিযুক্ত ______________________________, পিতা/মাতা/স্বামী ______________________________, বয়স ______ বছর, ঠিকানা ________________________________________________, থানা ____________________, জেলা ____________________-কে সংশ্লিষ্ট কাগজপত্র ও যথাযথ পুলিশ পাহারায় মহামান্যের আদালতে প্রেরণ করা হলো।

মামলার সংক্ষিপ্ত ঘটনা এই যে, __________ তারিখে ______ ঘটিকায় $complainant-এর নিকট থেকে একটি লিখিত অভিযোগ প্রাপ্ত হয়। অভিযোগের সংক্ষিপ্ত বিষয়: $gist। উক্ত অভিযোগের ভিত্তিতে উপরোক্ত মামলা রুজু হয় এবং নির্দেশক্রমে আমি তদন্তভার গ্রহণ করি।

তদন্তকালে ঘটনাস্থল পরিদর্শন করে সূচিসহ খসড়া নকশা প্রস্তুত করা হয়েছে/হবে; অভিযোগকারী ও উপলব্ধ সাক্ষীদের পরীক্ষা করে বিএনএসএস-এর ১৮০ ধারায় বিবৃতি লিপিবদ্ধ করা হয়েছে; প্রাসঙ্গিক নথি, ডিজিটাল তথ্য ও আলামত সংগ্রহ/জব্দের ব্যবস্থা গ্রহণ করা হয়েছে। সংগৃহীত তথ্য ও প্রমাণের ভিত্তিতে অভিযুক্তের বিরুদ্ধে প্রাথমিকভাবে সংশ্লিষ্টতার উপাদান পাওয়া যায়।

__________ তারিখে ______ ঘটিকায় সমস্ত আইনগত বিধান অনুসরণ করে অভিযুক্তকে ______________________________ স্থান থেকে গ্রেপ্তার করা হয়। গ্রেপ্তারের কারণ অভিযুক্তকে এবং তাঁর মনোনীত আত্মীয়/বন্ধুকে বোধগম্য ভাষায় জানানো হয়েছে। গ্রেপ্তার মেমো প্রস্তুত, ব্যক্তিগত তল্লাশি, চিকিৎসা পরীক্ষা এবং গ্রেপ্তার সংক্রান্ত প্রয়োজনীয় সংবাদ প্রদান করা হয়েছে।

অভিযুক্তকে হেফাজতে রাখার প্রয়োজনীয় কারণ:–
১। মামলাটি তদন্তের গুরুত্বপূর্ণ পর্যায়ে রয়েছে এবং আরও সাক্ষী পরীক্ষা ও নথি/আলামত সংগ্রহ বাকি রয়েছে।
২। জামিনে মুক্ত হলে অভিযুক্ত সাক্ষীদের প্রভাবিত, ভয় প্রদর্শন বা প্রমাণ নষ্ট/পরিবর্তন করতে পারেন।
৩। সহ-অভিযুক্তের সন্ধান, চোরাই/ব্যবহৃত সম্পত্তি উদ্ধার, ঘটনার পুনর্গঠন বা অন্যান্য গুরুত্বপূর্ণ তথ্য সংগ্রহের প্রয়োজন রয়েছে।
৪। অভিযুক্ত পলাতক হওয়ার বা বিচার প্রক্রিয়া এড়িয়ে যাওয়ার সম্ভাবনা রয়েছে।
৫। তদন্তের স্বার্থে প্রয়োজন অনুসারে পুলিশ হেফাজতে জিজ্ঞাসাবাদ/বিচারবিভাগীয় হেফাজত প্রয়োজন।

অতএব মহামান্যের নিকট প্রার্থনা, গ্রেপ্তারকৃত অভিযুক্তকে ______ দিনের পুলিশ হেফাজত/বিচারবিভাগীয় হেফাজতে নেওয়া এবং তাঁর জামিনের আবেদন নাকচ করার সদয় আদেশ প্রদান করা হোক।

সংযুক্তি:–
১। এফআইআর/আনুষ্ঠানিক এফআইআরের অনুলিপি।
২। গ্রেপ্তার মেমো ও গ্রেপ্তারের কারণ।
৩। ব্যক্তিগত তল্লাশি/পরিদর্শন মেমো।
৪। চিকিৎসা পরীক্ষার কাগজপত্র।
৫। মনোনীত ব্যক্তিকে সংবাদ প্রদানের নথি।
৬। প্রযোজ্য অন্যান্য নথি।

নিবেদক,

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}''';
  }

  String _forwardingEn(OfficerProfile officer, CaseFile caseFile) {
    final complainant = caseFile.complainantName.trim().isEmpty
        ? '____________________________'
        : caseFile.complainantName.trim();
    final gist = caseFile.firGist.trim().isEmpty
        ? '____________________________________________________________________________'
        : caseFile.firGist.trim();
    return '''IN THE COURT OF THE LEARNED ${officer.courtName}
Through: GRO/Court Officer of the concerned Court

Reference: ${_caseRefEn(officer, caseFile)}.

Subject: Forwarding of arrested accused ______________________________ before the Learned Court with prayer for judicial/police custody.

Most respectfully submitted that the arrested accused, namely ______________________________, son/daughter/wife of ______________________________, aged about ______ years, residing at ________________________________________________, P.S. ____________________, District ____________________, is being forwarded before the Learned Court under proper police escort along with the connected papers.

The brief facts of the case are that on __________ at about ______ hours, a written complaint was received from $complainant alleging, inter alia, that: $gist. On the basis of the said complaint, the above-noted case was registered and the investigation was endorsed to the undersigned.

During investigation, the place of occurrence has been/will be visited and a rough sketch map with index prepared; the complainant and available witnesses have been examined and their statements recorded under Section 180 BNSS; and steps have been taken to collect/seize relevant records, digital data and exhibits. The materials collected so far disclose prima facie involvement of the accused in the offence under investigation.

On __________ at ______ hours, the accused was arrested from ______________________________ after compliance with all legal requirements. The grounds of arrest were communicated to the accused and to the relative/friend nominated by the accused in a language understood by them. Arrest memo, personal search, medical examination and arrest intimation have been completed as required by law.

Custody is necessary for the following reasons:–
1. Investigation is at a crucial stage and examination of material witnesses and collection of records/exhibits remain pending.
2. If released on bail, the accused may influence or intimidate witnesses or destroy, conceal or tamper with evidence.
3. Search for co-accused, recovery of stolen/used property, reconstruction of the occurrence or collection of other material information is required.
4. There is a reasonable apprehension that the accused may abscond or evade the process of law.
5. Police custody interrogation/judicial custody is necessary in the interest of investigation, as applicable.

It is therefore prayed that the Learned Court may be pleased to remand the arrested accused to police custody for ______ days/judicial custody and reject the prayer for bail.

Enclosures:–
1. Copy of FIR/Formal FIR.
2. Arrest memo and grounds of arrest.
3. Personal search/inspection memo.
4. Medical examination papers.
5. Record of intimation to nominated person.
6. Other applicable documents.

Submitted by,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}''';
  }

  String _furtherInvestigationBn(OfficerProfile officer, CaseFile caseFile) =>
      '''মাননীয় ${officer.courtName}-এর আদালতে

বিষয়: ${_caseRefBn(officer, caseFile)}-এর সূত্রে পরবর্তী তদন্ত/সময় বৃদ্ধি/অনুবর্তিতার প্রার্থনা।

মহামান্য,
সবিনয় নিবেদন এই যে, উপরোক্ত মামলায় নিম্নলিখিত গুরুত্বপূর্ণ তদন্তমূলক কাজ সম্পন্ন করা এখনও বাকি রয়েছে:–

১। ________________________________________________
২। ________________________________________________
৩। ________________________________________________
৪। ________________________________________________

উক্ত কার্যগুলি সম্পন্ন না হলে মামলার সুষ্ঠু ও পূর্ণাঙ্গ তদন্ত ব্যাহত হতে পারে। বিলম্বের কারণ: ________________________________________________। এ পর্যন্ত গৃহীত পদক্ষেপ: ________________________________________________।

অতএব মহামান্যের নিকট প্রার্থনা, নিম্নস্বাক্ষরকারীকে প্রয়োজনীয় পরবর্তী তদন্ত/অনুবর্তিতা সম্পন্ন করার জন্য ______ দিন সময়/সদয় অনুমতি প্রদান করা হোক।

নিবেদক,

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}''';

  String _furtherInvestigationEn(OfficerProfile officer, CaseFile caseFile) =>
      '''IN THE COURT OF THE LEARNED ${officer.courtName}

Subject: Prayer for further investigation/extension of time/compliance in connection with ${_caseRefEn(officer, caseFile)}.

Most respectfully submitted that the following important steps of investigation in the above-noted case are yet to be completed:–

1. ________________________________________________
2. ________________________________________________
3. ________________________________________________
4. ________________________________________________

Non-completion of the above steps may prejudice a fair and complete investigation. Reason for delay: ________________________________________________. Steps already taken: ________________________________________________.

It is therefore prayed that the Learned Court may graciously allow the undersigned ______ days' time/permission to complete the necessary further investigation and compliance.

Submitted by,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}''';

  String _memoEvidenceBn(OfficerProfile officer, CaseFile caseFile) =>
      '''সাক্ষ্য-প্রমাণের স্মারক

১। এসএ নং: ______________________________
২। মামলার সূত্র: ${_caseRefBn(officer, caseFile)}
৩। অভিযোগকারীর নাম, বয়স, লিঙ্গ, পিতা-মাতা/স্বামী ও ঠিকানা:
${_valueOrBlank(caseFile.complainantName, '________________________________________________')}
৪। ঘটনাস্থল ও ঘটনার তারিখ/সময়:
${_valueOrBlank(caseFile.placeOfOccurrence, '____________________________')}; ${_valueOrBlank(caseFile.dateTimeOccurrence, '____________________________')}
৫। ভিকটিম/মৃত ব্যক্তির বিবরণ: ${_valueOrBlank(caseFile.victimName, 'প্রযোজ্য নয়')}
৬। এফআইআরের সংক্ষিপ্ত ঘটনা: ${_valueOrBlank(caseFile.firGist, '____________________________')}
৭। তদন্তকারী অফিসার: ${officer.rank} ${officer.name}; তদন্তকাল: ${caseFile.caseDate} থেকে অদ্যাবধি; সিডি নং: ১ থেকে ______
৮। এফআইআর-নামীয় অভিযুক্তদের তালিকা:
ক্রমিক | নাম ও পিতা-মাতা | ঠিকানা | গ্রেপ্তারের তারিখ | বর্তমান অবস্থা | জামিনের তারিখ
১ | ${_valueOrBlank(caseFile.accusedName, '____________________________')} | __________ | __________ | __________ | __________
৯। তদন্তে প্রকাশিত অন্যান্য অভিযুক্ত: নেই/____________________________
১০। জব্দের বিবরণ:
ক্রমিক | জব্দকৃত বস্তু/নথি | লেবেল | তারিখ | জিডিই | সম্পত্তি রেজিস্টার নং
১১। বিএনএসএস ১৮০ ধারার সাক্ষ্যবিবৃতি:
ক্রমিক | সাক্ষীর নাম ও ঠিকানা | পরীক্ষার তারিখ | সম্পর্ক | সাক্ষ্যের প্রকৃতি
১২। বিএনএসএস ১৮৩ ধারার বিবৃতি:
ক্রমিক | ব্যক্তির নাম ও ঠিকানা | তারিখ | সম্পর্ক | বক্তব্যের প্রকৃতি
১৩। চিকিৎসা/আঘাত/বিএইচটি প্রতিবেদন: ______________________________
১৪। সুরতহাল ও ময়নাতদন্ত প্রতিবেদন: _________________________________
১৫। এফএসএল/বিশেষজ্ঞ/ডিজিটাল প্রতিবেদন: ____________________________
১৬। টিআই প্যারেড/অন্যান্য প্রক্রিয়া: _________________________________
১৭। প্রমাণের চার্ট—প্রতিটি অভিযুক্তের বিরুদ্ধে প্রমাণযোগ্য বিষয় ও সংগৃহীত প্রমাণ:
_______________________________________________________________
১৮। প্রাথমিক অভিযোগ ও সংগৃহীত প্রমাণের বিশ্লেষণ:
_______________________________________________________________
১৯। মামলার শক্তি, দুর্বলতা, অসম্পন্ন তদন্ত ও তদন্তকারী অফিসারের মতামত:
_______________________________________________________________

নিবেদক,
${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}, ${officer.district}

আইসি/ওসির মতামত: _______________________________________________
ঊর্ধ্বতন অফিসারের মতামত: _________________________________________
চূড়ান্ত আদেশ: ____________________________________________________''';

  String _memoEvidenceEn(OfficerProfile officer, CaseFile caseFile) =>
      '''MEMO OF EVIDENCE

1. SA No.: ______________________________
2. Case reference: ${_caseRefEn(officer, caseFile)}
3. Name, age, sex, parentage/spouse and address of complainant:
${_valueOrBlank(caseFile.complainantName, '________________________________________________')}
4. Place and date/time of occurrence:
${_valueOrBlank(caseFile.placeOfOccurrence, '____________________________')}; ${_valueOrBlank(caseFile.dateTimeOccurrence, '____________________________')}
5. Victim/deceased particulars: ${_valueOrBlank(caseFile.victimName, 'Not applicable')}
6. Gist of FIR: ${_valueOrBlank(caseFile.firGist, '____________________________')}
7. Investigating Officer: ${officer.rank} ${officer.name}; period of investigation: ${caseFile.caseDate} till date; CD No. I to ______
8. FIR-named accused:
Sl. | Name and parentage | Address | Date of arrest | Present status | Date of bail
1 | ${_valueOrBlank(caseFile.accusedName, '____________________________')} | __________ | __________ | __________ | __________
9. Other accused whose names transpired: Nil/_________________________
10. Seizure particulars:
Sl. | Article/document seized | Label | Date | GDE | Property Register No.
11. Statements under Section 180 BNSS:
Sl. | Name and address of witness | Date of examination | Relation | Nature of evidence
12. Statements under Section 183 BNSS:
Sl. | Name and address | Date | Relation | Nature of statement
13. Medical/injury/BHT report: ______________________________________
14. Inquest and post-mortem report: _________________________________
15. FSL/expert/digital report: ______________________________________
16. TI parade/other proceedings: ___________________________________
17. Evidence chart—facts to be proved and evidence against each accused:
_______________________________________________________________
18. Analysis of prima facie charge and evidence collected:
_______________________________________________________________
19. Strength, weakness, pending investigation and opinion of I.O.:
_______________________________________________________________

Submitted by,
${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}, ${officer.district}

Opinion of I.C./O.C.: ______________________________________________
Opinion of Superior Officer: _______________________________________
Final order: _______________________________________________________''';

  String _form54Bn(OfficerProfile officer, CaseFile caseFile) =>
      '''ফর্ম ৫৪ — দুর্ঘটনা তথ্য প্রতিবেদন
[প্রযোজ্য মোটরযান বিধি অনুযায়ী]

১। থানার নাম: ${officer.policeStation}
২। এফআইআর/সিআর/দুর্ঘটনা প্রতিবেদন নং: ${caseFile.psCaseNo}
২(ক)। প্রযোজ্য ধারা: ${caseFile.sections}
৩। দুর্ঘটনার তারিখ, সময় ও স্থান: ${_valueOrBlank(caseFile.dateTimeOccurrence, '____________________________')} — ${_valueOrBlank(caseFile.placeOfOccurrence, '____________________________')}
৪। আহত/মৃত ব্যক্তির নাম ও পূর্ণ ঠিকানা: ${_valueOrBlank(caseFile.victimName, '____________________________')}
৫। যে হাসপাতালে নেওয়া হয়েছে: ______________________________________
৬। সংশ্লিষ্ট গাড়ির রেজিস্ট্রেশন নং ও ধরন: ___________________________
৭। চালকের বিবরণ:
   (ক) নাম ও ঠিকানা: ______________________________________________
   (খ) ড্রাইভিং লাইসেন্স নং ও মেয়াদ: _______________________________
   (গ) লাইসেন্স প্রদানকারী কর্তৃপক্ষ: _______________________________
   (ঘ) পাবলিক সার্ভিস গাড়ির ক্ষেত্রে ব্যাজ নং: ______________________
৮। দুর্ঘটনার সময় গাড়ির মালিকের নাম ও ঠিকানা: ________________________
৯। বীমা কোম্পানি ও বিভাগীয় কার্যালয়ের নাম/ঠিকানা: __________________
১০। বীমা পলিসি/সার্টিফিকেট নং ও বৈধতার মেয়াদ: ______________________
১১। গাড়ির নিবন্ধন বিবরণ:
   (ক) রেজিস্ট্রেশন নং: ____________________________________________
   (খ) ইঞ্জিন/মোটর নং: _____________________________________________
   (গ) চ্যাসিস নং: _________________________________________________
১২। রুট পারমিট/ব্যবহারের অনুমতির বিবরণ: _____________________________
১৩। গৃহীত ব্যবস্থা ও ফলাফল: _______________________________________

প্রস্তুতকারী,
${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';

  String _form54En(OfficerProfile officer, CaseFile caseFile) =>
      '''FORM 54 — ACCIDENT INFORMATION REPORT
[Under the applicable Motor Vehicles Rules]

1. Name of Police Station: ${officer.policeStation}
2. FIR/CR/Accident Report No.: ${caseFile.psCaseNo}
2A. Sections applied: ${caseFile.sections}
3. Date, time and place of accident: ${_valueOrBlank(caseFile.dateTimeOccurrence, '____________________________')} — ${_valueOrBlank(caseFile.placeOfOccurrence, '____________________________')}
4. Name and full address of injured/deceased: ${_valueOrBlank(caseFile.victimName, '____________________________')}
5. Hospital to which removed: ______________________________________
6. Registration number and type of vehicle: _________________________
7. Driver particulars:
   (a) Name and address: ___________________________________________
   (b) Driving licence number and validity: _________________________
   (c) Licensing authority: ________________________________________
   (d) Badge No. for public service vehicle: ________________________
8. Name and address of owner at the time of accident: ______________
9. Name/address of insurer and divisional office: ___________________
10. Insurance policy/certificate number and validity: ______________
11. Registration particulars:
   (a) Registration No.: ___________________________________________
   (b) Engine/motor No.: ___________________________________________
   (c) Chassis No.: ________________________________________________
12. Route permit/licence-of-use particulars: ________________________
13. Action taken and result: _______________________________________

Prepared by,
${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';

  String _inquest196Bn(OfficerProfile officer, CaseFile caseFile) =>
      '''বিএনএসএস, ২০২৩-এর ১৯৬ ধারায় সুরতহাল প্রতিবেদন

১। রাজ্য: পশ্চিমবঙ্গ     জেলা: ${officer.district}     থানা: ${officer.policeStation}
২। জিডিই/ইউডি/মামলা নং ও তারিখ: _________________________________
৩। তথ্য প্রাপ্তির তারিখ, সময় ও স্থান: ______________________________
৪। তথ্যের সারমর্ম ও তথ্যদাতার পরিচয়: ______________________________
৫। মৃতদেহ পাওয়ার স্থান: ${_valueOrBlank(caseFile.placeOfOccurrence, '____________________________')}
৬। সুরতহাল শুরু ও শেষের তারিখ/সময়: _______________________________
৭। মৃতদেহ প্রদর্শন/উদ্ধারকারী ব্যক্তির নাম ও ঠিকানা: _______________
৮। মৃতদেহ শনাক্তকারীর নাম, ঠিকানা ও সম্পর্ক: ______________________
৯। মৃত ব্যক্তির নাম, লিঙ্গ, আনুমানিক বয়স ও ঠিকানা:
${_valueOrBlank(caseFile.victimName, '________________________________________________')}
১০। মৃতদেহের অবস্থান, পোশাক, শনাক্তকরণ চিহ্ন ও শারীরিক বিবরণ:
_______________________________________________________________
১১। বাহ্যিক আঘাত, দাগ, রক্তপাত, গলার দাগ বা অন্য অস্বাভাবিক চিহ্ন:
_______________________________________________________________
১২। ঘটনাস্থলের অবস্থা এবং পাওয়া অস্ত্র/বস্তু/ওষুধ/পাত্র/দড়ি ইত্যাদি:
_______________________________________________________________
১৩। সাক্ষীদের নাম ও ঠিকানা:
   (১) ___________________________________________________________
   (২) ___________________________________________________________
১৪। মৃত্যুর সম্ভাব্য কারণ সম্পর্কে প্রাথমিক মতামত:
_______________________________________________________________
১৫। মৃতদেহ ময়নাতদন্তে প্রেরণ/অন্য ব্যবস্থা ও চালানের বিবরণ:
_______________________________________________________________
১৬। সংক্ষিপ্ত ঘটনা: ${_valueOrBlank(caseFile.firGist, '____________________________')}
১৭। মন্তব্য: ______________________________________________________

সাক্ষীদের স্বাক্ষর: ১) ____________________  ২) ____________________

${officer.rank} ${officer.name}
অনুসন্ধানকারী অফিসার
${officer.policeStation}, ${officer.district}''';

  String _inquest196En(OfficerProfile officer, CaseFile caseFile) =>
      '''INQUEST REPORT UNDER SECTION 196 BNSS, 2023

1. State: West Bengal     District: ${officer.district}     P.S.: ${officer.policeStation}
2. GDE/UD/Case No. and date: ______________________________________
3. Date, time and place of receipt of information: _________________
4. Substance of information and identity of informant: ____________
5. Place where dead body was found: ${_valueOrBlank(caseFile.placeOfOccurrence, '____________________________')}
6. Date/time of commencement and completion of inquest: ___________
7. Name and address of person who showed/recovered the body: _______
8. Name, address and relationship of identifier: ___________________
9. Name, sex, approximate age and address of deceased:
${_valueOrBlank(caseFile.victimName, '________________________________________________')}
10. Position, dress, identification marks and physical description:
_______________________________________________________________
11. External injuries, marks, bleeding, ligature mark or abnormality:
_______________________________________________________________
12. Condition of scene and weapon/article/medicine/container/rope found:
_______________________________________________________________
13. Names and addresses of witnesses:
   (1) ___________________________________________________________
   (2) ___________________________________________________________
14. Preliminary opinion regarding probable cause of death:
_______________________________________________________________
15. Dispatch for post-mortem/other disposal and challan particulars:
_______________________________________________________________
16. Brief facts: ${_valueOrBlank(caseFile.firGist, '____________________________')}
17. Remarks: ______________________________________________________

Signatures of witnesses: 1) __________________  2) __________________

${officer.rank} ${officer.name}
Enquiry Officer
${officer.policeStation}, ${officer.district}''';

  String _csChecklistBn(OfficerProfile officer, CaseFile caseFile) =>
      '''অভিযোগপত্র/চূড়ান্ত প্রতিবেদন দাখিল-পূর্ব যাচাইতালিকা

মামলার রেফারেন্স: ${_caseRefBn(officer, caseFile)}
তদন্তকারী অফিসার: ${officer.rank} ${officer.name}

[ ] এফআইআর/আনুষ্ঠানিক এফআইআর ও মূল অভিযোগপত্র সংযুক্ত।
[ ] ঘটনাস্থলের সূচিসহ খসড়া নকশা সংযুক্ত।
[ ] বিএনএসএস-এর ১৮০ ধারার সাক্ষ্যবিবৃতি সংযুক্ত।
[ ] বিএনএসএস-এর ১৮৩ ধারার বিচারবিভাগীয় বিবৃতি, প্রযোজ্য ক্ষেত্রে, সংযুক্ত।
[ ] জব্দতালিকা, মালখানা রেফারেন্স ও আলামতের হেফাজত-শৃঙ্খল সংযুক্ত।
[ ] চিকিৎসা, আঘাত, বিএইচটি, ময়নাতদন্ত ও বয়স নির্ধারণের প্রতিবেদন সংযুক্ত।
[ ] এফএসএল/বিশেষজ্ঞ প্রতিবেদন ও ফরওয়ার্ডিং নথি সংযুক্ত।
[ ] সিডিআর/সিএএফ/ব্যাংক/ডিজিটাল প্রমাণ এবং প্রযোজ্য সার্টিফিকেট সংযুক্ত।
[ ] গ্রেপ্তার মেমো, গ্রেপ্তারের কারণ, ফরওয়ার্ডিং ও হেফাজতের নথি সংযুক্ত।
[ ] অভিযুক্তের নাম, পরিচয়, ঠিকানা ও পূর্ব ইতিহাস যাচাই করা হয়েছে।
[ ] সাক্ষী তালিকা, নথি তালিকা ও সম্পত্তি/আলামত তালিকা প্রস্তুত।
[ ] আইনগত ধারা ও অপরাধের উপাদান প্রমাণের সঙ্গে মিলিয়ে যাচাই করা হয়েছে।
[ ] প্রযোজ্য অনুমোদন/স্যানকশন/প্রসিকিউশন অনুমতি সংগ্রহ করা হয়েছে।
[ ] বিএনএসএস-এর ২৩০ ধারার অধীন নথি সরবরাহের ইনডেক্স প্রস্তুত।
[ ] চূড়ান্ত মতামত, অভিযোগপত্র/চূড়ান্ত প্রতিবেদনের ভিত্তি ও অসম্পন্ন তদন্তের কারণ নথিভুক্ত।

মন্তব্য:
________________________________________________
________________________________________________

প্রস্তুতকারী,
${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}''';

  String _csChecklistEn(OfficerProfile officer, CaseFile caseFile) =>
      '''PRE-SUBMISSION CHECKLIST FOR CHARGE SHEET/FINAL REPORT

Case reference: ${_caseRefEn(officer, caseFile)}
Investigating Officer: ${officer.rank} ${officer.name}

[ ] FIR/Formal FIR and original complaint enclosed.
[ ] Rough sketch map with index of the place of occurrence enclosed.
[ ] Statements of witnesses under Section 180 BNSS enclosed.
[ ] Judicial statements under Section 183 BNSS enclosed wherever applicable.
[ ] Seizure lists, malkhana references and chain of custody of exhibits enclosed.
[ ] Medical, injury, BHT, post-mortem and age-determination reports enclosed.
[ ] FSL/expert reports and forwarding records enclosed.
[ ] CDR/CAF/bank/digital evidence and applicable certificates enclosed.
[ ] Arrest memo, grounds of arrest, forwarding and custody papers enclosed.
[ ] Identity, address and antecedents of accused verified.
[ ] Witness list, document list and property/exhibit list prepared.
[ ] Legal sections and ingredients of offences verified against collected evidence.
[ ] Applicable sanction/approval/prosecution permission obtained.
[ ] Indexed supply-of-documents set under Section 230 BNSS prepared.
[ ] Final opinion, basis of charge sheet/final report and reason for pending investigation recorded.

Remarks:
________________________________________________
________________________________________________

Prepared by,
${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _genericBn(OfficerProfile officer, CaseFile caseFile) =>
      '''রেফারেন্স: ${_caseRefBn(officer, caseFile)}

খসড়া বিবরণ:
________________________________________________
________________________________________________
________________________________________________

${officer.rank} ${officer.name}
তদন্তকারী অফিসার
${officer.policeStation}''';

  String _genericEn(OfficerProfile officer, CaseFile caseFile) =>
      '''Reference: ${_caseRefEn(officer, caseFile)}

Draft particulars:
________________________________________________
________________________________________________
________________________________________________

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';
}
