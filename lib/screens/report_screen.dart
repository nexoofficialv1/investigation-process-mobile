import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../screens/pdf_preview_screen.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../services/doc_export_service.dart';

class ReportScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile? caseFile;

  const ReportScreen({super.key, required this.profile, this.caseFile});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _store = LocalStoreService();
  final _pdf = PdfService();
  late _ReportTemplate _selected;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  late TextEditingController _recipientController;
  late TextEditingController _memoController;
  late TextEditingController _referenceController;
  late bool _caseLinked;

  bool get _hasCase => widget.caseFile != null;

  @override
  void initState() {
    super.initState();
    _caseLinked = _hasCase;
    _selected = _hasCase ? _caseTemplates.first : _generalTemplates.first;
    _recipientController = TextEditingController(text: _selected.recipient);
    _subjectController = TextEditingController(text: _selected.subject(widget.caseFile));
    _bodyController = TextEditingController(text: _selected.body(widget.profile, widget.caseFile));
    _memoController = TextEditingController(text: '');
    _referenceController = TextEditingController(text: _hasCase ? widget.caseFile!.displayTitle : '');
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _recipientController.dispose();
    _memoController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  List<_ReportTemplate> get _availableTemplates => _caseLinked && _hasCase ? _caseTemplates : _generalTemplates;

  void _applyTemplate(_ReportTemplate template) {
    setState(() {
      _selected = template;
      _recipientController.text = template.recipient;
      _subjectController.text = template.subject(_caseLinked ? widget.caseFile : null);
      _bodyController.text = template.body(widget.profile, _caseLinked ? widget.caseFile : null);
    });
  }

  void _toggleCaseLink(bool value) {
    setState(() {
      _caseLinked = value && _hasCase;
      _selected = _availableTemplates.first;
      _recipientController.text = _selected.recipient;
      _subjectController.text = _selected.subject(_caseLinked ? widget.caseFile : null);
      _bodyController.text = _selected.body(widget.profile, _caseLinked ? widget.caseFile : null);
      _referenceController.text = _caseLinked && _hasCase ? widget.caseFile!.displayTitle : '';
    });
  }

  String _fullReportBody() {
    final memo = _memoController.text.trim().isEmpty ? '' : 'রেফারেন্স: ${_referenceController.text.trim()}\n\n';
    final reference = _referenceController.text.trim().isEmpty ? '' : 'প্রতি
${_recipientController.text.trim()}

বিষয়: ${_subjectController.text.trim()}

$memo$reference${_bodyController.text.trim()}

সদয় অবগতি ও প্রয়োজনীয় ব্যবস্থা গ্রহণের জন্য প্রতিবেদনটি পেশ করা হলো।';
    return '''To
${_recipientController.text.trim()}

Subject: ${_subjectController.text.trim()}

$memo$reference${_bodyController.text.trim()}

Submitted for favour of kind information and necessary action.''';
  }

  FormNotice _buildReport({bool finalSave = false}) {
    final title = 'Report to ${_recipientController.text.trim()}';
    return FormNotice.create(
      caseId: _caseLinked && _hasCase ? widget.caseFile!.id : 'general_report',
      templateId: _caseLinked ? 'case_report_${_selected.id}' : 'general_report_${_selected.id}',
      title: title,
      body: _fullReportBody(),
    ).copyWith(isFinal: finalSave);
  }

  Future<void> _saveDraft() async {
    await _store.saveForm(_buildReport());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report draft saved.')));
  }

  Future<void> _preview() async {
    final report = _buildReport();
    final fileSlug = _subjectController.text.trim().isEmpty
        ? 'General_Report'
        : _subjectController.text.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'প্রতিবেদন প্রিভিউ',
          filename: '${fileSlug}_Report.pdf',
          docFilename: '${fileSlug}_Report.doc',
          buildPdf: () async {
            if (_caseLinked && _hasCase) {
              return _pdf.buildFormNoticePdf(officer: widget.profile, caseFile: widget.caseFile!, form: report);
            }
            return _pdf.buildGeneralReportPdf(officer: widget.profile, form: report);
          },
          buildDoc: () async {
            if (_caseLinked && _hasCase) {
              return DocExportService().buildFormNoticeDoc(officer: widget.profile, caseFile: widget.caseFile!, form: report);
            }
            return DocExportService().buildGeneralReportDoc(officer: widget.profile, form: report);
          },
          onFinalSave: () async => _store.saveForm(report.copyWith(isFinal: true)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = _availableTemplates;
    if (!templates.contains(_selected)) _selected = templates.first;

    return Scaffold(
      appBar: AppBar(title: const Text('প্রতিবেদন')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('খসড়া সংরক্ষণ'),
                  onPressed: _saveDraft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.preview),
                  label: const Text('প্রিভিউ'),
                  onPressed: _preview,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('দাপ্তরিক প্রতিবেদন প্রস্তুতকারী', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('কেস-সংযুক্ত অথবা সাধারণ প্রতিবেদন—এসপি, এসডিপিও, এসডিও, আদালত, ব্যাংক, হাসপাতাল ও অন্যান্য দপ্তরের জন্য—এখানে বাংলায় তৈরি ও সম্পাদনা করা যাবে। ইংরেজিতে লিখলে অনুবাদ চিহ্নে চাপুন অথবা ফিল্ড থেকে বের হলে তা বাংলায় রূপান্তর হবে।', style: TextStyle(fontWeight: FontWeight.w700)),
                  if (_hasCase) ...[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _caseLinked,
                      onChanged: _toggleCaseLink,
                      title: const Text('বর্তমান মামলার সঙ্গে প্রতিবেদন যুক্ত করুন'),
                      subtitle: Text(widget.caseFile!.displayTitle),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    const Text('ধরন: সাধারণ / কেস-বহির্ভূত প্রতিবেদন', style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_ReportTemplate>(
            value: _selected,
            decoration: const InputDecoration(labelText: 'প্রতিবেদনের ধরন'),
            items: templates.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
            onChanged: (value) {
              if (value != null) _applyTemplate(value);
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _recipientController,
            decoration: const InputDecoration(labelText: 'প্রাপক / দপ্তর'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(labelText: 'বিষয়'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _memoController,
            decoration: const InputDecoration(labelText: 'মেমো নং (যদি থাকে)'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _referenceController,
            decoration: const InputDecoration(labelText: 'মামলা / আবেদন / জিডিই / মেমো রেফারেন্স (যদি থাকে)'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _bodyController,
            decoration: const InputDecoration(labelText: 'প্রতিবেদনের মূল বক্তব্য'),
            minLines: 14,
            maxLines: 28,
            textAlignVertical: TextAlignVertical.top,
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _ReportTemplate {
  final String id;
  final String name;
  final String recipient;
  final String Function(CaseFile? file) subject;
  final String Function(OfficerProfile officer, CaseFile? file) body;

  const _ReportTemplate({required this.id, required this.name, required this.recipient, required this.subject, required this.body});
}

final List<_ReportTemplate> _caseTemplates = [
  _ReportTemplate(
    id: 'sp_progress',
    name: 'পুলিশ সুপারের নিকট মামলা অগ্রগতি প্রতিবেদন',
    recipient: 'পুলিশ সুপার, পূর্ব বর্ধমান',
    subject: (file) => 'Progress report in connection with ${file?.displayTitle ?? 'the matte'}-এর তদন্তের অগ্রগতি প্রতিবেদন',
    body: (officer, file) => '''সবিনয় নিবেদন এই যে, লিখিত অভিযোগ/এফআইআরের ভিত্তিতে ${file?.caseDate ?? ''} তারিখে ${file?.sections ?? ''} ধারায় উপরোক্ত মামলাটি রুজু হয়।

তদন্তকালে মামলার নথিপত্র পর্যালোচনা, প্রাসঙ্গিক স্থান পরিদর্শন/যাচাই এবং প্রযোজ্য ক্ষেত্রে সাক্ষীদের জিজ্ঞাসাবাদ করা হয়েছে। তদন্তের বর্তমান অগ্রগতি নিম্নরূপ:

১। সংক্ষিপ্ত ঘটনা: ${file?.firGist ?? ''}
২। ঘটনাস্থল: ${file?.placeOfOccurrence ?? ''}
৩। অভিযোগকারী: ${file?.complainantName ?? ''}
৪। ভুক্তভোগী: ${file?.victimName ?? ''}
৫। অভিযুক্ত/সন্দেহভাজন: ${file?.accusedName ?? ''}
৬। বর্তমান অগ্রগতি: 
৭। প্রস্তাবিত পরবর্তী পদক্ষেপ: 

সদয় অবগতির জন্য পেশ করা হলো।''',
  ),
  _ReportTemplate(
    id: 'sdpo_progress',
    name: 'এসডিপিও-র নিকট মামলা প্রতিবেদন',
    recipient: 'মহকুমা পুলিশ আধিকারিক, কালনা',
    subject: (file) => 'Report regarding ${file?.displayTitle ?? 'the matte'}-এর তদন্তের অগ্রগতি প্রতিবেদন',
    body: (officer, file) => '''সবিনয় নিবেদন এই যে, উপরোক্ত মামলার তদন্তকালে নিম্নলিখিত তথ্য ও অগ্রগতি পাওয়া গেছে।

মামলার রেফারেন্স: ${officer.policeStation} থানা মামলা নং ${file?.psCaseNo ?? ''}, তারিখ ${file?.caseDate ?? ''} তারিখে ${file?.sections ?? ''}।

সংক্ষিপ্ত ঘটনা: ${file?.firGist ?? ''}

তদন্তে গৃহীত পদক্ষেপ:
১। মামলার নথিপত্র পর্যালোচনা করা হয়েছে।
২। প্রাসঙ্গিক সাক্ষীদের জিজ্ঞাসাবাদ করা হয়েছে।
৩। প্রয়োজনীয় রিকুইজিশন/নথি সংগ্রহের ব্যবস্থা গ্রহণ করা হয়েছে।
৪। বর্তমান অবস্থা: 

পরবর্তী পদক্ষেপ: 

সদয় পর্যালোচনা ও প্রয়োজনীয় নির্দেশের জন্য পেশ করা হলো।''',
  ),
  _ReportTemplate(
    id: 'sdo_report',
    name: 'এসডিও-র নিকট মামলা / অনুসন্ধান প্রতিবেদন',
    recipient: 'মহকুমা শাসক, কালনা',
    subject: (file) => 'Enquiry report regarding ${file?.displayTitle ?? 'the matte'}-এর তদন্তের অগ্রগতি প্রতিবেদন',
    body: (officer, file) => '''সবিনয় নিবেদন এই যে, নির্দেশ/এন্ডোর্সমেন্ট অনুসারে উপরোক্ত বিষয়ে অনুসন্ধান/তদন্ত করা হয়েছে।

অনুসন্ধানকালে স্থানীয়ভাবে যাচাই করা হয় এবং উপলব্ধ ব্যক্তিদের সঙ্গে কথা বলা হয়। প্রাপ্ত তথ্য নিম্নরূপ:

১। মামলা/বিষয়ের রেফারেন্স: ${file?.displayTitle ?? ''}
২। ধারা/বিষয়: ${file?.sections ?? ''}
৩। স্থান: ${file?.placeOfOccurrence ?? ''}
৪। সংক্ষিপ্ত ঘটনা: ${file?.firGist ?? ''}
৫। অনুসন্ধানে প্রাপ্ত ফলাফল: 
৬। বর্তমান পরিস্থিতি: 
৭। গৃহীত/প্রস্তাবিত পুলিশি ব্যবস্থা: 

সদয় অবগতি ও প্রয়োজনীয় আদেশের জন্য পেশ করা হলো।''',
  ),
];

final List<_ReportTemplate> _generalTemplates = [
  _ReportTemplate(
    id: 'general_sp',
    name: 'পুলিশ সুপারের নিকট সাধারণ প্রতিবেদন',
    recipient: 'পুলিশ সুপার, পূর্ব বর্ধমান',
    subject: (_) => 'প্রতিবেদন পেশ প্রসঙ্গে',
    body: (officer, _) => '''সবিনয় নিবেদন এই যে, সদয় অবগতির জন্য নিম্নলিখিত প্রতিবেদন পেশ করা হলো।

১। রেফারেন্স / তথ্যের উৎস: 
২। তারিখ ও সময়: 
৩। সংশ্লিষ্ট স্থান / দপ্তর / এলাকা: 
৪। সংক্ষিপ্ত ঘটনা: 
৫। অনুসন্ধান / গৃহীত ব্যবস্থা: 
৬। বর্তমান অবস্থা: 
৭। প্রস্তাবিত পরবর্তী ব্যবস্থা / প্রার্থনা: 

সদয় অবগতি ও প্রয়োজনীয় নির্দেশের জন্য পেশ করা হলো।''',
  ),
  _ReportTemplate(
    id: 'general_sdpo',
    name: 'এসডিপিও-র নিকট সাধারণ প্রতিবেদন',
    recipient: 'মহকুমা পুলিশ আধিকারিক, কালনা',
    subject: (_) => 'সদয় পর্যালোচনার জন্য প্রতিবেদন',
    body: (officer, _) => '''সবিনয় নিবেদন এই যে, সদয় পর্যালোচনা ও প্রয়োজনীয় নির্দেশের জন্য নিম্নলিখিত বিষয়সমূহ পেশ করা হলো।

১। রেফারেন্স: 
২। বিষয়বস্তু: 
৩। অনুসন্ধান/স্থানীয় যাচাইয়ে প্রাপ্ত তথ্য: 
৪। এ পর্যন্ত গৃহীত ব্যবস্থা: 
৫। বর্তমান পরিস্থিতি: 
৬। প্রস্তাবিত পরবর্তী ব্যবস্থা: 

সদয় পর্যালোচনা ও প্রয়োজনীয় নির্দেশের জন্য পেশ করা হলো।''',
  ),
  _ReportTemplate(
    id: 'general_sdo',
    name: 'এসডিও / এক্সিকিউটিভ ম্যাজিস্ট্রেটের নিকট সাধারণ প্রতিবেদন',
    recipient: 'মহকুমা শাসক, কালনা',
    subject: (_) => 'অনুসন্ধান প্রতিবেদন',
    body: (officer, _) => '''সবিনয় নিবেদন এই যে, এন্ডোর্সমেন্ট/নির্দেশ অনুসারে বিষয়টি সম্পর্কে স্থানীয়ভাবে অনুসন্ধান করা হয়েছে।

অনুসন্ধানে নিম্নলিখিত তথ্য পাওয়া গেছে:

১। আবেদনকারী/তথ্যদাতার নাম ও ঠিকানা (যদি থাকে): 
২। অনুসন্ধানের স্থান: 
৩। যাঁদের সঙ্গে যোগাযোগ করা হয়েছে: 
৪। অনুসন্ধানে প্রকাশিত তথ্য: 
৫। গৃহীত/প্রস্তাবিত পুলিশি ব্যবস্থা: 
৬। মতামত / অনুসন্ধানের ফলাফল: 

সদয় অবগতি ও প্রয়োজনীয় আদেশের জন্য পেশ করা হলো।''',
  ),
  _ReportTemplate(
    id: 'court_report',
    name: 'বিজ্ঞ আদালতের নিকট সাধারণ প্রতিবেদন',
    recipient: 'বিজ্ঞ সংশ্লিষ্ট আদালত',
    subject: (_) => 'প্রতিবেদন পেশ প্রসঙ্গে',
    body: (officer, _) => '''সবিনয় নিবেদন এই যে, বিজ্ঞ আদালতের সদয় পর্যালোচনার জন্য নিম্নলিখিত প্রতিবেদন পেশ করা হলো।

১। রেফারেন্স: 
২। বিষয়ের পটভূমি: 
৩। পুলিশ কর্তৃক গৃহীত পদক্ষেপ: 
৪। বর্তমান অবস্থা: 
৫। প্রার্থনা / নিবেদন: 

সদয় পর্যালোচনা ও প্রয়োজনীয় আদেশের জন্য পেশ করা হলো।''',
  ),
  _ReportTemplate(
    id: 'bank_report',
    name: 'ব্যাংকের নিকট প্রতিবেদন / পত্র',
    recipient: 'শাখা ব্যবস্থাপক, সংশ্লিষ্ট ব্যাংক',
    subject: (_) => 'প্রয়োজনীয় তথ্য / ব্যবস্থা গ্রহণের অনুরোধ',
    body: (officer, _) => '''মহাশয়/মহাশয়া,

উপরোক্ত বিষয়ের প্রেক্ষিতে অনুসন্ধান/তদন্তের স্বার্থে অনুগ্রহ করে প্রয়োজনীয় ব্যবস্থা গ্রহণ এবং নিম্নলিখিত তথ্য সরবরাহ করার জন্য অনুরোধ করা হচ্ছে।

১। অ্যাকাউন্ট / লেনদেনের বিবরণ: 
২। প্রয়োজনীয় তথ্য / ব্যবস্থা: 
৩। রেফারেন্স নং / স্বীকৃতি নং (যদি থাকে): 
৪। প্রয়োজনীয় সময়সীমা: 

বিষয়টি জরুরি হিসেবে বিবেচনা করে যত দ্রুত সম্ভব উপলব্ধ তথ্য সরবরাহ করার অনুরোধ রইল।

সদয় অবগতি ও প্রয়োজনীয় ব্যবস্থা গ্রহণের জন্য প্রেরিত।''',
  ),
  _ReportTemplate(
    id: 'hospital_report',
    name: 'হাসপাতালের নিকট প্রতিবেদন / রিকুইজিশন',
    recipient: 'মেডিক্যাল অফিসার / সুপারিনটেনডেন্ট, সংশ্লিষ্ট হাসপাতাল',
    subject: (_) => 'চিকিৎসা সংক্রান্ত নথি / প্রতিবেদন প্রদানের অনুরোধ',
    body: (officer, _) => '''মহাশয়/মহাশয়া,

উপরোক্ত বিষয়ের প্রেক্ষিতে নিম্নোক্ত প্রয়োজনীয় চিকিৎসা সংক্রান্ত নথি/প্রতিবেদন সরবরাহ করার জন্য অনুরোধ করা হচ্ছে।

১। রোগী/সংশ্লিষ্ট ব্যক্তির নাম: 
২। চিকিৎসা/ভর্তির তারিখ: 
৩। প্রয়োজনীয় নথি/প্রতিবেদন: 
৪। উদ্দেশ্য: 

সদয় অবগতি ও প্রয়োজনীয় ব্যবস্থা গ্রহণের জন্য প্রেরিত।''',
  ),
  _ReportTemplate(
    id: 'blank_report',
    name: 'ফাঁকা কাস্টম প্রতিবেদন',
    recipient: 'সংশ্লিষ্ট আধিকারিক',
    subject: (_) => 'প্রতিবেদন',
    body: (officer, _) => '''সবিনয় নিবেদন এই যে,



সদয় অবগতি ও প্রয়োজনীয় ব্যবস্থা গ্রহণের জন্য পেশ করা হলো।''',
  ),
];
