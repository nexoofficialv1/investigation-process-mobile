import 'package:flutter/material.dart';

import '../core/document_language.dart';
import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/cd_generator_service.dart';
import '../services/document_translation_service.dart';
import '../services/local_store_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/form_helpers.dart';
import 'cd_editor_screen.dart';

class CdBuilderScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const CdBuilderScreen({
    super.key,
    required this.profile,
    required this.caseFile,
  });

  @override
  State<CdBuilderScreen> createState() => _CdBuilderScreenState();
}

class _CdBuilderScreenState extends State<CdBuilderScreen> {
  final LocalStoreService _store = LocalStoreService();
  final CdQuestionAnswer _answers = CdQuestionAnswer();

  int? cdNumber;
  DocumentLanguage _language = DocumentLanguage.bangla;
  List<PendingCdAction> pendingActions = [];
  final Set<String> selectedPendingActionIds = <String>{};
  final witness = TextEditingController();
  final po = TextEditingController();
  final sketch = TextEditingController();
  final medical = TextEditingController();
  final requisition = TextEditingController();
  final seizure = TextEditingController();
  final arrest = TextEditingController();
  final notice = TextEditingController();
  final courtPrayer = TextEditingController();
  final receivedDocument = TextEditingController();
  final localEnquiry = TextEditingController();
  final verification = TextEditingController();
  final digitalEvidence = TextEditingController();
  final importantDevelopment = TextEditingController();

  String _t(String bangla, String english) =>
      _language.isBangla ? bangla : english;

  List<TextEditingController> get _answerControllers => [
        witness,
        po,
        sketch,
        medical,
        requisition,
        seizure,
        arrest,
        notice,
        courtPrayer,
        receivedDocument,
        localEnquiry,
        verification,
        digitalEvidence,
        importantDevelopment,
      ];

  @override
  void initState() {
    super.initState();
    _loadNextCd();
    _loadPendingActions();
  }

  Future<void> _loadNextCd() async {
    final next = await _store.nextCdNumber(widget.caseFile.id);
    if (!mounted) return;
    setState(() => cdNumber = next);
  }

