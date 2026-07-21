import 'package:flutter/material.dart';

import '../core/document_language.dart';
import '../models/case_file.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../screens/pdf_preview_screen.dart';
import '../services/doc_export_service.dart';
import '../services/document_translation_service.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../widgets/form_helpers.dart';

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
  DocumentLanguage _language = DocumentLanguage.bangla;

  bool get _hasCase => widget.caseFile != null;

  @override
  void initState() {
    super.initState();
    _caseLinked = _hasCase;
    _selected = _hasCase ? _caseTemplates.first : _generalTemplates.first;
    _recipientController = TextEditingController();
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();
    _memoController = TextEditingController();
    _referenceController = TextEditingController(
      text: _hasCase ? widget.caseFile!.displayTitle : '',
    );
    _applyTemplateValues(_selected);
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

  List<_ReportTemplate> get _availableTemplates =>
      _caseLinked && _hasCase ? _caseTemplates : _generalTemplates;

  void _applyTemplateValues(_ReportTemplate template) {
    final file = _caseLinked ? widget.caseFile : null;
    _recipientController.text = template.recipientFor(_language);
    _subjectController.text = template.subjectFor(_language, file);
    _bodyController.text = template.bodyFor(_language, widget.profile, file);
  }

  void _applyTemplate(_ReportTemplate template) {
    setState(() {
      _selected = template;
      _applyTemplateValues(template);
    });
  }

  void _toggleCaseLink(bool value) {
    setState(() {
      _caseLinked = value && _hasCase;
      _selected = _availableTemplates.first;
      _referenceController.text =
          _caseLinked && _hasCase ? widget.caseFile!.displayTitle : '';
      _applyTemplateValues(_selected);
    });
  }

  Future<void> _changeLanguage(DocumentLanguage language) async {
    if (language == _language) return;
    final replace = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          language.isBangla
              ? 'প্রতিবেদনের ভাষা বাংলা করবেন?'
              : 'Change report language to English?',
        ),
        content: Text(
          language.isBangla
              ? 'নির্বাচিত প্রতিবেদন টেমপ্লেটটি সম্পূর্ণ বাংলায় নতুন করে বসবে। আপনার বর্তমান সম্পাদিত লেখা থাকলে আগে খসড়া সংরক্ষণ করুন।'
              : 'The selected report template will be regenerated completely in English. Save the present draft first if it contains important edits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(language.isBangla ? 'বাতিল' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(language.isBangla ? 'বাংলা করুন' : 'Use English'),
          ),
        ],
      ),
    );
    if (replace != true || !mounted) return;
    setState(() {
      _language = language;
      _applyTemplateValues(_selected);
    });
  }

  Future<void> _translateCurrentText() async {
    final changed = await DocumentTranslationService.instance
        .translateControllers(
      [_recipientController, _subjectController, _bodyController],
      target: _language,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          changed > 0
              ? (_language.isBangla
                  ? 'বর্তমান লেখাগুলি বাংলায় রূপান্তরিত হয়েছে।'
                  : 'The current text has been translated into English.')
              : (_language.isBangla
                  ? 'অনুবাদের প্রয়োজন পাওয়া যায়নি অথবা অনলাইন অনুবাদ পাওয়া যায়নি।'
                  : 'No translation was required, or the online translation service was unavailable.'),
        ),
      ),
    );
  }

  String _fullReportBody() {
    final memo = _memoController.text.trim().isEmpty
        ? ''
        : (_language.isBangla
            ? 'মেমো নং: ${_memoController.text.trim()}\n\n'
            : 'Memo No.: ${_memoController.text.trim()}\n\n');
    final reference = _referenceController.text.trim().isEmpty
        ? ''
        : (_language.isBangla
            ? 'সূত্র: ${_referenceController.text.trim()}\n\n'
            : 'Reference: ${_referenceController.text.trim()}\n\n');

    if (_language.isEnglish) {
      return '''To
${_recipientController.text.trim()}

Subject: ${_subjectController.text.trim()}

$memo$reference${_bodyController.text.trim()}

Submitted for favour of kind information and necessary action.''';
    }

    return '''প্রতি
${_recipientController.text.trim()}

বিষয়: ${_subjectController.text.trim()}

$memo$reference${_bodyController.text.trim()}

সদয় অবগতি ও প্রয়োজনীয় ব্যবস্থা গ্রহণের জন্য প্রতিবেদনটি পেশ করা হলো।''';
  }

  FormNotice _buildReport({bool finalSave = false}) {
    final title = _language.isBangla
        ? '${_recipientController.text.trim()}-এর নিকট প্রতিবেদন'
        : 'Report to ${_recipientController.text.trim()}';
    return FormNotice.create(
      caseId: _caseLinked && _hasCase
          ? widget.caseFile!.id
          : 'general_report',
      templateId: _caseLinked
          ? 'case_report_${_selected.id}'
          : 'general_report_${_selected.id}',
      title: title,
      body: _fullReportBody(),
      languageCode: _language.code,
    ).copyWith(isFinal: finalSave);
  }

  Future<void> _saveDraft() async {
    await _store.saveForm(_buildReport());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _language.isBangla
              ? 'প্রতিবেদনের খসড়া সংরক্ষিত হয়েছে।'
              : 'The report draft has been saved.',
        ),
      ),
    );
  }

  Future<void> _preview() async {
    final report = _buildReport();
    final fileSlug = _selected.id.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: _language.isBangla ? 'প্রতিবেদন প্রিভিউ' : 'Report Preview',
          filename: '${fileSlug}_${_language.code}_report.pdf',
          docFilename: '${fileSlug}_${_language.code}_report.doc',
          buildPdf: () async {
            if (_caseLinked && _hasCase) {
              return _pdf.buildFormNoticePdf(
                officer: widget.profile,
                caseFile: widget.caseFile!,
                form: report,
              );
            }
            return _pdf.buildGeneralReportPdf(
              officer: widget.profile,
              form: report,
            );
          },
          buildDoc: () async {
            if (_caseLinked && _hasCase) {
              return DocExportService().buildFormNoticeDoc(
                officer: widget.profile,
                caseFile: widget.caseFile!,
                form: report,
              );
            }
            return DocExportService().buildGeneralReportDoc(
              officer: widget.profile,
              form: report,
            );
          },
          onFinalSave: () async =>
              _store.saveForm(report.copyWith(isFinal: true)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = _availableTemplates;
    if (!templates.contains(_selected)) _selected = templates.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(_language.isBangla ? 'প্রতিবেদন' : 'Reports'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(
                    _language.isBangla ? 'খসড়া সংরক্ষণ' : 'Save Draft',
                  ),
                  onPressed: _saveDraft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.preview),
                  label: Text(_language.isBangla ? 'প্রিভিউ' : 'Preview'),
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
                  Text(
                    _language.isBangla
                        ? 'দাপ্তরিক প্রতিবেদন প্রস্তুতকারী'
                        : 'Official Report Builder',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DocumentLanguage>(
                    value: _language,
                    decoration: InputDecoration(
                      labelText: _language.isBangla
                          ? 'নথির ভাষা'
                          : 'Document language',
                      border: const OutlineInputBorder(),
                    ),
                    items: DocumentLanguage.values
                        .map(
                          (language) => DropdownMenuItem(
                            value: language,
                            child: Text(
                              language.isBangla ? 'বাংলা' : 'English',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (language) {
                      if (language != null) _changeLanguage(language);
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _translateCurrentText,
                    icon: const Icon(Icons.translate),
                    label: Text(
                      _language.isBangla
                          ? 'বর্তমান ইংরেজি লেখা বাংলায় করুন'
                          : 'Translate current Bangla text to English',
                    ),
                  ),
                  if (_hasCase) ...[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _caseLinked,
                      onChanged: _toggleCaseLink,
                      title: Text(
                        _language.isBangla
                            ? 'বর্তমান মামলার সঙ্গে প্রতিবেদন যুক্ত করুন'
                            : 'Link report with the current case',
                      ),
                      subtitle: Text(widget.caseFile!.displayTitle),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_ReportTemplate>(
            value: _selected,
            decoration: InputDecoration(
              labelText: _language.isBangla
                  ? 'প্রতিবেদনের ধরন'
                  : 'Report type',
            ),
            items: templates
                .map(
                  (template) => DropdownMenuItem(
                    value: template,
                    child: Text(template.nameFor(_language)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) _applyTemplate(value);
            },
          ),
          const SizedBox(height: 10),
          BanglaTextField(
            controller: _recipientController,
            label: _language.isBangla ? 'প্রাপক / দপ্তর' : 'Recipient / Office',
            maxLines: 2,
            autoTranslate: _language.isBangla,
          ),
          const SizedBox(height: 10),
          BanglaTextField(
            controller: _subjectController,
            label: _language.isBangla ? 'বিষয়' : 'Subject',
            maxLines: 2,
            autoTranslate: _language.isBangla,
          ),
          const SizedBox(height: 10),
          BanglaTextField(
            controller: _memoController,
            label: _language.isBangla
                ? 'মেমো নং (যদি থাকে)'
                : 'Memo No. (if any)',
            autoTranslate: false,
          ),
          const SizedBox(height: 10),
          BanglaTextField(
            controller: _referenceController,
            label: _language.isBangla
                ? 'মামলা / আবেদন / জিডিই / মেমো সূত্র'
                : 'Case / petition / GDE / memo reference',
            maxLines: 2,
            autoTranslate: false,
          ),
          const SizedBox(height: 10),
          BanglaTextField(
            controller: _bodyController,
            label: _language.isBangla
                ? 'প্রতিবেদনের মূল বক্তব্য'
                : 'Main report body',
            minLines: 14,
            maxLines: 28,
            autoTranslate: _language.isBangla,
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _ReportTemplate {
  final String id;
  final String banglaName;
  final String englishName;
  final String banglaRecipient;
  final String englishRecipient;
  final String Function(CaseFile? file) banglaSubject;
  final String Function(CaseFile? file) englishSubject;
  final String Function(OfficerProfile officer, CaseFile? file) banglaBody;
  final String Function(OfficerProfile officer, CaseFile? file) englishBody;

  const _ReportTemplate({
    required this.id,
    required this.banglaName,
    required this.englishName,
    required this.banglaRecipient,
    required this.englishRecipient,
    required this.banglaSubject,
    required this.englishSubject,
    required this.banglaBody,
    required this.englishBody,
  });

  String nameFor(DocumentLanguage language) =>
      language.isBangla ? banglaName : englishName;

  String recipientFor(DocumentLanguage language) =>
      language.isBangla ? banglaRecipient : englishRecipient;

  String subjectFor(DocumentLanguage language, CaseFile? file) =>
      language.isBangla ? banglaSubject(file) : englishSubject(file);

  String bodyFor(
    DocumentLanguage language,
    OfficerProfile officer,
    CaseFile? file,
  ) => language.isBangla
      ? banglaBody(officer, file)
      : englishBody(officer, file);
}

String _caseReferenceBn(OfficerProfile officer, CaseFile? file) =>
    '${officer.policeStation} থানা মামলা নং ${file?.psCaseNo ?? ''}, তারিখ ${file?.caseDate ?? ''}, ধারা ${file?.sections ?? ''}';

String _caseReferenceEn(OfficerProfile officer, CaseFile? file) =>
    '${officer.policeStation} Case No. ${file?.psCaseNo ?? ''} dated ${file?.caseDate ?? ''}, U/S ${file?.sections ?? ''}';

final List<_ReportTemplate> _caseTemplates = [
  _ReportTemplate(
    id: 'sp_progress',
    banglaName: 'পুলিশ সুপারের নিকট মামলা অগ্রগতি প্রতিবেদন',
    englishName: 'Case Progress Report to Superintendent of Police',
    banglaRecipient: 'পুলিশ সুপার, পূর্ব বর্ধমান',
    englishRecipient: 'The Superintendent of Police, Purba Bardhaman',
    banglaSubject: (file) =>
        '${file?.displayTitle ?? 'উক্ত বিষয়'}-এর তদন্তের অগ্রগতি প্রতিবেদন',
    englishSubject: (file) =>
        'Progress of investigation of ${file?.displayTitle ?? 'the matter noted above'}',
    banglaBody: (officer, file) => '''সবিনয় নিবেদন এই যে, লিখিত অভিযোগ/এফআইআরের ভিত্তিতে ${file?.caseDate ?? ''} তারিখে ${file?.sections ?? ''} ধারায় উপরোক্ত মামলাটি রুজু হয়।

তদন্তের বর্তমান অগ্রগতি নিম্নরূপ:–
১। সংক্ষিপ্ত ঘটনা: ${file?.firGist ?? ''}
২। ঘটনাস্থল: ${file?.placeOfOccurrence ?? ''}
৩। অভিযোগকারী: ${file?.complainantName ?? ''}
৪। ভুক্তভোগী: ${file?.victimName ?? ''}
৫। অভিযুক্ত/সন্দেহভাজন: ${file?.accusedName ?? ''}
৬। এ পর্যন্ত গৃহীত তদন্তমূলক পদক্ষেপ: 
৭। সংগৃহীত সাক্ষ্য/নথি/বস্তুগত বা ডিজিটাল প্রমাণ: 
৮। গ্রেপ্তার/উদ্ধার/জব্দের বিবরণ: 
৯। তদন্তের বর্তমান অবস্থা: 
১০। প্রস্তাবিত পরবর্তী পদক্ষেপ: 

সদয় অবগতির জন্য পেশ করা হলো।''',
    englishBody: (officer, file) => '''Most respectfully submitted that the above-noted case was registered on ${file?.caseDate ?? ''} under sections ${file?.sections ?? ''} on the basis of the written complaint/FIR.

The present progress of investigation is as follows:–
1. Brief facts: ${file?.firGist ?? ''}
2. Place of occurrence: ${file?.placeOfOccurrence ?? ''}
3. Complainant: ${file?.complainantName ?? ''}
4. Victim: ${file?.victimName ?? ''}
5. Accused/suspect: ${file?.accusedName ?? ''}
6. Investigative steps taken so far: 
7. Oral, documentary, material or digital evidence collected: 
8. Arrest/recovery/seizure particulars: 
9. Present status of investigation: 
10. Proposed next course of action: 

Submitted for favour of kind information.''',
  ),
  _ReportTemplate(
    id: 'sdpo_progress',
    banglaName: 'এসডিপিও-র নিকট মামলা প্রতিবেদন',
    englishName: 'Case Report to SDPO',
    banglaRecipient: 'মহকুমা পুলিশ আধিকারিক, কালনা',
    englishRecipient: 'The Sub-Divisional Police Officer, Kalna',
    banglaSubject: (file) => '${file?.displayTitle ?? 'উক্ত বিষয়'} সম্পর্কে প্রতিবেদন',
    englishSubject: (file) => 'Report regarding ${file?.displayTitle ?? 'the matter noted above'}',
    banglaBody: (officer, file) => '''সবিনয় নিবেদন এই যে, উপরোক্ত মামলার তদন্তকালে নিম্নলিখিত তথ্য ও অগ্রগতি পাওয়া গেছে।

মামলার সূত্র: ${_caseReferenceBn(officer, file)}।

সংক্ষিপ্ত ঘটনা: ${file?.firGist ?? ''}

তদন্তে গৃহীত পদক্ষেপ:
১। মামলার নথিপত্র পর্যালোচনা করা হয়েছে।
২। প্রাসঙ্গিক সাক্ষীদের জিজ্ঞাসাবাদ করা হয়েছে।
৩। প্রয়োজনীয় রিকুইজিশন/নথি সংগ্রহের ব্যবস্থা গ্রহণ করা হয়েছে।
৪। বর্তমান অবস্থা: 
৫। পরবর্তী পদক্ষেপ: 

সদয় পর্যালোচনা ও প্রয়োজনীয় নির্দেশের জন্য পেশ করা হলো।''',
    englishBody: (officer, file) => '''Most respectfully submitted that the following facts and progress have emerged during investigation of the above-noted case.

Case reference: ${_caseReferenceEn(officer, file)}.

Brief facts: ${file?.firGist ?? ''}

Steps taken during investigation:
1. The case records have been examined.
2. Relevant witnesses have been examined.
3. Necessary requisitions have been issued and records are being collected.
4. Present status: 
5. Proposed next steps: 

Submitted for favour of kind perusal and necessary direction.''',
  ),
  _ReportTemplate(
    id: 'sdo_report',
    banglaName: 'এসডিও-র নিকট অনুসন্ধান প্রতিবেদন',
    englishName: 'Enquiry Report to SDO',
    banglaRecipient: 'মহকুমা শাসক, কালনা',
    englishRecipient: 'The Sub-Divisional Officer, Kalna',
    banglaSubject: (file) => '${file?.displayTitle ?? 'উক্ত বিষয়'} সম্পর্কে অনুসন্ধান প্রতিবেদন',
    englishSubject: (file) => 'Enquiry report regarding ${file?.displayTitle ?? 'the matter noted above'}',
    banglaBody: (officer, file) => '''সবিনয় নিবেদন এই যে, নির্দেশ/এন্ডোর্সমেন্ট অনুসারে উপরোক্ত বিষয়ে অনুসন্ধান/তদন্ত করা হয়েছে।

অনুসন্ধানকালে স্থানীয়ভাবে যাচাই করা হয় এবং উপলব্ধ ব্যক্তিদের সঙ্গে কথা বলা হয়। প্রাপ্ত তথ্য নিম্নরূপ:–
১। মামলা/বিষয়ের সূত্র: ${file?.displayTitle ?? ''}
২। ধারা/বিষয়: ${file?.sections ?? ''}
৩। স্থান: ${file?.placeOfOccurrence ?? ''}
৪। সংক্ষিপ্ত ঘটনা: ${file?.firGist ?? ''}
৫। অনুসন্ধানে প্রাপ্ত ফলাফল: 
৬। বর্তমান পরিস্থিতি: 
৭। গৃহীত/প্রস্তাবিত পুলিশি ব্যবস্থা: 

সদয় অবগতি ও প্রয়োজনীয় আদেশের জন্য পেশ করা হলো।''',
    englishBody: (officer, file) => '''Most respectfully submitted that an enquiry/investigation was conducted into the above matter pursuant to the endorsement/direction.

Local verification was conducted and available persons were examined. The facts found are as follows:–
1. Case/matter reference: ${file?.displayTitle ?? ''}
2. Sections/subject: ${file?.sections ?? ''}
3. Place: ${file?.placeOfOccurrence ?? ''}
4. Brief facts: ${file?.firGist ?? ''}
5. Findings of enquiry: 
6. Present situation: 
7. Police action taken/proposed: 

Submitted for favour of kind information and necessary order.''',
  ),
];

final List<_ReportTemplate> _generalTemplates = [
  _ReportTemplate(
    id: 'general_sp',
    banglaName: 'পুলিশ সুপারের নিকট সাধারণ প্রতিবেদন',
    englishName: 'General Report to Superintendent of Police',
    banglaRecipient: 'পুলিশ সুপার, পূর্ব বর্ধমান',
    englishRecipient: 'The Superintendent of Police, Purba Bardhaman',
    banglaSubject: (_) => 'প্রতিবেদন পেশ প্রসঙ্গে',
    englishSubject: (_) => 'Submission of report',
    banglaBody: (officer, _) => '''সবিনয় নিবেদন এই যে, সদয় অবগতির জন্য নিম্নলিখিত প্রতিবেদন পেশ করা হলো।

১। সূত্র/তথ্যের উৎস: 
২। তারিখ ও সময়: 
৩। সংশ্লিষ্ট স্থান/দপ্তর/এলাকা: 
৪। সংক্ষিপ্ত ঘটনা: 
৫। অনুসন্ধান/গৃহীত ব্যবস্থা: 
৬। বর্তমান অবস্থা: 
৭। প্রস্তাবিত পরবর্তী ব্যবস্থা/প্রার্থনা: 

সদয় অবগতি ও প্রয়োজনীয় নির্দেশের জন্য পেশ করা হলো।''',
    englishBody: (officer, _) => '''Most respectfully submitted that the following report is placed for favour of kind information.

1. Reference/source of information: 
2. Date and time: 
3. Place/office/area concerned: 
4. Brief facts: 
5. Enquiry/action taken: 
6. Present status: 
7. Proposed further action/prayer: 

Submitted for favour of kind information and necessary direction.''',
  ),
  _ReportTemplate(
    id: 'general_sdpo',
    banglaName: 'এসডিপিও-র নিকট সাধারণ প্রতিবেদন',
    englishName: 'General Report to SDPO',
    banglaRecipient: 'মহকুমা পুলিশ আধিকারিক, কালনা',
    englishRecipient: 'The Sub-Divisional Police Officer, Kalna',
    banglaSubject: (_) => 'সদয় পর্যালোচনার জন্য প্রতিবেদন',
    englishSubject: (_) => 'Report for kind perusal',
    banglaBody: (officer, _) => '''সবিনয় নিবেদন এই যে, সদয় পর্যালোচনা ও প্রয়োজনীয় নির্দেশের জন্য নিম্নলিখিত বিষয়সমূহ পেশ করা হলো।

১। সূত্র: 
২। বিষয়বস্তু: 
৩। অনুসন্ধান/স্থানীয় যাচাইয়ে প্রাপ্ত তথ্য: 
৪। এ পর্যন্ত গৃহীত ব্যবস্থা: 
৫। বর্তমান পরিস্থিতি: 
৬। প্রস্তাবিত পরবর্তী ব্যবস্থা: 

সদয় পর্যালোচনা ও প্রয়োজনীয় নির্দেশের জন্য পেশ করা হলো।''',
    englishBody: (officer, _) => '''Most respectfully submitted that the following facts are placed for kind perusal and necessary direction.

1. Reference: 
2. Subject matter: 
3. Facts found during enquiry/local verification: 
4. Action taken so far: 
5. Present situation: 
6. Proposed further action: 

Submitted for favour of kind perusal and necessary direction.''',
  ),
  _ReportTemplate(
    id: 'general_sdo',
    banglaName: 'এসডিও/এক্সিকিউটিভ ম্যাজিস্ট্রেটের নিকট সাধারণ প্রতিবেদন',
    englishName: 'General Report to SDO/Executive Magistrate',
    banglaRecipient: 'মহকুমা শাসক, কালনা',
    englishRecipient: 'The Sub-Divisional Officer, Kalna',
    banglaSubject: (_) => 'অনুসন্ধান প্রতিবেদন',
    englishSubject: (_) => 'Enquiry report',
    banglaBody: (officer, _) => '''সবিনয় নিবেদন এই যে, এন্ডোর্সমেন্ট/নির্দেশ অনুসারে বিষয়টি সম্পর্কে স্থানীয়ভাবে অনুসন্ধান করা হয়েছে।

অনুসন্ধানে নিম্নলিখিত তথ্য পাওয়া গেছে:–
১। আবেদনকারী/তথ্যদাতার নাম ও ঠিকানা: 
২। অনুসন্ধানের স্থান: 
৩। যাঁদের সঙ্গে যোগাযোগ করা হয়েছে: 
৪। অনুসন্ধানে প্রকাশিত তথ্য: 
৫। গৃহীত/প্রস্তাবিত পুলিশি ব্যবস্থা: 
৬। মতামত/অনুসন্ধানের ফলাফল: 

সদয় অবগতি ও প্রয়োজনীয় আদেশের জন্য পেশ করা হলো।''',
    englishBody: (officer, _) => '''Most respectfully submitted that a local enquiry was conducted into the matter pursuant to the endorsement/direction.

The following facts were found during enquiry:–
1. Name and address of petitioner/informant: 
2. Place of enquiry: 
3. Persons contacted/examined: 
4. Facts revealed during enquiry: 
5. Police action taken/proposed: 
6. Opinion/result of enquiry: 

Submitted for favour of kind information and necessary order.''',
  ),
  _ReportTemplate(
    id: 'court_report',
    banglaName: 'বিজ্ঞ আদালতের নিকট সাধারণ প্রতিবেদন',
    englishName: 'General Report before the Learned Court',
    banglaRecipient: 'বিজ্ঞ সংশ্লিষ্ট আদালত',
    englishRecipient: 'The Learned Court concerned',
    banglaSubject: (_) => 'প্রতিবেদন পেশ প্রসঙ্গে',
    englishSubject: (_) => 'Submission of report',
    banglaBody: (officer, _) => '''সবিনয় নিবেদন এই যে, বিজ্ঞ আদালতের সদয় পর্যালোচনার জন্য নিম্নলিখিত প্রতিবেদন পেশ করা হলো।

১। সূত্র: 
২। বিষয়ের পটভূমি: 
৩। পুলিশ কর্তৃক গৃহীত পদক্ষেপ: 
৪। বর্তমান অবস্থা: 
৫। প্রার্থনা/নিবেদন: 

সদয় পর্যালোচনা ও প্রয়োজনীয় আদেশের জন্য পেশ করা হলো।''',
    englishBody: (officer, _) => '''Most respectfully submitted that the following report is placed before the Learned Court for kind consideration.

1. Reference: 
2. Background of the matter: 
3. Action taken by police: 
4. Present status: 
5. Prayer/submission: 

Submitted for favour of kind consideration and necessary order.''',
  ),
  _ReportTemplate(
    id: 'bank_report',
    banglaName: 'ব্যাংকের নিকট প্রতিবেদন/পত্র',
    englishName: 'Report/Letter to Bank',
    banglaRecipient: 'শাখা ব্যবস্থাপক, সংশ্লিষ্ট ব্যাংক',
    englishRecipient: 'The Branch Manager, Bank concerned',
    banglaSubject: (_) => 'প্রয়োজনীয় তথ্য/ব্যবস্থা গ্রহণের অনুরোধ',
    englishSubject: (_) => 'Request for necessary information/action',
    banglaBody: (officer, _) => '''মহাশয়/মহাশয়া,

উপরোক্ত বিষয়ের প্রেক্ষিতে অনুসন্ধান/তদন্তের স্বার্থে প্রয়োজনীয় ব্যবস্থা গ্রহণ এবং নিম্নলিখিত তথ্য সরবরাহ করার জন্য অনুরোধ করা হচ্ছে।

১। হিসাব/লেনদেনের বিবরণ: 
২। প্রয়োজনীয় তথ্য/ব্যবস্থা: 
৩। সূত্র নং/স্বীকৃতি নং: 
৪। প্রয়োজনীয় সময়সীমা: 

বিষয়টি জরুরি হিসেবে বিবেচনা করে যত দ্রুত সম্ভব উপলব্ধ তথ্য সরবরাহ করার অনুরোধ রইল।''',
    englishBody: (officer, _) => '''Sir/Madam,

In connection with the matter noted above, you are requested to take necessary action and furnish the following information for the purpose of enquiry/investigation.

1. Account/transaction particulars: 
2. Information/action required: 
3. Reference/Acknowledgement No.: 
4. Required period/time limit: 

The matter may kindly be treated as urgent and the available information supplied at the earliest.''',
  ),
  _ReportTemplate(
    id: 'hospital_report',
    banglaName: 'হাসপাতালের নিকট প্রতিবেদন/রিকুইজিশন',
    englishName: 'Report/Requisition to Hospital',
    banglaRecipient: 'মেডিক্যাল অফিসার/সুপারিনটেনডেন্ট, সংশ্লিষ্ট হাসপাতাল',
    englishRecipient: 'The Medical Officer/Superintendent, Hospital concerned',
    banglaSubject: (_) => 'চিকিৎসা সংক্রান্ত নথি/প্রতিবেদন প্রদানের অনুরোধ',
    englishSubject: (_) => 'Request for medical records/report',
    banglaBody: (officer, _) => '''মহাশয়/মহাশয়া,

উপরোক্ত বিষয়ের প্রেক্ষিতে নিম্নলিখিত চিকিৎসা সংক্রান্ত নথি/প্রতিবেদন সরবরাহ করার জন্য অনুরোধ করা হচ্ছে।

১। রোগী/সংশ্লিষ্ট ব্যক্তির নাম: 
২। চিকিৎসা/ভর্তির তারিখ: 
৩। প্রয়োজনীয় নথি/প্রতিবেদন: 
৪। উদ্দেশ্য: 

সদয় অবগতি ও প্রয়োজনীয় ব্যবস্থা গ্রহণের জন্য প্রেরিত।''',
    englishBody: (officer, _) => '''Sir/Madam,

In connection with the matter noted above, you are requested to furnish the following medical records/report.

1. Name of patient/person concerned: 
2. Date of treatment/admission: 
3. Records/report required: 
4. Purpose: 

Sent for favour of kind information and necessary action.''',
  ),
  _ReportTemplate(
    id: 'blank_report',
    banglaName: 'ফাঁকা কাস্টম প্রতিবেদন',
    englishName: 'Blank Custom Report',
    banglaRecipient: 'সংশ্লিষ্ট আধিকারিক',
    englishRecipient: 'The Officer concerned',
    banglaSubject: (_) => 'প্রতিবেদন',
    englishSubject: (_) => 'Report',
    banglaBody: (officer, _) => '''সবিনয় নিবেদন এই যে,



সদয় অবগতি ও প্রয়োজনীয় ব্যবস্থা গ্রহণের জন্য পেশ করা হলো।''',
    englishBody: (officer, _) => '''Most respectfully submitted that,



Submitted for favour of kind information and necessary action.''',
  ),
];
