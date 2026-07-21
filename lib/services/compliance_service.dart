import '../models/case_file.dart';
import 'sop_compliance_service.dart';

class ComplianceTask {
  final String title;
  final String detail;
  final String priority;
  final bool mandatory;

  const ComplianceTask({
    required this.title,
    required this.detail,
    required this.priority,
    required this.mandatory,
  });
}

class ComplianceService {
  List<ComplianceTask> buildTasks(CaseFile caseFile) {
    final sections = caseFile.sections.toLowerCase();
    final tasks = <ComplianceTask>[
      const ComplianceTask(
        title: 'কেস ডায়েরির ধারাবাহিকতা',
        detail: 'প্রতিটি কেস ডায়েরি নির্ধারিত সূচনা বাক্য দিয়ে শুরু এবং নির্ধারিত সমাপ্তি বাক্য দিয়ে শেষ করতে হবে।',
        priority: 'উচ্চ',
        mandatory: true,
      ),
      const ComplianceTask(
        title: 'বিএনএসএস-এর ১৮০ ধারায় সাক্ষীর বিবৃতি',
        detail: 'উপলব্ধ অভিযোগকারী, ভিকটিম, স্থানীয়, প্রত্যক্ষদর্শী ও জব্দ সাক্ষীদের বিবৃতি লিপিবদ্ধ করুন।',
        priority: 'উচ্চ',
        mandatory: true,
      ),
      const ComplianceTask(
        title: 'সূচিসহ খসড়া নকশা',
        detail: 'ঘটনাস্থল পরিদর্শন প্রাসঙ্গিক হলে খসড়া নকশা প্রস্তুত বা হালনাগাদ করুন।',
        priority: 'মধ্যম',
        mandatory: false,
      ),
      const ComplianceTask(
        title: 'চিকিৎসা/বিএইচটি/আঘাতের নথি',
        detail: 'মারধর, আঘাত, বিষক্রিয়া, মৃত্যু বা যৌন অপরাধের ক্ষেত্রে চিকিৎসা সংক্রান্ত নথি সংগ্রহ করুন।',
        priority: 'মধ্যম',
        mandatory: false,
      ),
    ];

    if (sections.contains('pocso') || sections.contains('74') || sections.contains('75') || sections.contains('69')) {
      tasks.addAll(const [
        ComplianceTask(
          title: 'বিএনএসএস-এর ১৮৩ ধারায় ভিকটিমের বিবৃতি',
          detail: 'বিএনএসএস-এর ১৮৩ ধারার প্রার্থনা তৈরি করুন এবং আদালতে বিবৃতি লিপিবদ্ধ হওয়ার অগ্রগতি অনুসরণ করুন।',
          priority: 'উচ্চ',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'বয়সের প্রমাণ/জন্ম শংসাপত্র',
          detail: 'ভিকটিম/অপ্রাপ্তবয়স্কের বিষয় থাকলে বিদ্যালয়ের শংসাপত্র, জন্ম শংসাপত্র বা অন্য বয়সের প্রমাণ সংগ্রহ করুন।',
          priority: 'উচ্চ',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'ভিকটিমের চিকিৎসা পরীক্ষা',
          detail: 'চিকিৎসা রিকুইজিশন তৈরি করে প্রতিবেদন/বিএইচটি সংগ্রহ করুন।',
          priority: 'উচ্চ',
          mandatory: true,
        ),
      ]);
    }

    if (sections.contains('109') || sections.contains('115') || sections.contains('117') || sections.contains('118')) {
      tasks.addAll(const [
        ComplianceTask(
          title: 'আঘাতের প্রতিবেদন যাচাই',
          detail: 'আঘাতের প্রতিবেদন/বিএইচটি সংগ্রহ করে কেস ডায়েরিতে আঘাতের বিবরণ উল্লেখ করুন।',
          priority: 'উচ্চ',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'অস্ত্র/আলামত জব্দ যাচাই',
          detail: 'অস্ত্র/আলামত ব্যবহৃত হলে জব্দতালিকা প্রস্তুত করুন এবং এফএসএল পরীক্ষার প্রয়োজন বিবেচনা করুন।',
          priority: 'মধ্যম',
          mandatory: false,
        ),
      ]);
    }

    if (sections.contains('318') || sections.contains('319') || sections.contains('316') || sections.contains('cyber') || sections.contains('bank')) {
      tasks.addAll(const [
        ComplianceTask(
          title: 'ব্যাংক/ইউপিআই লেনদেনের গতিপথ',
          detail: 'কেওয়াইসি, হিসাব বিবরণী, সুবিধাভোগী, ইউটিআর এবং লিয়েন/ফ্রিজের তথ্যের জন্য ব্যাংক রিকুইজিশন তৈরি করুন।',
          priority: 'উচ্চ',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'ডিজিটাল প্রমাণের সার্টিফিকেট',
          detail: 'প্রযোজ্য ক্ষেত্রে বিএসএ অনুযায়ী ইলেকট্রনিক রেকর্ড ও সার্টিফিকেটের প্রয়োজনীয়তা অনুসরণ করুন।',
          priority: 'উচ্চ',
          mandatory: true,
        ),
      ]);
    }

    if (sections.contains('303') || sections.contains('305') || sections.contains('306') || sections.contains('309') || sections.contains('317')) {
      tasks.addAll(const [
        ComplianceTask(
          title: 'চুরি/উদ্ধার হওয়া সম্পত্তির তালিকা',
          detail: 'সম্পত্তির তালিকা, জব্দতালিকা এবং উদ্ধার মেমোর বিবরণ সংরক্ষণ করুন।',
          priority: 'উচ্চ',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'মালখানা এন্ট্রি',
          detail: 'জব্দ/উদ্ধার করা সম্পত্তির সঙ্গে মালখানার রেফারেন্স সংযুক্ত আছে কি না নিশ্চিত করুন।',
          priority: 'মধ্যম',
          mandatory: false,
        ),
      ]);
    }

    final sopRules = SopComplianceService().buildRules(caseFile);
    for (final rule in sopRules.where((r) => r.mandatory)) {
      tasks.add(ComplianceTask(
        title: 'এসওপি: ${rule.title}',
        detail: '${rule.sectionRef} • ${rule.detail}',
        priority: 'উচ্চ',
        mandatory: true,
      ));
    }

    tasks.add(const ComplianceTask(
      title: 'চার্জশিট/ফাইনাল রিপোর্ট দাখিল-পূর্ব যাচাই',
      detail: 'চূড়ান্ত প্রতিবেদন দাখিলের আগে ফর্ম মডিউল থেকে অভিযোগপত্র/চূড়ান্ত প্রতিবেদন যাচাইতালিকা তৈরি করে এসওপি অনুবর্তিতা নিশ্চিত করুন।',
      priority: 'মধ্যম',
      mandatory: true,
    ));

    return tasks;
  }
}