  Future<void> _loadPendingActions() async {
    final actions = await _store.loadPendingCdActions(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      pendingActions = actions;
      selectedPendingActionIds.addAll(actions.map((e) => e.id));
    });
  }

  @override
  void dispose() {
    for (final controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    await DocumentTranslationService.instance.translateControllers(
      _answerControllers,
      target: _language,
    );
    if (!mounted) return;

    final number = cdNumber;
    if (number == null) return;

    _answers.witnessDetails = witness.text.trim();
    _answers.poDetails = po.text.trim();
    _answers.sketchDetails = sketch.text.trim();
    _answers.medicalDetails = medical.text.trim();
    _answers.requisitionDetails = requisition.text.trim();
    _answers.seizureDetails = seizure.text.trim();
    _answers.arrestDetails = arrest.text.trim();
    _answers.noticeDetails = notice.text.trim();
    _answers.courtPrayerDetails = courtPrayer.text.trim();
    _answers.receivedDocumentDetails = receivedDocument.text.trim();
    _answers.localEnquiryDetails = localEnquiry.text.trim();
    _answers.verificationDetails = verification.text.trim();
    _answers.digitalEvidenceDetails = digitalEvidence.text.trim();
    _answers.importantDevelopmentDetails = importantDevelopment.text.trim();

    final selectedPending = pendingActions
        .where((e) => selectedPendingActionIds.contains(e.id))
        .toList();
    final translatedPending = <String>[];
    for (final action in selectedPending) {
      translatedPending.add(
        await DocumentTranslationService.instance.translate(
          action.paragraph,
          target: _language,
        ),
      );
    }
    _answers.pendingActionParagraphs = translatedPending;

    final service = CdGeneratorService();
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final time = _language.isBangla
        ? '$hour.$minute ঘণ্টা'
        : '$hour:$minute hrs';
    final tableLines = service.generateOfficialCdTableLines(
      caseFile: widget.caseFile,
      cdNumber: number,
      time: time,
      defaultPlace: widget.profile.policeStation,
      answers: _answers,
      language: _language,
    );
    final body = tableLines.map((e) => e.proceedings).join('\n\n');
    final cd = CdEntry.newDraft(
      caseId: widget.caseFile.id,
      cdNumber: number,
      body: body,
      placeOfEntry: widget.profile.policeStation,
      tableLines: tableLines,
      languageCode: _language.code,
    );
    await _store.saveCd(cd);
    await _store.markPendingCdActionsConsumed(
      selectedPending.map((e) => e.id).toList(),
    );
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CdEditorScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
          cd: cd,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final number = cdNumber;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          number == null
              ? _t('নতুন সিডি', 'New Case Diary')
              : _t('সিডি-$number তৈরি করুন', 'Create CD-$number'),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_t('সিডি তৈরি করুন', 'Generate Case Diary')),
          ),
        ),
      ),
      body: number == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(
                            'সিডি-$number তৈরি হবে। হ্যাঁ/না নির্বাচন করে বিস্তারিত লিখুন। “সিডি তৈরি করুন” চাপলে খসড়া তৈরি হবে।',
                            'CD-$number will be generated. Select Yes/No and enter the details, then tap “Generate Case Diary”.',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<DocumentLanguage>(
                          value: _language,
                          decoration: InputDecoration(
                            labelText: _t(
                              'সিডির ভাষা',
                              'Case Diary language',
                            ),
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
                            if (language != null) {
                              setState(() => _language = language);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t(
                            'বাংলা নির্বাচন করলে সিডির স্থির বাক্য, সারাংশ, কলাম ও PDF/DOC শিরোনাম বাংলায় হবে। ইংরেজিতে লেখা বিবরণ সংরক্ষণের আগে বাংলায় রূপান্তরের চেষ্টা হবে।',
                            'English selection generates the fixed CD narration, synopsis, column headings and PDF/DOC headings in English. Bangla input will be translated before generation when online translation is available.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (pendingActions.isNotEmpty)
                  AppSectionCard(
                    title: _t(
                      'ফর্ম/রিকুইজিশন থেকে অপেক্ষমাণ সিডি এন্ট্রি',
                      'Pending CD entries from forms/requisitions',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(
                            'আগে সংরক্ষিত/এক্সপোর্ট করা রিকুইজিশন বা ফর্ম থেকে সিডিতে উল্লেখের অপেক্ষমাণ এন্ট্রি আছে। আজকের সিডিতে যেগুলি রাখতে চান সেগুলি টিক দিন।',
                            'The following entries are pending from previously saved/exported forms or requisitions. Select the entries to include in today’s case diary.',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pendingActions.map(
                          (action) => CheckboxListTile(
                            value: selectedPendingActionIds.contains(action.id),
                            title: Text(
                              action.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${action.actionDate} • ${action.paragraph}',
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedPendingActionIds.add(action.id);
                                } else {
                                  selectedPendingActionIds.remove(action.id);
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                _questionCard(
                  _t(
                    '১। আজ কোনো সাক্ষীকে জিজ্ঞাসাবাদ করেছেন?',
                    '1. Did you examine any witness today?',
                  ),
                  _answers.examinedWitness,
                  (value) =>
                      setState(() => _answers.examinedWitness = value),
                  witness,
                  _t(
                    'সাক্ষী জিজ্ঞাসাবাদের বিবরণ',
                    'Details of witness examination',
                  ),
                ),
                _questionCard(
                  _t(
                    '২। আজ ঘটনাস্থল পরিদর্শন করেছেন?',
                    '2. Did you visit the place of occurrence today?',
                  ),
                  _answers.visitedPo,
                  (value) => setState(() => _answers.visitedPo = value),
                  po,
                  _t(
                    'ঘটনাস্থল পরিদর্শনের বিবরণ',
                    'Details of visit to the place of occurrence',
                  ),
                ),
                _questionCard(
                  _t(
                    '৩। খসড়া নকশা প্রস্তুত/সংশোধন করেছেন?',
                    '3. Did you prepare/update the rough sketch map?',
                  ),
                  _answers.sketchMap,
                  (value) => setState(() => _answers.sketchMap = value),
                  sketch,
                  _t('খসড়া নকশার বিবরণ', 'Details of rough sketch map'),
                ),
                _questionCard(
                  _t(
                    '৪। কোনো চিকিৎসা সংক্রান্ত নথি সংগ্রহ করেছেন?',
                    '4. Did you collect any medical papers?',
                  ),
                  _answers.medicalPaper,
                  (value) => setState(() => _answers.medicalPaper = value),
                  medical,
                  _t(
                    'চিকিৎসা / বিএইচটি / আঘাতের বিবরণ',
                    'Medical/BHT/injury-report details',
                  ),
                ),
                _questionCard(
                  _t(
                    '৫। কোনো রিকুইজিশন পাঠিয়েছেন?',
                    '5. Did you send any requisition?',
                  ),
                  _answers.requisition,
                  (value) => setState(() => _answers.requisition = value),
                  requisition,
                  _t('রিকুইজিশনের বিবরণ', 'Details of requisition'),
                ),
                _questionCard(
                  _t(
                    '৬। কোনো বস্তু/নথি জব্দ করেছেন?',
                    '6. Did you seize any article/document?',
                  ),
                  _answers.seizure,
                  (value) => setState(() => _answers.seizure = value),
                  seizure,
                  _t('জব্দের বিবরণ', 'Details of seizure'),
                ),
                _questionCard(
                  _t(
                    '৭। কোনো অভিযুক্তকে গ্রেপ্তার করেছেন?',
                    '7. Did you arrest any accused?',
                  ),
                  _answers.arrest,
                  (value) => setState(() => _answers.arrest = value),
                  arrest,
                  _t('গ্রেপ্তারের বিবরণ', 'Details of arrest'),
                ),
                _questionCard(
                  _t(
                    '৮। কোনো নোটিশ তামিল করেছেন?',
                    '8. Did you serve any notice?',
                  ),
                  _answers.notice,
                  (value) => setState(() => _answers.notice = value),
                  notice,
                  _t('নোটিশের বিবরণ', 'Details of notice'),
                ),
                _questionCard(
                  _t(
                    '৯। আদালতে কোনো প্রার্থনা পেশ করেছেন?',
                    '9. Did you submit any prayer before the Court?',
                  ),
                  _answers.courtPrayer,
                  (value) => setState(() => _answers.courtPrayer = value),
                  courtPrayer,
                  _t(
                    'আদালতের প্রার্থনার বিবরণ',
                    'Details of Court prayer',
                  ),
                ),
                _questionCard(
                  _t(
                    '১০। কোনো আদেশ/প্রতিবেদন/নথি পেয়েছেন?',
                    '10. Did you receive any order/report/document?',
                  ),
                  _answers.receivedDocument,
                  (value) =>
                      setState(() => _answers.receivedDocument = value),
                  receivedDocument,
                  _t('প্রাপ্ত নথির বিবরণ', 'Details of document received'),
                ),
                _questionCard(
                  _t(
                    '১১। স্থানীয় অনুসন্ধান করেছেন?',
                    '11. Did you conduct local enquiry?',
                  ),
                  _answers.localEnquiry,
                  (value) => setState(() => _answers.localEnquiry = value),
                  localEnquiry,
                  _t('স্থানীয় অনুসন্ধানের বিবরণ', 'Details of local enquiry'),
                ),
                _questionCard(
                  _t(
                    '১২। কোনো ব্যক্তি/তথ্য যাচাই করেছেন?',
                    '12. Did you verify any person/information?',
                  ),
                  _answers.verification,
                  (value) => setState(() => _answers.verification = value),
                  verification,
                  _t('যাচাইয়ের বিবরণ', 'Details of verification'),
                ),
                _questionCard(
                  _t(
                    '১৩। আলামত/প্রমাণ সংগ্রহ বা সংরক্ষণের ব্যবস্থা নিয়েছেন?',
                    '13. Did you collect or preserve any evidence?',
                  ),
                  _answers.digitalEvidence,
                  (value) =>
                      setState(() => _answers.digitalEvidence = value),
                  digitalEvidence,
                  _t('ডিজিটাল প্রমাণের বিবরণ', 'Details of evidence'),
                ),
                _questionCard(
                  _t(
                    '১৪। আজ কোনো গুরুত্বপূর্ণ অগ্রগতি হয়েছে?',
                    '14. Was there any important development today?',
                  ),
                  _answers.importantDevelopment,
                  (value) =>
                      setState(() => _answers.importantDevelopment = value),
                  importantDevelopment,
                  _t(
                    'গুরুত্বপূর্ণ অগ্রগতির বিবরণ',
                    'Details of important development',
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _questionCard(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    TextEditingController controller,
    String label,
  ) {
    return AppSectionCard(
      title: title,
      child: Column(
        children: [
          FormHelpers.yesNoTile(
            title: _t('উত্তর', 'Answer'),
            value: value,
            onChanged: onChanged,
          ),
          if (value)
            FormHelpers.textField(
              controller: controller,
              label: label,
              maxLines: 4,
              autoTranslate: _language.isBangla,
            ),
        ],
      ),
    );
  }
}
