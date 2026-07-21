import '../models/case_file.dart';

class SopRule {
  final String title;
  final String detail;
  final String sectionRef;
  final bool mandatory;
  final String category;

  const SopRule({
    required this.title,
    required this.detail,
    required this.sectionRef,
    required this.mandatory,
    required this.category,
  });
}

class SopComplianceService {
  static const List<String> sexualOffenceSections = [
    '64', '65', '66', '67', '68', '69', '70', '71',
    '74', '75', '76', '77', '78', '79', '124',
  ];

  static const List<String> pocsoSections = ['4', '6', '8', '10'];

  bool _hasSection(CaseFile file, String section) {
    final normalized = file.sections.toLowerCase().replaceAll(RegExp(r'[^0-9a-z]+'), ' ');
    return RegExp('(^| )${RegExp.escape(section.toLowerCase())}( |\$)').hasMatch(normalized) ||
        file.sections.toLowerCase().contains('section $section') ||
        file.sections.toLowerCase().contains('/$section') ||
        file.sections.toLowerCase().contains('$section ');
  }

  bool hasSexualOrVulnerableOffence(CaseFile file) {
    final lower = file.sections.toLowerCase();
    return lower.contains('pocso') || sexualOffenceSections.any((s) => _hasSection(file, s));
  }

  bool hasPocsoTimeBoundOffence(CaseFile file) {
    final lower = file.sections.toLowerCase();
    if (!lower.contains('pocso')) return false;
    return pocsoSections.any((s) => _hasSection(file, s));
  }

  bool isElectronicEvidenceCase(CaseFile file) {
    final lower = '${file.sections} ${file.firGist} ${file.investigationStart.evidenceDetails}'.toLowerCase();
    return lower.contains('mobile') || lower.contains('cctv') || lower.contains('cdr') ||
        lower.contains('caf') || lower.contains('upi') || lower.contains('bank') ||
        lower.contains('electronic') || lower.contains('digital') || lower.contains('device');
  }

  bool likelySeriousOffence(CaseFile file) {
    final lower = file.sections.toLowerCase();
    return lower.contains('103') || lower.contains('109') || lower.contains('302') ||
        lower.contains('307') || lower.contains('376') || lower.contains('pocso') ||
        lower.contains('life') || lower.contains('death');
  }

