import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/officer_profile.dart';
import 'mandatory_first_cd_screen.dart';
import '../services/local_store_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/form_helpers.dart';

class CaseFormScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile? existing;

  const CaseFormScreen({super.key, required this.profile, this.existing});

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final LocalStoreService _store = LocalStoreService();

  late CaseFile _base;
  late final TextEditingController psCaseNo;
  late final TextEditingController caseDate;
  late final TextEditingController sections;
  late final TextEditingController crimeHead;
  late final TextEditingController po;
  late final TextEditingController dto;
  late final TextEditingController dtr;
  late final TextEditingController complainant;
  late final TextEditingController victim;
  late final TextEditingController accused;
  late final TextEditingController gist;
  late final TextEditingController tookUpDate;
  late final TextEditingController poDetails;
  late final TextEditingController sketchDetails;
  late final TextEditingController witnessDetails;
  late final TextEditingController medicalDetails;
  late final TextEditingController seizureDetails;
  late final TextEditingController evidenceDetails;

  bool visitedPo = false;
  bool sketchPrepared = false;
  bool witnessExamined = false;
  bool medicalRequired = false;
  bool seizureRequired = false;
  bool evidenceRequired = false;

  @override
  void initState() {
    super.initState();
    _base = widget.existing ?? CaseFile.empty(ioName: '${widget.profile.rank} ${widget.profile.name}');
    psCaseNo = TextEditingController(text: _base.psCaseNo);
    caseDate = TextEditingController(text: _base.caseDate);
    sections = TextEditingController(text: _base.sections);
    crimeHead = TextEditingController(text: _base.crimeHead);
    po = TextEditingController(text: _base.placeOfOccurrence);
    dto = TextEditingController(text: _base.dateTimeOccurrence);
    dtr = TextEditingController(text: _base.dateTimeReporting);
    complainant = TextEditingController(text: _base.complainantName);
    victim = TextEditingController(text: _base.victimName);
    accused = TextEditingController(text: _base.accusedName);
    gist = TextEditingController(text: _base.firGist);

    final start = _base.investigationStart;
    tookUpDate = TextEditingController(text: start.tookUpDate);
    poDetails = TextEditingController(text: start.poDetails);
    sketchDetails = TextEditingController(text: start.sketchDetails);
    witnessDetails = TextEditingController(text: start.witnessDetails);
    medicalDetails = TextEditingController(text: start.medicalDetails);
    seizureDetails = TextEditingController(text: start.seizureDetails);
    evidenceDetails = TextEditingController(text: start.evidenceDetails);
    visitedPo = start.visitedPo;
    sketchPrepared = start.sketchPrepared;
    witnessExamined = start.witnessExamined;
    medicalRequired = start.medicalRequired;
    seizureRequired = start.seizureRequired;
    evidenceRequired = start.evidenceRequired;
  }

  @override
  void dispose() {
    for (final c in [psCaseNo, caseDate, sections, crimeHead, po, dto, dtr, complainant, victim, accused, gist, tookUpDate, poDetails, sketchDetails, witnessDetails, medicalDetails, seizureDetails, evidenceDetails]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (psCaseNo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('থানা মামলা নং আবশ্যক')));
      return;
    }

    final start = InvestigationStart(
      ioName: '${widget.profile.rank} ${widget.profile.name}',
      tookUpDate: tookUpDate.text.trim(),
      visitedPo: visitedPo,
      poDetails: poDetails.text.trim(),
      sketchPrepared: sketchPrepared,
      sketchDetails: sketchDetails.text.trim(),
      witnessExamined: witnessExamined,
      witnessDetails: witnessDetails.text.trim(),
      medicalRequired: medicalRequired,
      medicalDetails: medicalDetails.text.trim(),
      seizureRequired: seizureRequired,
      seizureDetails: seizureDetails.text.trim(),
      evidenceRequired: evidenceRequired,
      evidenceDetails: evidenceDetails.text.trim(),
    );

    final updated = _base.copyWith(
      psCaseNo: psCaseNo.text.trim(),
      caseDate: caseDate.text.trim(),
      sections: sections.text.trim(),
      crimeHead: crimeHead.text.trim(),
      placeOfOccurrence: po.text.trim(),
      dateTimeOccurrence: dto.text.trim(),
      dateTimeReporting: dtr.text.trim(),
      complainantName: complainant.text.trim(),
      victimName: victim.text.trim(),
      accusedName: accused.text.trim(),
      firGist: gist.text.trim(),
      investigationStart: start,
    );
    await _store.saveCase(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('মামলা সংরক্ষিত হয়েছে')),
    );

    if (widget.existing != null) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'মামলা সংরক্ষিত হয়েছে—Mandatory First Case Diary শুরু হচ্ছে',
        ),
      ),
    );
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MandatoryFirstCdScreen(
          profile: widget.profile,
          caseFile: updated,
        ),
      ),
    );
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'নতুন মামলা তৈরি' : 'মামলা সম্পাদনা')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('মামলা সংরক্ষণ করুন')),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSectionCard(
            title: 'ধাপ ১: প্রাথমিক বিবরণ',
            icon: Icons.assignment,
            child: Column(
              children: [
                FormHelpers.textField(controller: psCaseNo, label: 'থানা মামলা নং/সাল'),
                FormHelpers.dateField(context: context, controller: caseDate, label: 'মামলার তারিখ'),
                FormHelpers.textField(controller: sections, label: 'আইনের ধারা'),
                FormHelpers.textField(controller: crimeHead, label: 'অপরাধের শ্রেণি/মামলার ধরন'),
              ],
            ),
          ),
          AppSectionCard(
            title: 'ধাপ ২: ঘটনার বিবরণ',
            icon: Icons.place,
            child: Column(
              children: [
                FormHelpers.textField(controller: po, label: 'ঘটনাস্থল', maxLines: 2),
                FormHelpers.dateTimeField(context: context, controller: dto, label: 'ঘটনার তারিখ ও সময়'),
                FormHelpers.dateTimeField(context: context, controller: dtr, label: 'রিপোর্টের তারিখ ও সময়'),
                FormHelpers.textField(controller: gist, label: 'এফআইআর-এর সংক্ষিপ্ত ঘটনা', maxLines: 5),
              ],
            ),
          ),
          AppSectionCard(
            title: 'ধাপ ৩: সংশ্লিষ্ট পক্ষসমূহ',
            icon: Icons.people,
            child: Column(
              children: [
                FormHelpers.textField(controller: complainant, label: 'অভিযোগকারীর বিবরণ', maxLines: 2),
                FormHelpers.textField(controller: victim, label: 'ভিকটিমের বিবরণ', maxLines: 2),
                FormHelpers.textField(controller: accused, label: 'অভিযুক্ত/সন্দেহভাজনের বিবরণ', maxLines: 3),
              ],
            ),
          ),
          if (widget.existing != null)
            AppSectionCard(
              title: 'ধাপ ৪: তদন্তের সূচনা',
            subtitle: 'হ্যাঁ নির্বাচন করলে বিস্তারিত লেখার ঘর খুলবে। এই তথ্য থেকে সিডি-১-এর খসড়া স্বয়ংক্রিয়ভাবে তৈরি হবে।',
            icon: Icons.manage_search,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('তদন্তকারী অফিসার: ${widget.profile.rank} ${widget.profile.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FormHelpers.dateField(context: context, controller: tookUpDate, label: 'তদন্তভার গ্রহণের তারিখ'),
                FormHelpers.yesNoTile(title: 'ঘটনাস্থল পরিদর্শন করেছেন?', value: visitedPo, onChanged: (v) => setState(() => visitedPo = v)),
                if (visitedPo) FormHelpers.textField(controller: poDetails, label: 'ঘটনাস্থল পরিদর্শনের বিবরণ', maxLines: 4),
                FormHelpers.yesNoTile(title: 'খসড়া নকশা প্রস্তুত করেছেন?', value: sketchPrepared, onChanged: (v) => setState(() => sketchPrepared = v)),
                if (sketchPrepared) FormHelpers.textField(controller: sketchDetails, label: 'খসড়া নকশার বিবরণ', maxLines: 3),
                FormHelpers.yesNoTile(title: 'সাক্ষী পরীক্ষা করেছেন?', value: witnessExamined, onChanged: (v) => setState(() => witnessExamined = v)),
                if (witnessExamined) FormHelpers.textField(controller: witnessDetails, label: 'সাক্ষী পরীক্ষার বিবরণ', maxLines: 4),
                FormHelpers.yesNoTile(title: 'চিকিৎসা সংক্রান্ত ব্যবস্থা প্রয়োজন?', value: medicalRequired, onChanged: (v) => setState(() => medicalRequired = v)),
                if (medicalRequired) FormHelpers.textField(controller: medicalDetails, label: 'চিকিৎসা/বিএইচটি/আঘাতের বিবরণ', maxLines: 4),
                FormHelpers.yesNoTile(title: 'জব্দ প্রয়োজন?', value: seizureRequired, onChanged: (v) => setState(() => seizureRequired = v)),
                if (seizureRequired) FormHelpers.textField(controller: seizureDetails, label: 'জব্দের বিবরণ', maxLines: 4),
                FormHelpers.yesNoTile(title: 'প্রমাণ উপলব্ধ/সংগ্রহ প্রয়োজন?', value: evidenceRequired, onChanged: (v) => setState(() => evidenceRequired = v)),
                if (evidenceRequired) FormHelpers.textField(controller: evidenceDetails, label: 'প্রমাণের বিবরণ (ভৌত/ডিজিটাল/সিসিটিভি/নথি ইত্যাদি)', maxLines: 4),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
