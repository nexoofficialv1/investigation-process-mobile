import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/forms_generator_service.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../services/doc_export_service.dart';
import 'pdf_preview_screen.dart';
import '../widgets/form_helpers.dart';

class FormsScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const FormsScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> {
  final LocalStoreService _store = LocalStoreService();
  final FormsGeneratorService _generator = FormsGeneratorService();
  List<FormNotice> forms = [];
  List<CaseFile> _cases = [];
  late CaseFile _selectedCase;

  @override
  void initState() {
    super.initState();
    _selectedCase = widget.caseFile;
    _load();
  }

  Future<void> _load() async {
    final cases = await _store.loadCases();
    CaseFile selected = _selectedCase;
    if (cases.isNotEmpty) {
      selected = cases.firstWhere(
        (c) => c.id == _selectedCase.id,
        orElse: () => cases.first,
      );
    }
    final list = await _store.loadForms(selected.id);
    if (!mounted) return;
    setState(() {
      _cases = cases;
      _selectedCase = selected;
      forms = list;
    });
  }

  Future<void> _changeCase(CaseFile? file) async {
    if (file == null) return;
    setState(() => _selectedCase = file);
    final list = await _store.loadForms(file.id);
    if (!mounted) return;
    setState(() => forms = list);
  }

  Future<void> _create(FormTemplateInfo template) async {
    final body = _generator.generate(templateId: template.id, officer: widget.profile, caseFile: _selectedCase);
    final form = FormNotice.create(
      caseId: _selectedCase.id,
      templateId: template.id,
      title: template.title,
      body: body,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormEditorScreen(profile: widget.profile, caseFile: _selectedCase, form: form)),
    );
    await _load();
  }

  Future<void> _open(FormNotice form) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormEditorScreen(profile: widget.profile, caseFile: _selectedCase, form: form)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ফর্ম ও নোটিশ')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('স্বয়ংক্রিয়ভাবে পূরণযোগ্য ফর্ম', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('${_selectedCase.displayTitle}\nধারা: ${_selectedCase.sections}\nতদন্তকারী অফিসার: ${widget.profile.rank} ${widget.profile.name}'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedCase.id,
                      decoration: const InputDecoration(
                        labelText: 'এই ফর্মের জন্য মামলা নির্বাচন করুন',
                        helperText: 'নির্বাচিত মামলা অনুযায়ী ৩৫ ধারার নোটিশে অভিযুক্তের নাম এবং ৯৪ ধারার নোটিশে অভিযোগকারীর নাম স্বয়ংক্রিয়ভাবে বসবে।',
                      ),
                      items: _cases.isEmpty
                          ? [DropdownMenuItem(value: _selectedCase.id, child: Text(_selectedCase.displayTitle))]
                          : _cases.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.displayTitle} • ${c.caseDate}'))).toList(),
                      onChanged: (id) {
                        final found = _cases.where((c) => c.id == id).toList();
                        if (found.isNotEmpty) _changeCase(found.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('নতুন ফর্ম তৈরি করুন', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...FormsGeneratorService.templates.map((template) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.post_add),
                    title: Text(template.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${template.category} • ${template.subtitle}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _create(template),
                  ),
                )),
            const SizedBox(height: 18),
            Text('সংরক্ষিত ফর্মসমূহ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (forms.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('এখনও কোনো ফর্ম সংরক্ষিত নেই। উপরের একটি টেমপ্লেট নির্বাচন করুন।')))
            else
              ...forms.map((form) => Card(
                    child: ListTile(
                      leading: Icon(form.isFinal ? Icons.lock : Icons.description),
                      title: Text(form.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(form.isFinal ? 'চূড়ান্তভাবে সংরক্ষিত' : 'খসড়া'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(form),
                    ),
                  )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class FormEditorScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;
  final FormNotice form;

  const FormEditorScreen({super.key, required this.profile, required this.caseFile, required this.form});

  @override
  State<FormEditorScreen> createState() => _FormEditorScreenState();
}

class _FormEditorScreenState extends State<FormEditorScreen> {
  final LocalStoreService _store = LocalStoreService();
  late FormNotice _form;
  late final TextEditingController title;
  late final TextEditingController body;
  final Map<String, TextEditingController> _structured = {};
  final List<Map<String, TextEditingController>> _fslExhibits = [];
  final List<Map<String, TextEditingController>> _fslCustodyPersons = [];

  bool get _isCdrCaf => _form.templateId == 'cdr_caf';
  bool get _isFsl => _form.templateId == 'fsl';

  @override
  void initState() {
    super.initState();
    _form = widget.form;
    title = TextEditingController(text: _form.title);
    body = TextEditingController(text: _form.body);
    _initStructuredControllers();
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    for (final controller in _structured.values) {
      controller.dispose();
    }
    for (final row in _fslExhibits) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }
    for (final row in _fslCustodyPersons) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  String _readLineValue(String key, {String fallback = ''}) {
    final pattern = RegExp('^' + RegExp.escape(key) + r'\s*:\s*(.*)$', multiLine: true, caseSensitive: false);
    final match = pattern.firstMatch(_form.body);
    if (match == null) return fallback;
    final value = (match.group(1) ?? '').trim();
    return value.isEmpty ? fallback : value;
  }


  List<List<String>> _parsePipeLines(String raw, int expectedColumns) {
    final rows = <List<String>>[];
    for (final line in raw.split('\n')) {
      final clean = line.trim();
      if (clean.isEmpty) continue;
      final parts = clean.split('|').map((e) => e.trim()).toList();
      while (parts.length < expectedColumns) {
        parts.add('');
      }
      rows.add(parts.take(expectedColumns).toList());
    }
    return rows;
  }

  Map<String, TextEditingController> _controllerRow(List<String> keys, List<String> values) {
    final map = <String, TextEditingController>{};
    for (var i = 0; i < keys.length; i++) {
      map[keys[i]] = TextEditingController(text: i < values.length ? values[i] : '');
    }
    return map;
  }

  void _addFslExhibit({List<String>? values}) {
    setState(() {
      _fslExhibits.add(_controllerRow(
        ['চিহ্ন', 'বিবরণ', 'কীভাবে/কখন/কার দ্বারা পাওয়া', 'আলামতের মালিকানা', 'মন্তব্য'],
        values ?? ['', '', '', '', ''],
      ));
    });
  }

  void _addFslCustodyPerson({List<String>? values}) {
    setState(() {
      _fslCustodyPersons.add(_controllerRow(
        ['পূর্ণ নাম', 'পেশা', 'বয়স', 'লিঙ্গ', 'গ্রেপ্তারের তারিখ ও সময়', 'জামিন/হেফাজতের অবস্থা', 'আদালত'],
        values ?? ['', '', '', '', '', '', ''],
      ));
    });
  }

  void _initFslRepeatingRows() {
    final exhibitsRaw = _structured['আলামতসমূহ']?.text ?? '';
    final custodyRaw = _structured['হেফাজতে থাকা ব্যক্তিবর্গ']?.text ?? '';
    final exhibitRows = _parsePipeLines(exhibitsRaw, 5);
    final custodyRows = _parsePipeLines(custodyRaw, 7);
    _fslExhibits.clear();
    _fslCustodyPersons.clear();
    if (exhibitRows.isEmpty) {
      _fslExhibits.add(_controllerRow(
        ['চিহ্ন', 'বিবরণ', 'কীভাবে/কখন/কার দ্বারা পাওয়া', 'আলামতের মালিকানা', 'মন্তব্য'],
        ['ক', 'একটি সিলমোহরযুক্ত প্যাকেট/জার/পাত্র, যার মধ্যে ________________________________ আছে বলে উল্লেখ।', '__________ তারিখে ________________________________ স্থান থেকে ${widget.profile.rank} ${widget.profile.name} কর্তৃক জব্দ।', 'বিজ্ঞ সিজেএম/ম্যাজিস্ট্রেট, ${widget.profile.district}', 'পরীক্ষার পরে রাষ্ট্রের অনুকূলে বাজেয়াপ্ত/ফেরতযোগ্য'],
      ));
    } else {
      for (final row in exhibitRows) {
        _fslExhibits.add(_controllerRow(['চিহ্ন', 'বিবরণ', 'কীভাবে/কখন/কার দ্বারা পাওয়া', 'আলামতের মালিকানা', 'মন্তব্য'], row));
      }
    }
    if (custodyRows.isEmpty) {
      _fslCustodyPersons.add(_controllerRow(
        ['পূর্ণ নাম', 'পেশা', 'বয়স', 'লিঙ্গ', 'গ্রেপ্তারের তারিখ ও সময়', 'জামিন/হেফাজতের অবস্থা', 'আদালত'],
        [widget.caseFile.accusedName.trim().isEmpty ? 'অভিযুক্তের নাম ও ঠিকানা' : widget.caseFile.accusedName, '', '', '', '', 'বিচারবিভাগীয় হেফাজত / পুলিশ হেফাজত / জামিন / পলাতক', 'বিজ্ঞ আদালত'],
      ));
    } else {
      for (final row in custodyRows) {
        _fslCustodyPersons.add(_controllerRow(['পূর্ণ নাম', 'পেশা', 'বয়স', 'লিঙ্গ', 'গ্রেপ্তারের তারিখ ও সময়', 'জামিন/হেফাজতের অবস্থা', 'আদালত'], row));
      }
    }
  }

  String _joinRows(List<Map<String, TextEditingController>> rows, List<String> keys) {
    return rows.map((row) => keys.map((key) => row[key]?.text.trim() ?? '').join(' | ')).join('\n');
  }

  void _syncFslRepeatingRowsToStructured() {
    if (!_isFsl) return;
    _structured['আলামতসমূহ']?.text = _joinRows(_fslExhibits, ['চিহ্ন', 'বিবরণ', 'কীভাবে/কখন/কার দ্বারা পাওয়া', 'আলামতের মালিকানা', 'মন্তব্য']);
    _structured['হেফাজতে থাকা ব্যক্তিবর্গ']?.text = _joinRows(_fslCustodyPersons, ['পূর্ণ নাম', 'পেশা', 'বয়স', 'লিঙ্গ', 'গ্রেপ্তারের তারিখ ও সময়', 'জামিন/হেফাজতের অবস্থা', 'আদালত']);
  }

  void _initStructuredControllers() {
    if (_isCdrCaf) {
      final defaults = <String, String>{
        'মামলার রেফারেন্স': '${widget.profile.policeStation} মামলা নং-${widget.caseFile.psCaseNo}, তারিখ-${widget.caseFile.caseDate}, ধারা-${widget.caseFile.sections}',
        'সংক্ষিপ্ত ঘটনা': widget.caseFile.firGist,
        'প্রয়োজনীয় মোবাইল/আইএমইআই': '',
        'প্রকৃত ব্যবহারকারী/সংশ্লিষ্টতা': 'সন্দেহভাজন কর্তৃক ব্যবহৃত',
        'প্রয়োজনীয়তার যুক্তি': '',
        'সিডিআর-এর সময়সীমা': '____________ থেকে ____________ পর্যন্ত',
        'এসডিআর প্রয়োজন': 'হ্যাঁ',
        'সিএএফ প্রয়োজন': 'হ্যাঁ',
        'আইএমইআই অনুসন্ধানের সময়সীমা': '---',
        'তদন্তকারী অফিসারের নাম': '${widget.profile.rank} ${widget.profile.name}',
        'তদন্তকারী অফিসারের ফোন': widget.profile.mobile,
        'অন্যান্য বিষয়': 'প্রযোজ্য নয়',
      };
      for (final entry in defaults.entries) {
        _structured[entry.key] = TextEditingController(text: _readLineValue(entry.key, fallback: entry.value));
      }
      _applyStructuredToBody(showMessage: false);
    } else if (_isFsl) {
      final defaults = <String, String>{
        'অপরাধের প্রকৃতি': widget.caseFile.firGist,
        'আলামতসমূহ': 'ক | উপরোক্ত মামলার সূত্রে একটি সিলমোহরযুক্ত প্যাকেট/জার/পাত্র, যার মধ্যে ________________________________ আছে বলে উল্লেখ | __________ তারিখে ________________________________ স্থান থেকে ${widget.profile.rank} ${widget.profile.name} কর্তৃক জব্দ/________________ থেকে প্রাপ্ত | মাননীয় সিজেএম/ম্যাজিস্ট্রেট, ${widget.profile.district} | পরীক্ষার পরে রাষ্ট্রের অনুকূলে বাজেয়াপ্ত/ফেরতযোগ্য',
        'প্রয়োজনীয় পরীক্ষার প্রকৃতি': '১) আলামত চিহ্ন “ক”-তে বিষ/রক্ত/বীর্য/জৈব পদার্থ/রাসায়নিক/বিস্ফোরক/মাদক/ডিজিটাল চিহ্ন বা অন্য কোনো প্রাসঙ্গিক উপাদান শনাক্ত করা যায় কি না।\n২) শনাক্ত হলে উক্ত উপাদানের প্রকৃতি/ধরন/উৎস এবং মামলার ঘটনার সঙ্গে তার প্রাসঙ্গিকতা কী।\n৩) পরীক্ষাকালে উদ্ভূত অন্য কোনো প্রাসঙ্গিক বিষয়।',
        'হেফাজতে থাকা ব্যক্তিবর্গ': '${widget.caseFile.accusedName.trim().isEmpty ? 'অভিযুক্তের নাম ও ঠিকানা' : widget.caseFile.accusedName} | পেশা | বয়স | লিঙ্গ | গ্রেপ্তারের তারিখ ও সময় | বিচারবিভাগীয় হেফাজত/পুলিশ হেফাজত/জামিন/পলাতক | মাননীয় আদালত',
        'এফএসএল কার্যালয়': 'দপ্তর প্রধান ও সহকারী পরিচালক\nআঞ্চলিক ফরেনসিক বিজ্ঞানাগার\nশংকরপুর, দুর্গাপুর\nপশ্চিম বর্ধমান, ৭১৩২১২',
        'আদালত': 'বিজ্ঞ সিজেএম/ম্যাজিস্ট্রেট, ${widget.profile.district}',
        'তদন্তকারী অফিসার/থানার যোগাযোগের বিবরণ': 'তদন্তকারী অফিসারের নাম:- ${widget.profile.name}\nপদমর্যাদা:- ${widget.profile.rank}\nতদন্তকারী অফিসারের মোবাইল নং:- ${widget.profile.mobile}\nথানার নাম:- ${widget.profile.policeStation}\nজেলা:- ${widget.profile.district}\nথানার ঠিকানা:- ________________________________\nপিন কোড:- ________________________________\nহোয়াটসঅ্যাপ নং:- ${widget.profile.mobile}\nহাসপাতাল/মর্গ:- ________________________________\nবার্তাবাহকের নাম ও ফোন:- ________________________________',
      };
      for (final entry in defaults.entries) {
        _structured[entry.key] = TextEditingController(text: _readLineValue(entry.key, fallback: entry.value));
      }
      _initFslRepeatingRows();
      _applyStructuredToBody(showMessage: false);
    }
  }

  void _applyStructuredToBody({bool showMessage = true}) {
    if (!_isCdrCaf && !_isFsl) return;
    if (_isFsl) _syncFslRepeatingRowsToStructured();
    final buffer = StringBuffer();
    buffer.writeln(_isCdrCaf ? 'সিডিআর/এসডিআর/সিএএফ-এর কাঠামোবদ্ধ এন্ট্রি' : 'এফএসএল প্যাকেজের কাঠামোবদ্ধ এন্ট্রি');
    buffer.writeln();
    for (final entry in _structured.entries) {
      buffer.writeln('${entry.key}: ${entry.value.text.trim()}');
    }
    buffer.writeln();
    buffer.writeln(_isCdrCaf
        ? 'Note: Fill the above entry fields. Preview will render the official table format.'
        : 'Note: Fill the above entry fields. Preview will generate Form 5203 + Exhibit List + Examination Required + Custody + Magistrate forwarding/certification + Challan + Labels.');
    body.text = buffer.toString();
    if (showMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Structured entry applied. Now preview/export.')));
    }
  }


  Widget _entryText(String key, {int maxLines = 1, String? helperText}) {
    final controller = _structured[key];
    if (controller == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: key, helperText: helperText, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _fslExhibitEntryCard(int index, Map<String, TextEditingController> row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Exhibit ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                if (_fslExhibits.length > 1)
                  IconButton(
                    onPressed: () => setState(() {
                      for (final c in row.values) { c.dispose(); }
                      _fslExhibits.removeAt(index);
                    }),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            TextField(controller: row['চিহ্ন'], decoration: const InputDecoration(labelText: 'Label / Exhibit Mark, e.g. A', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: row['বিবরণ'], maxLines: 3, decoration: const InputDecoration(labelText: 'Description of the exhibit', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: row['কীভাবে/কখন/কার দ্বারা পাওয়া'], maxLines: 3, decoration: const InputDecoration(labelText: 'How and when found and by whom', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: row['আলামতের মালিকানা'], maxLines: 2, decoration: const InputDecoration(labelText: 'Ownership of exhibit', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: row['মন্তব্য'], maxLines: 2, decoration: const InputDecoration(labelText: 'Remarks — editable', border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }

  Widget _fslCustodyEntryCard(int index, Map<String, TextEditingController> row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Person in Custody ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                if (_fslCustodyPersons.length > 1)
                  IconButton(
                    onPressed: () => setState(() {
                      for (final c in row.values) { c.dispose(); }
                      _fslCustodyPersons.removeAt(index);
                    }),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            TextField(controller: row['পূর্ণ নাম'], maxLines: 2, decoration: const InputDecoration(labelText: 'পূর্ণ নাম', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: row['পেশা'], decoration: const InputDecoration(labelText: 'পেশা', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: row['বয়স'], decoration: const InputDecoration(labelText: 'বয়স', border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: (row['লিঙ্গ']?.text.trim().isEmpty ?? true) ? null : row['লিঙ্গ']!.text.trim(),
                decoration: const InputDecoration(labelText: 'লিঙ্গ', border: OutlineInputBorder()),
                items: const ['Male', 'Female', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => row['লিঙ্গ']?.text = v ?? '',
              )),
              const SizedBox(width: 8),
              Expanded(child: FormHelpers.dateTimeField(context: context, controller: row['গ্রেপ্তারের তারিখ ও সময়']!, label: 'গ্রেপ্তারের তারিখ ও সময়')),
            ]),
            const SizedBox(height: 8),
            TextField(controller: row['জামিন/হেফাজতের অবস্থা'], decoration: const InputDecoration(labelText: 'Whether on bail or in custody', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: row['আদালত'], decoration: const InputDecoration(labelText: 'আদালত', border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }

  Widget _fslSimpleEntryModule() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FSL Form Fill Up — Step by Step Entry', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Pre-fill data already বসানো আছে। প্রতিটা point ধরে entry করুন। Preview করলে official Form 5203, Exhibit List, Nature of Examination, Particulars of Person in Custody, Certificate, Challan ও Label আলাদা page/section-এ তৈরি হবে।'),
            const SizedBox(height: 12),
            _entryText('অপরাধের প্রকৃতি', maxLines: 6),
            _entryText('প্রয়োজনীয় পরীক্ষার প্রকৃতি', maxLines: 5),
            _entryText('এফএসএল কার্যালয়', maxLines: 4),
            _entryText('আদালত', maxLines: 1),
            const Divider(height: 24),
            Row(children: [
              const Expanded(child: Text('II. List of Exhibits Sent for Examination', style: TextStyle(fontWeight: FontWeight.bold))),
              FilledButton.icon(onPressed: () => _addFslExhibit(), icon: const Icon(Icons.add), label: const Text('Add Exhibit')),
            ]),
            const SizedBox(height: 8),
            ..._fslExhibits.asMap().entries.map((entry) => _fslExhibitEntryCard(entry.key, entry.value)),
            const Divider(height: 24),
            Row(children: [
              const Expanded(child: Text('IV. Particulars of Persons in Custody', style: TextStyle(fontWeight: FontWeight.bold))),
              FilledButton.icon(onPressed: () => _addFslCustodyPerson(), icon: const Icon(Icons.add), label: const Text('Add Person')),
            ]),
            const SizedBox(height: 8),
            ..._fslCustodyPersons.asMap().entries.map((entry) => _fslCustodyEntryCard(entry.key, entry.value)),
            const Divider(height: 24),
            _entryText('তদন্তকারী অফিসার/থানার যোগাযোগের বিবরণ', maxLines: 6),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _applyStructuredToBody(),
                icon: const Icon(Icons.check),
                label: const Text('Apply to Form Draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _structuredEntryModule() {
    if (_isFsl) return _fslSimpleEntryModule();
    if (!_isCdrCaf && !_isFsl) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isCdrCaf ? 'CDR / SDR / CAF Entry Module' : 'FSL Form + Challan + Label Entry Module', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_isFsl
                ? 'Exhibit একাধিক হলে EXHIBITS field-এ প্রত্যেক exhibit আলাদা line-এ লিখুন: Mark | Description | How/when found | Ownership | Remarks. Accused একাধিক হলে PERSONS IN CUSTODY field-এ প্রত্যেক accused আলাদা line-এ লিখুন: Name | Occupation | Age | Sex | Arrest date/time | Bail/Custody | Court. Preview official page-wise format-এ হবে।'
                : 'নিচের field গুলো fill/edit করুন। Preview চাপলে official form layout-এ দেখা যাবে।'),
            const SizedBox(height: 12),
            ..._structured.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: entry.value,
                    maxLines: entry.key == 'সংক্ষিপ্ত ঘটনা' || entry.key == 'অপরাধের প্রকৃতি' || entry.key == 'প্রয়োজনীয় পরীক্ষার প্রকৃতি' || entry.key == 'এফএসএল কার্যালয়' || entry.key == 'আলামতসমূহ' || entry.key == 'হেফাজতে থাকা ব্যক্তিবর্গ' || entry.key == 'তদন্তকারী অফিসার/থানার যোগাযোগের বিবরণ' ? 5 : 1,
                    decoration: InputDecoration(labelText: entry.key, border: const OutlineInputBorder()),
                  ),
                )),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _applyStructuredToBody(),
                icon: const Icon(Icons.check),
                label: const Text('Apply to Form Draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  FormNotice _currentForm({bool? finalSave}) {
    if (_isCdrCaf || _isFsl) {
      _applyStructuredToBody(showMessage: false);
    }
    return _form.copyWith(
      title: title.text.trim(),
      body: body.text.trim(),
      isFinal: finalSave == true ? true : _form.isFinal,
    );
  }

  Future<FormNotice> _save({bool finalSave = false, bool askCdMention = true}) async {
    final updated = _currentForm(finalSave: finalSave);
    await _store.saveForm(updated);
    if (!mounted) return updated;
    setState(() => _form = updated);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(finalSave ? 'Form final saved' : 'Form draft saved')));
    if (askCdMention) await _askMentionInCaseDiary(updated);
    return updated;
  }

  String _today() => DateTime.now().toIso8601String().split('T').first;

  String _cdParagraphForForm(FormNotice form) {
    final lower = form.title.toLowerCase();
    if (lower.contains('183')) {
      return 'এই মামলার সূত্রে বিএনএসএস-এর ১৮৩ ধারায় বিবৃতি লিপিবদ্ধ করার জন্য বিজ্ঞ আদালতের নিকট প্রার্থনা পেশ করলাম।';
    }
    if (lower.contains('35')) {
      return 'এই মামলার সূত্রে সংশ্লিষ্ট ব্যক্তির প্রতি বিএনএসএস-এর ৩৫(৩) ধারার নোটিশ প্রস্তুত/তামিল করলাম।';
    }
    if (lower.contains('94')) {
      return 'এই মামলার সূত্রে প্রাসঙ্গিক নথি/বস্তু সংগ্রহ/উপস্থাপনের জন্য বিএনএসএস-এর ৯৪ ধারার রিকুইজিশন প্রেরণ করলাম।';
    }
    if (lower.contains('medical')) {
      return 'এই মামলার সূত্রে চিকিৎসা পরীক্ষা/চিকিৎসা সংক্রান্ত নথি সংগ্রহের জন্য রিকুইজিশন প্রেরণ করলাম।';
    }
    if (lower.contains('bht') || lower.contains('injury')) {
      return 'এই মামলার সূত্রে বিএইচটি/আঘাতের প্রতিবেদন সংগ্রহের জন্য রিকুইজিশন প্রেরণ করলাম।';
    }
    if (lower.contains('cdr') || lower.contains('caf')) {
      return 'এই মামলার সূত্রে সিডিআর/সিএএফ সংগ্রহের জন্য রিকুইজিশন প্রেরণ করলাম।';
    }
    if (lower.contains('bank')) {
      return 'এই মামলার সূত্রে হিসাব/লেনদেনের তথ্য সংগ্রহের জন্য সংশ্লিষ্ট ব্যাংক/কর্তৃপক্ষের নিকট রিকুইজিশন প্রেরণ করলাম।';
    }
    if (lower.contains('fsl')) {
      return 'এই মামলার সূত্রে এফএসএল/বৈজ্ঞানিক পরীক্ষার জন্য রিকুইজিশন প্রেরণ করলাম।';
    }
    if (lower.contains('forwarding')) {
      return 'এই মামলার সূত্রে ফরওয়ার্ডিং প্রতিবেদন/প্রার্থনা প্রস্তুত করলাম।';
    }
    return 'এই মামলার সূত্রে ${form.title} প্রস্তুত করলাম।';
  }

  Future<void> _askMentionInCaseDiary(FormNotice form) async {
    if (!mounted) return;
    final mention = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('কেস ডায়েরিতে উল্লেখ করবেন?'),
        content: Text('“${form.title}” কেস ডায়েরিতে উল্লেখ করা হবে? হ্যাঁ করলে তারিখভিত্তিক অপেক্ষমাণ সিডি এন্ট্রি হিসেবে সংরক্ষিত হবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('হ্যাঁ')),
        ],
      ),
    );
    if (mention != true) return;

    final action = PendingCdAction.create(
      caseId: widget.caseFile.id,
      sourceType: 'form_notice',
      sourceId: form.id,
      title: form.title,
      actionDate: _today(),
      paragraph: _cdParagraphForForm(form),
    );
    await _store.savePendingCdAction(action);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কেস ডায়েরির অপেক্ষমাণ এন্ট্রি সংরক্ষিত হয়েছে। দৈনিক সিডি নির্মাতায় দেখা যাবে।')));
  }

  Future<void> _previewPdf() async {
    final previewForm = await _save(askCdMention: false);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: '${previewForm.title} প্রিভিউ',
          filename: '${previewForm.title.replaceAll(' ', '_')}_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.pdf',
          docFilename: '${previewForm.title.replaceAll(' ', '_')}_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.doc',
          buildPdf: () => PdfService().buildFormNoticePdf(officer: widget.profile, caseFile: widget.caseFile, form: previewForm),
          buildDoc: () => DocExportService().buildFormNoticeDoc(officer: widget.profile, caseFile: widget.caseFile, form: previewForm),
          onFinalSave: () async {
            final saved = await _save(finalSave: true, askCdMention: false);
            await _askMentionInCaseDiary(saved);
          },
        ),
      ),
    );
  }

  Future<void> _finalSave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Final Save Form?'),
        content: const Text('Final save করলে form locked হিসেবে mark হবে। পরে edit করা যাবে, কিন্তু warning দেখাবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Final Save')),
        ],
      ),
    );
    if (ok == true) await _save(finalSave: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_form.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save), label: const Text('খসড়া'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _finalSave, icon: const Icon(Icons.lock), label: const Text('Final'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _previewPdf, icon: const Icon(Icons.preview), label: const Text('প্রিভিউ'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_form.isFinal)
            const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('This form is final saved. Edit carefully if required.', style: TextStyle(fontWeight: FontWeight.bold)))),
          _structuredEntryModule(),
          const SizedBox(height: 10),
          FormHelpers.textField(controller: title, label: 'Form Title'),
          TextField(
            controller: body,
            maxLines: 28,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              labelText: 'Auto-filled form body — edit as required',
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