  List<SopRule> buildRules(CaseFile file) {
    final sexual = hasSexualOrVulnerableOffence(file);
    final electronic = isElectronicEvidenceCase(file);
    final serious = likelySeriousOffence(file);
    final pocsoTimeBound = hasPocsoTimeBoundOffence(file);

    final rules = <SopRule>[
      const SopRule(
        category: 'এফআইআর/মামলা রুজু',
        title: 'ইলেকট্রনিক তথ্যের ক্ষেত্রে ৩ দিনের মধ্যে স্বাক্ষর',
        detail: 'আমলযোগ্য অপরাধের তথ্য ইলেকট্রনিক মাধ্যমে পাওয়া গেলে তিন দিনের মধ্যে সংবাদদাতার স্বাক্ষর সংগ্রহ করে কেস ডায়েরিতে অনুবর্তিতা উল্লেখ করুন।',
        sectionRef: 'এসওপি নির্দেশ ১(ক)-(খ), বিএনএসএস ১৭৩',
        mandatory: true,
      ),
      const SopRule(
        category: 'ঘটনাস্থল পরিদর্শন/প্রমাণ',
        title: 'ঘটনাস্থলের আলোকচিত্র/ভিডিওগ্রাফি',
        detail: 'প্রযোজ্য ক্ষেত্রে ঘটনাস্থলের আলোকচিত্র/ভিডিওগ্রাফি করে তা প্রমাণ/নথি হিসেবে সংযুক্ত করুন।',
        sectionRef: 'এসওপি নির্দেশ ২(ক), বিএনএসএস ১৭৬(৩)',
        mandatory: true,
      ),
      const SopRule(
        category: 'বিবৃতি',
        title: 'বিলম্ব না করে বিএনএসএস ১৮০ ধারার বিবৃতি',
        detail: 'উপলব্ধ সাক্ষী/ভিকটিমের বিবৃতি বিলম্ব না করে লিপিবদ্ধ করুন; প্রযোজ্য ক্ষেত্রে অডিও-ভিডিও ইলেকট্রনিক মাধ্যম ব্যবহার করা যেতে পারে।',
        sectionRef: 'এসওপি নির্দেশ ৩, বিএনএসএস ১৮০',
        mandatory: true,
      ),
      const SopRule(
        category: 'চূড়ান্ত পর্যায়',
        title: 'তদন্তের অগ্রগতি/ফলাফল ভিকটিম/সংবাদদাতাকে জানানো',
        detail: 'নির্ধারিত সময়ের মধ্যে তদন্তের অগ্রগতি/ফলাফল সংবাদদাতা বা ভিকটিমকে জানানো হয়েছে কি না অনুসরণ করে মাধ্যম ও তারিখ উল্লেখ করুন।',
        sectionRef: 'এসওপি নির্দেশ ৫(গ), বিএনএসএস ১৯৩(৩)',
        mandatory: true,
      ),
      const SopRule(
        category: 'চূড়ান্ত পর্যায়',
        title: 'চার্জশিটের নথি ইলেকট্রনিকভাবে সরবরাহ',
        detail: 'প্রযোজ্য ক্ষেত্রে চার্জশিট ও সংশ্লিষ্ট নথির অনুলিপি অভিযুক্ত ও ভিকটিমকে ইলেকট্রনিকভাবে সরবরাহ করা হয়েছে কি না অনুসরণ করুন।',
        sectionRef: 'এসওপি নির্দেশ ৫(ঘ), বিএনএসএস ১৯৩',
        mandatory: true,
      ),
      const SopRule(
        category: 'পরবর্তী তদন্ত',
        title: 'পরবর্তী তদন্তের জন্য আদালতের অনুমতি',
        detail: 'তদন্ত শেষ/প্রতিবেদন দাখিলের পরে পরবর্তী তদন্ত প্রয়োজন হলে আদালতের অনুমতি নথিবদ্ধ করে অনুমোদিত সময়ের মধ্যে সম্পন্ন করুন।',
        sectionRef: 'এসওপি নির্দেশ ৫(ঙ), বিএনএসএস ১৯৩',
        mandatory: true,
      ),
      const SopRule(
        category: 'পরবর্তী তদন্ত',
        title: 'তদন্ত শেষ না হলে ৯০ দিনের আগে সময় বৃদ্ধির প্রার্থনা',
        detail: '৯০ দিনের মধ্যে তদন্ত শেষ না হলে সময়সীমা শেষ হওয়ার আগেই পরবর্তী তদন্তের সময় বৃদ্ধির প্রার্থনা তৈরি করুন।',
        sectionRef: 'এসওপি নির্দেশ ৫(চ), বিএনএসএস ১৯৩',
        mandatory: true,
      ),
    ];

    if (sexual) {
      rules.addAll(const [
        SopRule(
          category: 'নারী/ভিকটিম-সংবেদনশীল অপরাধ',
          title: 'মহিলা পুলিশ অফিসার কর্তৃক এফআইআর/বিবৃতি',
          detail: 'বিএনএস ৬৪-৭১, ৭৪-৭৯ ও ১২৪ ধারার অপরাধে প্রয়োজন অনুযায়ী মহিলা পুলিশ অফিসার কর্তৃক এফআইআর/বিবৃতি লিপিবদ্ধ হয়েছে কি না নিশ্চিত করুন।',
          sectionRef: 'এসওপি নির্দেশ ১(গ)',
          mandatory: true,
        ),
        SopRule(
          category: 'নারী/ভিকটিম-সংবেদনশীল অপরাধ',
          title: 'প্রয়োজনে দোভাষী/বিশেষ শিক্ষকের সহায়তা',
          detail: 'মহিলা ভিকটিম/সংবাদদাতা সাময়িক বা স্থায়ীভাবে মানসিক/শারীরিক প্রতিবন্ধী হলে দোভাষী/বিশেষ শিক্ষকের ব্যবস্থা করে তাঁর বাসস্থান/সুবিধাজনক স্থানে বিবৃতি লিপিবদ্ধ করুন।',
          sectionRef: 'এসওপি নির্দেশ ১(ঘ), ৪(গ)-(ঘ)',
          mandatory: true,
        ),
        SopRule(
          category: 'নারী/ভিকটিম-সংবেদনশীল অপরাধ',
          title: 'সংবেদনশীল বিবৃতির ভিডিওগ্রাফি',
          detail: 'এসওপি অনুযায়ী প্রয়োজন হলে মোবাইল ফোনসহ অডিও-ভিডিও ইলেকট্রনিক মাধ্যমে বিবৃতি লিপিবদ্ধ করুন।',
          sectionRef: 'এসওপি নির্দেশ ১(ঙ), ৪(ঘ)',
          mandatory: true,
        ),
        SopRule(
          category: 'বিএনএসএস ১৮৩',
          title: 'বিলম্ব না করে ম্যাজিস্ট্রেটের নিকট বিএনএসএস ১৮৩ ধারার বিবৃতি',
          detail: 'প্রযোজ্য ক্ষেত্রে ভিকটিম/সাক্ষীর বিবৃতি লিপিবদ্ধের জন্য বিলম্ব না করে মাননীয় ম্যাজিস্ট্রেটের নিকট আবেদন করুন।',
          sectionRef: 'এসওপি নির্দেশ ১(চ), ৪(ক)-(খ)',
          mandatory: true,
        ),
        SopRule(
          category: 'বিএনএসএস ১৮৩',
          title: 'মহিলা ম্যাজিস্ট্রেটকে অগ্রাধিকার',
          detail: 'নির্দিষ্ট অপরাধে ভিকটিমের বিবৃতি মহিলা ম্যাজিস্ট্রেট কর্তৃক, অথবা তাঁর অনুপস্থিতিতে একজন মহিলার উপস্থিতিতে পুরুষ ম্যাজিস্ট্রেট কর্তৃক লিপিবদ্ধ হওয়া উচিত।',
          sectionRef: 'এসওপি নির্দেশ ১(চ), ৪(ক)',
          mandatory: true,
        ),
        SopRule(
          category: 'বিবৃতি',
          title: 'ভিকটিমের বাসস্থান/পছন্দের স্থানে বিবৃতি',
          detail: 'ধর্ষণ/যৌন অপরাধে প্রয়োজন অনুযায়ী ভিকটিমের বাসস্থান বা তাঁর পছন্দের স্থানে বিবৃতি লিপিবদ্ধ করুন।',
          sectionRef: 'এসওপি নির্দেশ ২(গ)',
          mandatory: true,
        ),
        SopRule(
          category: 'বিবৃতি',
          title: 'মহিলা অফিসার কর্তৃক বিএনএসএস ১৮০ ধারার বিবৃতি',
          detail: 'বিএনএস ৬৪-৭১, ৭৪-৭৯ ও ১২৪ ধারার অভিযোগে মহিলা পুলিশ অফিসার/যে কোনো মহিলা অফিসার কর্তৃক বিএনএসএস-এর ১৮০ ধারায় ভিকটিমের বিবৃতি লিপিবদ্ধ করুন।',
          sectionRef: 'এসওপি নির্দেশ ৩(খ)',
          mandatory: true,
        ),
      ]);
    }

    if (pocsoTimeBound || sexual) {
      rules.add(const SopRule(
        category: 'চূড়ান্ত পর্যায়',
        title: 'দুই মাসের মধ্যে তদন্ত সমাপ্তির যাচাই',
        detail: 'নির্দিষ্ট বিএনএস যৌন অপরাধ এবং পকসো ৪/৬/৮/১০ ধারার ক্ষেত্রে এফআইআর-এর তারিখ থেকে দুই মাসের মধ্যে চার্জশিট/ফাইনাল রিপোর্ট সম্পন্ন হয়েছে কি না অনুসরণ করুন।',
        sectionRef: 'এসওপি নির্দেশ ৫(ক)',
        mandatory: true,
      ));
    }

    if (serious) {
      rules.add(const SopRule(
        category: 'ঘটনাস্থল পরিদর্শন/প্রমাণ',
        title: 'গুরুতর অপরাধে ঘটনাস্থলে ফরেনসিক বিশেষজ্ঞ',
        detail: 'অপরাধের সাজা সাত বছরের বেশি হলে ফরেনসিক প্রমাণ সংগ্রহের জন্য ঘটনাস্থলে ফরেনসিক বিশেষজ্ঞকে ডাকুন এবং কেস ডায়েরিতে উল্লেখ করুন।',
        sectionRef: 'এসওপি নির্দেশ ২(খ), বিএনএসএস ১৭৬(৩)',
        mandatory: true,
      ));
    }

    if (electronic) {
      rules.add(const SopRule(
        category: 'ইলেকট্রনিক প্রমাণ',
        title: 'ইলেকট্রনিক ডিভাইসের হেফাজত-শৃঙ্খল',
        detail: 'ইলেকট্রনিক ডিভাইস/প্রমাণের ক্ষেত্রে হেফাজত-শৃঙ্খলের বিস্তারিত সংরক্ষণ ও দাখিল করে প্রমাণের রেকর্ডের সঙ্গে সংযুক্ত করুন।',
        sectionRef: 'এসওপি নির্দেশ ৫(খ)',
        mandatory: true,
      ));
    }

    return rules;
  }
}
