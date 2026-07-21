import 'package:flutter/material.dart';

import '../models/case_file.dart';

class InvestigationChecklistScreen extends StatefulWidget {
  final CaseFile caseFile;

  const InvestigationChecklistScreen({super.key, required this.caseFile});

  @override
  State<InvestigationChecklistScreen> createState() => _InvestigationChecklistScreenState();
}

class _InvestigationChecklistScreenState extends State<InvestigationChecklistScreen> {
  final Set<String> _checked = <String>{};

  @override
  Widget build(BuildContext context) {
    final sections = _buildChecklist(widget.caseFile);
    final total = sections.fold<int>(0, (sum, sec) => sum + sec.items.length);
    return Scaffold(
      appBar: AppBar(title: const Text('তদন্ত যাচাইতালিকা')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('ধারা: ${widget.caseFile.sections}'),
                  const SizedBox(height: 8),
                  Text('যাচাই সম্পন্ন: ${_checked.length} / $total', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'প্রতিটি বিষয় ট্যাপ করলে টিক/আনটিক হবে। সিডি/আইএফ-৫ চূড়ান্ত করার আগে সবগুলি যাচাই করুন।',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...sections.map((section) => _ChecklistBlock(
                section: section,
                checked: _checked,
                onToggle: (item, value) {
                  setState(() {
                    if (value) {
                      _checked.add(item);
                    } else {
                      _checked.remove(item);
                    }
                  });
                },
              )),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  List<_ChecklistSection> _buildChecklist(CaseFile file) {
    final lower = file.sections.toLowerCase();
    final pocso = lower.contains('pocso');
    final hurt = lower.contains('115') || lower.contains('117') || lower.contains('118') || lower.contains('109');
    final property = lower.contains('303') || lower.contains('305') || lower.contains('309') || lower.contains('317') || lower.contains('318');

    final common = <_ChecklistSection>[
      _ChecklistSection('মামলার সূচনা ও প্রাথমিক নথি', [
        'লিখিত অভিযোগ/এফআইআরের অনুলিপি যাচাই করা হয়েছে',
        'ফর্মাল এফআইআর/থানা মামলার তথ্য যাচাই করা হয়েছে',
        'তদন্তভার গ্রহণের এন্ডোর্সমেন্ট ও তারিখ উল্লেখ করা হয়েছে',
        'ঘটনাস্থল, ঘটনার তারিখ, রিপোর্টের তারিখ, তদন্তভার গ্রহণের তারিখ/সময় ও তদন্তকারী অফিসারের তথ্য লেখা হয়েছে',
        'অভিযোগকারী/ভুক্তভোগী/অভিযুক্তের প্রাথমিক তথ্য লেখা হয়েছে',
      ]),
      _ChecklistSection('ঘটনাস্থল পরিদর্শন ও স্থানীয় অনুসন্ধান', [
        'ঘটনাস্থল পরিদর্শন করে সুনির্দিষ্ট অবস্থান উল্লেখ করা হয়েছে',
        'প্রয়োজনে সূচিসহ ঘটনাস্থলের খসড়া নকশা প্রস্তুত করা হয়েছে',
        'গুরুত্বপূর্ণ চিহ্ন, সীমানা ও পার্শ্ববর্তী এলাকার বিবরণ লেখা হয়েছে',
        'স্থানীয় সাক্ষীদের শনাক্ত করে জিজ্ঞাসাবাদ করা হয়েছে',
        'প্রাসঙ্গিক হলে সিসিটিভি/নিকটবর্তী দোকান/সার্বজনীন উৎস যাচাই করা হয়েছে',
      ]),
      _ChecklistSection('বিবৃতি', [
        'বিএনএসএস-এর ১৮০ ধারায় অভিযোগকারীর বিবৃতি লিপিবদ্ধ করা হয়েছে',
        'বিএনএসএস-এর ১৮০ ধারায় ভুক্তভোগীর বিবৃতি লিপিবদ্ধ করা হয়েছে',
        'বিএনএসএস-এর ১৮০ ধারায় উপলব্ধ সাক্ষীদের বিবৃতি লিপিবদ্ধ করা হয়েছে',
        'জব্দ করা হলে জব্দসাক্ষীদের বিবৃতি লিপিবদ্ধ করা হয়েছে',
        'বিরোধপূর্ণ/প্রতিকূল/ঘটনা সম্পর্কে অজ্ঞ সাক্ষী থাকলে পৃথকভাবে উল্লেখ করা হয়েছে',
      ]),
      _ChecklistSection('অভিযুক্ত/সন্দেহভাজন সংক্রান্ত ব্যবস্থা', [
        'অভিযুক্তের পরিচয় ও ঠিকানা যাচাই করা হয়েছে',
        'প্রযোজ্য ক্ষেত্রে বিএনএসএস-এর ৩৫ ধারার নোটিশ/গ্রেপ্তারের ব্যবস্থা হালনাগাদ করা হয়েছে',
        'গ্রেপ্তার করা হলে গ্রেপ্তারের কারণ, পরিবারকে সংবাদ ও মেডিক্যাল পরীক্ষা সম্পন্ন হয়েছে',
        'ফরওয়ার্ডিং/পুলিশ বা বিচারবিভাগীয় হেফাজতের প্রার্থনা/জামিনের অবস্থা হালনাগাদ হয়েছে',
        'প্রয়োজনে পূর্বের মামলা/দণ্ডাদেশ/স্থানীয় সুনাম যাচাই করা হয়েছে',
      ]),
      _ChecklistSection('আলামত, জব্দ ও ডিজিটাল প্রমাণ', [
        'প্রযোজ্য ক্ষেত্রে জব্দতালিকা প্রস্তুত করা হয়েছে',
        'মালখানা/সম্পত্তি রেজিস্টারের তথ্য উল্লেখ করা হয়েছে',
        'প্রয়োজনে এফএসএল/বিশেষজ্ঞ মতামতের রিকুইজিশন পাঠানো হয়েছে',
        'প্রয়োজনে সিডিআর/সিএএফ/ব্যাংক/ইউপিআই/সিসিটিভি রিকুইজিশন পাঠানো হয়েছে',
        'প্রয়োজনে বিএসএ-এর ৬৩(৪) ধারার ইলেকট্রনিক প্রমাণের সার্টিফিকেট বিবেচনা করা হয়েছে',
      ]),
      _ChecklistSection('এসওপির বাধ্যতামূলক যাচাই', [
        'ইলেকট্রনিকভাবে তথ্য পাওয়া হলে ৩ দিনের মধ্যে তথ্যদাতার স্বাক্ষর নেওয়া হয়েছে',
        'প্রযোজ্য ক্ষেত্রে বিএনএসএস-এর ১৭৬(৩) ধারায় ঘটনাস্থলের ছবি/ভিডিও ধারণ করা হয়েছে',
        '৭ বছরের বেশি দণ্ডযোগ্য গুরুতর অপরাধে ফরেনসিক বিশেষজ্ঞ ডাকার প্রয়োজন যাচাই করা হয়েছে',
        '৯০ দিনের মধ্যে ভুক্তভোগী/তথ্যদাতাকে তদন্তের অগ্রগতি/ফলাফল জানানোর বিষয় অনুসরণ করা হয়েছে',
        '৯০ দিনের মধ্যে তদন্ত শেষ না হলে মেয়াদ শেষের আগে সময় বৃদ্ধির প্রার্থনা প্রস্তুত করা হয়েছে',
        'ইলেকট্রনিক ডিভাইস/প্রমাণ থাকলে ধারাবাহিক হেফাজত ও সংগ্রহের ক্রম বজায় রাখা হয়েছে',
      ]),
      _ChecklistSection('চূড়ান্ত পর্যায় ও আইএফ-৫ প্রস্তুতি', [
        'চূড়ান্ত তদন্ত সিডি পর্যন্ত সব সিডি পর্যালোচনা করা হয়েছে',
        'চূড়ান্ত সিডিতে সম্পূর্ণ তদন্তের সারাংশ রয়েছে',
        'আইএফ-৫-এর জন্য সাক্ষী তালিকা প্রস্তুত হয়েছে',
        'চার্জশিটভুক্ত/চার্জশিট-বহির্ভূত অভিযুক্তের তালিকা প্রস্তুত হয়েছে',
        'সংযুক্ত নথির তালিকা প্রস্তুত হয়েছে',
        'প্রযোজ্য ক্ষেত্রে অভিযোগকারী/ভুক্তভোগীকে তদন্তের ফলাফল/অগ্রগতি জানানো হয়েছে',
        'চূড়ান্ত প্রতিবেদন দাখিলের আগে এসওপি অনুবর্তিতা স্ক্রিন যাচাই করা হয়েছে',
      ]),
    ];

    if (pocso) {
      common.insert(3, _ChecklistSection('পকসো / নাবালক / ভুক্তভোগী সংক্রান্ত', [
        'ভুক্তভোগীর বয়সের প্রমাণ/স্কুলের নথি/জন্ম সনদ সংগ্রহ করা হয়েছে',
        'চিকিৎসা পরীক্ষা/সম্মতি/অস্বীকৃতির বিবরণ লেখা হয়েছে',
        'বিএনএসএস-এর ১৮৩ ধারার বিচারবিভাগীয় বিবৃতির প্রার্থনা ও ফলাফল হালনাগাদ হয়েছে',
        'অভিভাবক/পরিবারের সদস্যের বিবৃতি লিপিবদ্ধ করা হয়েছে',
        'প্রযোজ্য ক্ষেত্রে বিশেষ আদালত/জেজেবি-এর অনুবর্তিতা যাচাই করা হয়েছে',
      ]));
    }
    if (hurt) {
      common.insert(3, _ChecklistSection('চিকিৎসা / আঘাত সংক্রান্ত', [
        'আঘাতের প্রতিবেদন/বিএইচটি/ছাড়পত্রের রিকুইজিশন পাঠানো হয়েছে',
        'চিকিৎসক/মেডিক্যাল অফিসারের বিবরণ লেখা হয়েছে',
        'অস্ত্র/আঘাতের কারণ ও পদ্ধতি যাচাই করা হয়েছে',
        'চূড়ান্ত নথিতে চিকিৎসা সংক্রান্ত কাগজপত্র সংযুক্ত করা হয়েছে',
      ]));
    }
    if (property) {
      common.insert(4, _ChecklistSection('সম্পত্তি / প্রতারণা / উদ্ধার সংক্রান্ত', [
        'চুরি/প্রতারণার সম্পত্তির বিবরণ যাচাই করা হয়েছে',
        'সাক্ষীসহ উদ্ধার/জব্দের বিবরণ লেখা হয়েছে',
        'আর্থিক প্রতারণা হলে ব্যাংক/ইউপিআই/হিসাবের লেনদেন-পথের রিকুইজিশন পাঠানো হয়েছে',
        'প্রয়োজনে মালিকানার নথি/চালান/মূল্যায়ন প্রতিবেদন সংগ্রহ করা হয়েছে',
      ]));
    }
    return common;
  }
}

class _ChecklistBlock extends StatelessWidget {
  final _ChecklistSection section;
  final Set<String> checked;
  final void Function(String item, bool value) onToggle;

  const _ChecklistBlock({required this.section, required this.checked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        children: section.items.map((item) {
          final key = '${section.title}::$item';
          return CheckboxListTile(
            value: checked.contains(key),
            onChanged: (value) => onToggle(key, value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(item),
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

class _ChecklistSection {
  final String title;
  final List<String> items;
  _ChecklistSection(this.title, this.items);
}
