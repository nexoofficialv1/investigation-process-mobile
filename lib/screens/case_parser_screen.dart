import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/case_parser_service.dart';
import '../services/local_store_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/form_helpers.dart';

class CaseParserScreen extends StatefulWidget {
  final OfficerProfile profile;
  const CaseParserScreen({super.key, required this.profile});

  @override
  State<CaseParserScreen> createState() => _CaseParserScreenState();
}

class _CaseParserScreenState extends State<CaseParserScreen> {
  final _store = LocalStoreService();
  final _parser = CaseParserService();
  final rawText = TextEditingController();

  final psCaseNo = TextEditingController();
  final caseDate = TextEditingController();
  final sections = TextEditingController();
  final po = TextEditingController();
  final dO = TextEditingController();
  final dR = TextEditingController();
  final complainant = TextEditingController();
  final victim = TextEditingController();
  final accused = TextEditingController();
  final io = TextEditingController();
  final ioMobile = TextEditingController();
  final gist = TextEditingController();
  final arrest = TextEditingController();

  List<CaseFile> _cases = [];
  CaseFile? _selectedCase;
  bool _parsed = false;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    final cases = await _store.loadCases();
    if (!mounted) return;
    setState(() => _cases = cases);
  }

  @override
  void dispose() {
    for (final c in [rawText, psCaseNo, caseDate, sections, po, dO, dR, complainant, victim, accused, io, ioMobile, gist, arrest]) {
      c.dispose();
    }
    super.dispose();
  }

  void _parse() {
    final result = _parser.parse(rawText.text);
    setState(() {
      psCaseNo.text = result.psCaseNo;
      caseDate.text = result.caseDate;
      sections.text = result.sections;
      po.text = result.placeOfOccurrence;
      dO.text = result.dateTimeOccurrence;
      dR.text = result.dateTimeReporting;
      complainant.text = result.complainant;
      victim.text = result.victim;
      accused.text = result.accused;
      io.text = result.ioName;
      ioMobile.text = result.ioMobile;
      gist.text = result.gist;
      arrest.text = result.arrest;
      _parsed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data extracted. Review/edit before saving.')));
  }

  ParsedCaseData _currentParsed() => ParsedCaseData(
        psCaseNo: psCaseNo.text.trim(),
        caseDate: caseDate.text.trim(),
        sections: sections.text.trim(),
        placeOfOccurrence: po.text.trim(),
        dateTimeOccurrence: dO.text.trim(),
        dateTimeReporting: dR.text.trim(),
        complainant: complainant.text.trim(),
        victim: victim.text.trim(),
        accused: accused.text.trim(),
        ioName: io.text.trim(),
        ioMobile: ioMobile.text.trim(),
        gist: gist.text.trim(),
        arrest: arrest.text.trim(),
        rawText: rawText.text,
      );

  Future<void> _saveNewCase() async {
    if (!_parsed) _parse();
    final file = _currentParsed().toCaseFile(widget.profile);
    if (file.psCaseNo.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PS Case No. missing. Fill it before saving.')));
      return;
    }
    await _store.saveCase(file);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parsed data saved as new case')));
    Navigator.pop(context);
  }

  Future<void> _updateSelectedCase() async {
    final selected = _selectedCase;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update করার জন্য আগে existing case select করুন।')));
      return;
    }
    if (!_parsed) _parse();
    final file = _currentParsed().toCaseFile(widget.profile, existing: selected);
    await _store.saveCase(file);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected case updated from parsed data')));
    Navigator.pop(context);
  }

  void _showCameraNote() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scan Document / Camera OCR'),
        content: const Text('এই version-এ Text Parser ready. Camera দিয়ে complaint/FIR/report scan করে OCR extraction next online/OCR patch-এ add হবে। এখন document text copy/paste করে Parse করুন।'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ঠিক আছে'))],
      ),
    );
  }

  void _showUseOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Parsed data দিয়ে কী করবেন?', style: TextStyle(fontWeight: FontWeight.w900))),
            ListTile(leading: const Icon(Icons.add_box), title: const Text('Create New Case'), onTap: () { Navigator.pop(context); _saveNewCase(); }),
            ListTile(leading: const Icon(Icons.folder_open), title: const Text('Update Selected Case'), onTap: () { Navigator.pop(context); _updateSelectedCase(); }),
            const ListTile(leading: Icon(Icons.menu_book), title: Text('Create CD Entry'), subtitle: Text('Next patch: parsed text থেকে CD entry বানাবে')),
            const ListTile(leading: Icon(Icons.description), title: Text('Create Form / Notice'), subtitle: Text('Next patch: selected case/form auto-fill')),
            const ListTile(leading: Icon(Icons.inventory_2), title: Text('Save as Evidence / Document'), subtitle: Text('Next patch: case document manager')),
          ],
        ),
      ),
    );
  }

  void _fillDemo() {
    rawText.text = '''Ref: Kalna P.S. Case No- 558/26 Dated 08.07.26 U/S- 126(2)/115(2)/76/3(5) BNS.

P.O: Dharmadanga PS Kalna Dist Purba Bardhaman (Hatkalna GP).

D.O: On 07.07.2026 at about 13:30 Hrs.

D.R:  08.07.2026 at 13.25 hrs.

Complt: Aparna Sarkar Kharati W/o Asim Kharati of Dharmadanga PS Kalna Dist Purba Bardhaman (Mob- 81011111657).

FIR Named Accd-01 & others(1. Sargam Biswas S/o Lt. Samir Biswas of Dharmadanga PS Kalna Dist Purba Bardhaman and others)

I.O: ASI Sukanta Chakraborty (7001786060)

Gist: - On 08.07.2026 at 13:25 hrs, a written complaint was received from one Aparna Sarkar Kharati, W/o Asim Kharati of Dharmadanga, P.S. Kalna, Dist. Purba Bardhaman, to the effect that on 07.07.2026 at about 13:30 hrs, some young boys created a disturbance over an issue. Subsequently, at about 22:10 hrs, one Sargam Biswas, along with others, assaulted the complainant and her husband and also tore the wearing apparel of the complainant. On the basis of such complaint initiated this instant case. Investigation is proceeding.

Arrest: NIL.''';
    _parse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('মামলা তথ্য বিশ্লেষক')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: _showUseOptions, icon: const Icon(Icons.rule), label: const Text('তথ্য ব্যবহার করুন'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: _parse, icon: const Icon(Icons.auto_fix_high), label: const Text('বিশ্লেষণ করুন'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSectionCard(
            title: 'মামলার লেখা পেস্ট/স্ক্যান করুন',
            subtitle: 'রেফারেন্স, ঘটনাস্থল, ঘটনার তারিখ, রিপোর্টের তারিখ, অভিযোগকারী, অভিযুক্ত, তদন্তকারী অফিসার, সংক্ষিপ্ত ঘটনা ও গ্রেপ্তার সংক্রান্ত বিন্যাস শনাক্ত করবে।',
            icon: Icons.document_scanner,
            child: Column(
              children: [
                FormHelpers.textField(controller: rawText, label: 'এখানে অভিযোগ/এফআইআর/আদেশ/প্রতিবেদনের লেখা পেস্ট করুন', maxLines: 10),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: _fillDemo, icon: const Icon(Icons.text_snippet), label: const Text('ডেমো'))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(onPressed: _showCameraNote, icon: const Icon(Icons.camera_alt), label: const Text('নথি স্ক্যান করুন'))),
                  ],
                ),
              ],
            ),
          ),
          AppSectionCard(
            title: 'সংগৃহীত তথ্য যাচাই করুন',
            subtitle: 'সরাসরি সংরক্ষণ হবে না। আগে তদন্তকারী অফিসার যাচাই/সম্পাদনা করবেন, তারপর সংরক্ষণ/হালনাগাদ করবেন।',
            icon: Icons.fact_check,
            child: Column(
              children: [
                if (_cases.isNotEmpty)
                  DropdownButtonFormField<CaseFile>(
                    value: _selectedCase,
                    items: _cases.map((c) => DropdownMenuItem(value: c, child: Text(c.displayTitle, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _selectedCase = v),
                    decoration: const InputDecoration(labelText: 'বর্তমান মামলা হালনাগাদ (ঐচ্ছিক)', border: OutlineInputBorder()),
                  ),
                if (_cases.isNotEmpty) const SizedBox(height: 12),
                FormHelpers.textField(controller: psCaseNo, label: 'থানা মামলা নং'),
                FormHelpers.textField(controller: caseDate, label: 'মামলার তারিখ'),
                FormHelpers.textField(controller: sections, label: 'ধারা'),
                FormHelpers.textField(controller: po, label: 'ঘটনাস্থল', maxLines: 2),
                FormHelpers.textField(controller: dO, label: 'ঘটনার তারিখ ও সময়'),
                FormHelpers.textField(controller: dR, label: 'রিপোর্টের তারিখ ও সময়'),
                FormHelpers.textField(controller: complainant, label: 'অভিযোগকারী/সংবাদদাতা', maxLines: 3),
                FormHelpers.textField(controller: victim, label: 'ভিকটিম', maxLines: 2),
                FormHelpers.textField(controller: accused, label: 'এফআইআরে নামীয় অভিযুক্ত', maxLines: 4),
                Row(
                  children: [
                    Expanded(child: FormHelpers.textField(controller: io, label: 'তদন্তকারী অফিসারের নাম')),
                    const SizedBox(width: 10),
                    Expanded(child: FormHelpers.textField(controller: ioMobile, label: 'তদন্তকারী অফিসারের মোবাইল')),
                  ],
                ),
                FormHelpers.textField(controller: gist, label: 'সংক্ষিপ্ত ঘটনা', maxLines: 6),
                FormHelpers.textField(controller: arrest, label: 'গ্রেপ্তারের অবস্থা'),
                const SizedBox(height: 8),
                const Text('সংরক্ষণের পরে এই তথ্য মামলা এন্ট্রি, সিডি-১, ফর্ম, বিবৃতি, চূড়ান্ত সিডি ও আইএফ-৫-এ স্বয়ংক্রিয়ভাবে বসবে।', style: TextStyle(color: AppTheme.deepGreen, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
