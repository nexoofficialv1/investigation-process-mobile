import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/cd_generator_service.dart';
import '../services/local_store_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/form_helpers.dart';
import 'cd_editor_screen.dart';

class CdBuilderScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const CdBuilderScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<CdBuilderScreen> createState() => _CdBuilderScreenState();
}

class _CdBuilderScreenState extends State<CdBuilderScreen> {
  final LocalStoreService _store = LocalStoreService();
  final CdQuestionAnswer _answers = CdQuestionAnswer();

  int? cdNumber;
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
    for (final c in [witness, po, sketch, medical, requisition, seizure, arrest, notice, courtPrayer, receivedDocument, localEnquiry, verification, digitalEvidence, importantDevelopment]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
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
    final selectedPending = pendingActions.where((e) => selectedPendingActionIds.contains(e.id)).toList();
    _answers.pendingActionParagraphs = selectedPending.map((e) => e.paragraph).toList();

    final service = CdGeneratorService();
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')} ঘণ্টা';
    final tableLines = service.generateOfficialCdTableLines(
      caseFile: widget.caseFile,
      cdNumber: number,
      time: time,
      defaultPlace: widget.profile.policeStation,
      answers: _answers,
    );
    final body = tableLines.map((e) => e.proceedings).join('\n\n');
    final cd = CdEntry.newDraft(
      caseId: widget.caseFile.id,
      cdNumber: number,
      body: body,
      placeOfEntry: widget.profile.policeStation,
      tableLines: tableLines,
    );
    await _store.saveCd(cd);
    await _store.markPendingCdActionsConsumed(selectedPending.map((e) => e.id).toList());
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CdEditorScreen(profile: widget.profile, caseFile: widget.caseFile, cd: cd)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final number = cdNumber;
    return Scaffold(
      appBar: AppBar(title: Text(number == null ? 'নতুন সিডি' : 'সিডি-$number তৈরি করুন')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(onPressed: _generate, icon: const Icon(Icons.auto_awesome), label: const Text('সিডি তৈরি করুন')),
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
                    child: Text('সিডি-$number তৈরি হবে। হ্যাঁ/না নির্বাচন করে বিস্তারিত লিখুন। “সিডি তৈরি করুন” চাপলে খসড়া তৈরি হবে।', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                if (pendingActions.isNotEmpty)
                  AppSectionCard(
                    title: 'ফর্ম/রিকুইজিশন থেকে অপেক্ষমাণ সিডি এন্ট্রি',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('আগে সংরক্ষিত/এক্সপোর্ট করা রিকুইজিশন বা ফর্ম থেকে সিডিতে উল্লেখের অপেক্ষমাণ এন্ট্রি আছে। আজকের সিডিতে যেগুলি রাখতে চান সেগুলি টিক দিন।'),
                        const SizedBox(height: 8),
                        ...pendingActions.map((action) => CheckboxListTile(
                              value: selectedPendingActionIds.contains(action.id),
                              title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${action.actionDate} • ${action.paragraph}'),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedPendingActionIds.add(action.id);
                                  } else {
                                    selectedPendingActionIds.remove(action.id);
                                  }
                                });
                              },
                            )),
                      ],
                    ),
                  ),
                _questionCard('১। আজ কোনো সাক্ষীকে জিজ্ঞাসাবাদ করেছেন?', _answers.examinedWitness, (v) => setState(() => _answers.examinedWitness = v), witness, 'সাক্ষী জিজ্ঞাসাবাদের বিবরণ'),
                _questionCard('২। আজ ঘটনাস্থল পরিদর্শন করেছেন?', _answers.visitedPo, (v) => setState(() => _answers.visitedPo = v), po, 'ঘটনাস্থল পরিদর্শনের বিবরণ'),
                _questionCard('৩। খসড়া নকশা প্রস্তুত/সংশোধন করেছেন?', _answers.sketchMap, (v) => setState(() => _answers.sketchMap = v), sketch, 'খসড়া নকশার বিবরণ'),
                _questionCard('৪। কোনো চিকিৎসা সংক্রান্ত নথি সংগ্রহ করেছেন?', _answers.medicalPaper, (v) => setState(() => _answers.medicalPaper = v), medical, 'চিকিৎসা / বিএইচটি / আঘাতের বিবরণ'),
                _questionCard('৫। কোনো রিকুইজিশন পাঠিয়েছেন?', _answers.requisition, (v) => setState(() => _answers.requisition = v), requisition, 'রিকুইজিশনের বিবরণ'),
                _questionCard('৬। কোনো বস্তু/নথি জব্দ করেছেন?', _answers.seizure, (v) => setState(() => _answers.seizure = v), seizure, 'জব্দের বিবরণ'),
                _questionCard('৭। কোনো অভিযুক্তকে গ্রেপ্তার করেছেন?', _answers.arrest, (v) => setState(() => _answers.arrest = v), arrest, 'গ্রেপ্তারের বিবরণ'),
                _questionCard('৮। কোনো নোটিশ তামিল করেছেন?', _answers.notice, (v) => setState(() => _answers.notice = v), notice, 'নোটিশের বিবরণ'),
                _questionCard('৯। আদালতে কোনো প্রার্থনা পেশ করেছেন?', _answers.courtPrayer, (v) => setState(() => _answers.courtPrayer = v), courtPrayer, 'আদালতের প্রার্থনার বিবরণ'),
                _questionCard('১০। কোনো আদেশ/প্রতিবেদন/নথি পেয়েছেন?', _answers.receivedDocument, (v) => setState(() => _answers.receivedDocument = v), receivedDocument, 'প্রাপ্ত নথির বিবরণ'),
                _questionCard('১১। স্থানীয় অনুসন্ধান করেছেন?', _answers.localEnquiry, (v) => setState(() => _answers.localEnquiry = v), localEnquiry, 'স্থানীয় অনুসন্ধানের বিবরণ'),
                _questionCard('১২। কোনো ব্যক্তি/তথ্য যাচাই করেছেন?', _answers.verification, (v) => setState(() => _answers.verification = v), verification, 'যাচাইয়ের বিবরণ'),
                _questionCard('১৩। আলামত/প্রমাণ সংগ্রহ বা সংরক্ষণের ব্যবস্থা নিয়েছেন?', _answers.digitalEvidence, (v) => setState(() => _answers.digitalEvidence = v), digitalEvidence, 'ডিজিটাল প্রমাণের বিবরণ'),
                _questionCard('১৪। আজ কোনো গুরুত্বপূর্ণ অগ্রগতি হয়েছে?', _answers.importantDevelopment, (v) => setState(() => _answers.importantDevelopment = v), importantDevelopment, 'গুরুত্বপূর্ণ অগ্রগতির বিবরণ'),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _questionCard(String title, bool value, ValueChanged<bool> onChanged, TextEditingController controller, String label) {
    return AppSectionCard(
      title: title,
      child: Column(
        children: [
          FormHelpers.yesNoTile(title: 'উত্তর', value: value, onChanged: onChanged),
          if (value) FormHelpers.textField(controller: controller, label: label, maxLines: 4),
        ],
      ),
    );
  }
}
