import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/investigation_action.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/bengali_translation_service.dart';
import '../services/local_store_service.dart';
import '../services/sop_compliance_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/form_helpers.dart';

class InvestigationScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const InvestigationScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<InvestigationScreen> createState() => _InvestigationScreenState();
}

class _InvestigationScreenState extends State<InvestigationScreen> {
  final LocalStoreService _store = LocalStoreService();
  final SopComplianceService _sop = SopComplianceService();
  final _date = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
  final _departureTime = TextEditingController();
  final _arrivalTime = TextEditingController();
  final _returnTime = TextEditingController();
  final _place = TextEditingController();
  final _accompaniedBy = TextEditingController();
  final _details = TextEditingController();
  final _personName = TextEditingController();
  final _repeatReason = TextEditingController();
  final _sopResponse = TextEditingController();

  String _actionType = 'PO Visit / Local Enquiry';
  bool _outsidePs = true;
  bool _arrestInvolved = false;
  bool _seizureInvolved = false;
  bool _courtForwardingSuggested = false;
  bool _pcPrayerSuggested = false;
  List<InvestigationActionEntry> _history = [];

  final List<String> _actions = const [
    'PO Visit / Local Enquiry',
    'Rough Sketch Map Preparation',
    'Raid',
    'Accused Search',
    'Arrest / Apprehension',
    'Witness Examination',
    'Complainant Examination',
    'Victim Examination',
    'Hospital / Medical Work',
    'Court Work / Prayer',
    'Report / Document Collection',
    'Notice Service',
    'General Investigation Note',
  ];

  String _actionLabel(String value) => const <String, String>{
        'PO Visit / Local Enquiry': 'ঘটনাস্থল পরিদর্শন / স্থানীয় অনুসন্ধান',
        'Rough Sketch Map Preparation': 'ঘটনাস্থলের খসড়া নকশা প্রস্তুত',
        'Raid': 'অভিযান',
        'Accused Search': 'অভিযুক্তের অনুসন্ধান',
        'Arrest / Apprehension': 'গ্রেপ্তার / আটক',
        'Witness Examination': 'সাক্ষী জিজ্ঞাসাবাদ',
        'Complainant Examination': 'অভিযোগকারী জিজ্ঞাসাবাদ',
        'Victim Examination': 'ভুক্তভোগী জিজ্ঞাসাবাদ',
        'Hospital / Medical Work': 'হাসপাতাল / চিকিৎসা সংক্রান্ত কাজ',
        'Court Work / Prayer': 'আদালতের কাজ / প্রার্থনা',
        'Report / Document Collection': 'প্রতিবেদন / নথি সংগ্রহ',
        'Notice Service': 'নোটিশ তামিল',
        'General Investigation Note': 'সাধারণ তদন্ত নোট',
      }[value] ?? value;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _place.text = widget.caseFile.placeOfOccurrence;
  }

  Future<void> _loadHistory() async {
    final entries = await _store.loadInvestigationActions(widget.caseFile.id);
    if (!mounted) return;
    setState(() => _history = entries);
  }

  @override
  void dispose() {
    for (final c in [_date, _departureTime, _arrivalTime, _returnTime, _place, _accompaniedBy, _details, _personName, _repeatReason, _sopResponse]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isFieldAction {
    final t = _actionType.toLowerCase();
    return _outsidePs || t.contains('po') || t.contains('raid') || t.contains('search') || t.contains('hospital') || t.contains('court') || t.contains('notice');
  }

  String get _currentStepKey {
    final t = _actionType.toLowerCase();
    if (t.contains('po')) return 'po_visit';
    if (t.contains('sketch')) return 'rough_sketch_map';
    if (t.contains('complainant')) return 'complainant_statement';
    if (t.contains('witness')) return 'witness_statement';
    if (t.contains('victim')) return 'victim_statement';
    if (t.contains('medical') || t.contains('hospital')) return 'medical_requisition';
    if (t.contains('seizure')) return 'seizure';
    if (t.contains('raid') || t.contains('search')) return 'accused_search';
    if (t.contains('arrest')) return 'arrest';
    if (t.contains('court')) return 'court_forwarding';
    return t.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  bool get _normallyOnceStep => const <String>{
        'po_visit',
        'rough_sketch_map',
        'complainant_statement',
        'victim_statement',
        'medical_requisition',
        'fsl_forwarding',
        'cdr_requisition',
        'ud_inquest_surathal',
        'dead_body_challan',
        'ud_final_report',
        'final_cd',
      }.contains(_currentStepKey);

  String _normalizeName(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  InvestigationActionEntry? _findSameStep() {
    final key = _currentStepKey;
    for (final e in _history) {
      final t = e.actionType.toLowerCase();
      final existingKey = t.contains('po')
          ? 'po_visit'
          : t.contains('sketch')
              ? 'rough_sketch_map'
              : t.contains('complainant')
                  ? 'complainant_statement'
                  : t.contains('witness')
                      ? 'witness_statement'
                      : t.contains('victim')
                          ? 'victim_statement'
                          : t.contains('medical') || t.contains('hospital')
                              ? 'medical_requisition'
                              : t.contains('raid') || t.contains('search')
                                  ? 'accused_search'
                                  : t.contains('arrest')
                                      ? 'arrest'
                                      : t.contains('court')
                                          ? 'court_forwarding'
                                          : t.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      if (existingKey == key) return e;
    }
    return null;
  }

  InvestigationActionEntry? _findSameStatementName() {
    final name = _normalizeName(_personName.text);
    if (name.isEmpty) return null;
    for (final e in _history) {
      final details = _normalizeName('${e.details} ${e.sopResponse} ${e.place}');
      final type = e.actionType.toLowerCase();
      if ((type.contains('witness') || type.contains('complainant') || type.contains('victim')) && details.contains(name)) {
        return e;
      }
    }
    return null;
  }

  Future<bool> _confirmRepeatIfNeeded() async {
    final sameStatement = _findSameStatementName();
    if (sameStatement != null) {
      _repeatReason.clear();
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('একই ব্যক্তির বিবৃতি পূর্বে নেওয়া হয়েছে'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_personName.text.trim()}-এর বিবৃতি ${sameStatement.actionDate} তারিখে নেওয়া হয়েছিল। আপনি কি অতিরিক্ত/পুনঃবিবৃতি নথিভুক্ত করছেন?'),
            const SizedBox(height: 10),
            TextField(controller: _repeatReason, decoration: const InputDecoration(labelText: 'অতিরিক্ত/পুনঃবিবৃতির কারণ', border: OutlineInputBorder()), maxLines: 2),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('অতিরিক্ত বিবৃতি নথিভুক্ত করুন')),
          ],
        ),
      );
      return ok == true;
    }
    if (_normallyOnceStep) {
      final same = _findSameStep();
      if (same != null) {
        _repeatReason.clear();
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('ধাপটি পূর্বেই সম্পন্ন হয়েছে'),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('এই ধাপটি ${same.actionDate} তারিখে সম্পন্ন হয়েছিল। আপনি কি আবার এই কাজটি করেছেন?'),
              const SizedBox(height: 10),
              TextField(controller: _repeatReason, decoration: const InputDecoration(labelText: 'পুনরাবৃত্তি/পুনঃপরিদর্শনের কারণ', border: OutlineInputBorder()), maxLines: 2),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('পুনরাবৃত্তি নথিভুক্ত করুন')),
            ],
          ),
        );
        return ok == true;
      }
    }
    return true;
  }

  List<String> _buildCdParagraphs() {
    final place = _place.text.trim().isEmpty ? 'সংশ্লিষ্ট স্থান' : _place.text.trim();
    final force = _accompaniedBy.text.trim().isEmpty ? 'সঙ্গীয় ফোর্স' : _accompaniedBy.text.trim();
    final personPrefix = _personName.text.trim().isEmpty ? '' : 'ব্যক্তি/সাক্ষী: ${_personName.text.trim()}। ';
    final repeatPrefix = _repeatReason.text.trim().isEmpty ? '' : 'পুনরাবৃত্তি/অতিরিক্ত কারণ: ${_repeatReason.text.trim()}। ';
    final details = '$personPrefix$repeatPrefix${_details.text.trim()}'.trim();
    final action = _actionLabel(_actionType);
    final paragraphs = <String>[];

    if (_isFieldAction) {
      paragraphs.add('পার্শ্বে উল্লিখিত সময়ে আমি $force-কে সঙ্গে নিয়ে এই মামলার তদন্তের স্বার্থে $action করার উদ্দেশ্যে ${widget.profile.policeStation} থেকে $place-এর উদ্দেশ্যে রওনা হলাম।');
      paragraphs.add('পার্শ্বে উল্লিখিত সময়ে আমি $place-এ পৌঁছে $action সম্পন্ন করলাম। ${details.isEmpty ? '' : 'বিস্তারিত: $details'}'.trim());
      if (_returnTime.text.trim().isNotEmpty) {
        paragraphs.add('পার্শ্বে উল্লিখিত সময়ে উপরোক্ত তদন্তের কাজ সম্পন্ন করে আমি $force-কে সঙ্গে নিয়ে ${widget.profile.policeStation}-এ প্রত্যাবর্তন করলাম।');
      }
    } else {
      paragraphs.add('পার্শ্বে উল্লিখিত সময়ে আমি এই মামলার তদন্তের স্বার্থে $action সম্পন্ন করলাম। ${details.isEmpty ? '' : 'বিস্তারিত: $details'}'.trim());
    }

    if (_arrestInvolved) {
      paragraphs.add('অভিযুক্তকে গ্রেপ্তার/আটক করা হয়েছে। আইনানুগ গ্রেপ্তার সংক্রান্ত আনুষ্ঠানিকতা, মেডিক্যাল পরীক্ষা, আত্মীয়কে সংবাদ প্রদান এবং আদালতে ফরওয়ার্ড করার ব্যবস্থা গ্রহণ করতে হবে।');
      paragraphs.add('প্রস্তাবনা: বিজ্ঞ আদালতের নিকট ফরওয়ার্ডিং প্রতিবেদন প্রস্তুত করুন এবং তদন্তের তথ্য ও প্রয়োজন অনুসারে পুলিশ হেফাজত/বিচারবিভাগীয় হেফাজতের প্রার্থনা বিবেচনা করুন।');
    }
    if (_seizureInvolved) {
      paragraphs.add('জব্দ/আলামত সংক্রান্ত ব্যবস্থা গ্রহণ করা হয়েছে। প্রযোজ্য ক্ষেত্রে জব্দতালিকা, সাক্ষী, মালখানা/এফএসএল এবং আলামতের হেফাজতের ধারাবাহিকতা নিশ্চিত করতে হবে।');
    }
    if (_sopResponse.text.trim().isNotEmpty) {
      paragraphs.add('এসওপি অনুবর্তিতা নোট: ${_sopResponse.text.trim()}');
    }
    return paragraphs.where((e) => e.trim().isNotEmpty).toList();
  }

  Future<void> _saveAction() async {
    await BengaliTranslationService.instance.translateControllers([
      _place, _accompaniedBy, _details, _repeatReason, _sopResponse,
    ]);
    if (!mounted) return;
    if (_isFieldAction && (_departureTime.text.trim().isEmpty || _arrivalTime.text.trim().isEmpty)) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('বাধ্যতামূলক সিডি ধাপ অনুপস্থিত'),
          content: const Text('থানার বাইরে তদন্তের কাজ হলে রওনা হওয়ার সময় এবং সংশ্লিষ্ট স্থানে পৌঁছে কাজ শুরুর সময় অবশ্যই লিখতে হবে। এগুলি ছাড়া সিডি-২ ও পরবর্তী এন্ট্রি সম্পূর্ণ হবে না।'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('ঠিক আছে'))],
        ),
      );
      return;
    }

    final confirmed = await _confirmRepeatIfNeeded();
    if (!confirmed) return;

    final personPrefix = _personName.text.trim().isEmpty ? '' : 'ব্যক্তি/সাক্ষী: ${_personName.text.trim()}\n';
    final repeatPrefix = _repeatReason.text.trim().isEmpty ? '' : 'পুনরাবৃত্তি/অতিরিক্ত কারণ: ${_repeatReason.text.trim()}\n';

    final entry = InvestigationActionEntry.create(
      caseId: widget.caseFile.id,
      actionDate: _date.text.trim(),
      actionType: _actionType,
      outsidePs: _isFieldAction,
      departureTime: _departureTime.text.trim(),
      actionArrivalTime: _arrivalTime.text.trim(),
      returnTime: _returnTime.text.trim(),
      place: _place.text.trim(),
      accompaniedBy: _accompaniedBy.text.trim(),
      sopResponse: _sopResponse.text.trim(),
      details: '$personPrefix$repeatPrefix${_details.text.trim()}'.trim(),
      arrestInvolved: _arrestInvolved,
      seizureInvolved: _seizureInvolved,
      courtForwardingSuggested: _courtForwardingSuggested,
      pcPrayerSuggested: _pcPrayerSuggested,
    );
    await _store.saveInvestigationAction(entry);

    final paragraphs = _buildCdParagraphs();
    for (var i = 0; i < paragraphs.length; i++) {
      final action = PendingCdAction.create(
        caseId: widget.caseFile.id,
        sourceType: 'তদন্ত',
        sourceId: '${entry.id}_$i',
        title: i == 0 ? 'তদন্ত: ${_actionLabel(_actionType)}' : 'তদন্তের পরবর্তী পদক্ষেপ: ${_actionLabel(_actionType)}',
        actionDate: entry.actionDate,
        paragraph: paragraphs[i],
      );
      await _store.savePendingCdAction(action);
    }

    if (_arrestInvolved) {
      await _showArrestSuggestions();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('তদন্তের এন্ট্রি সংরক্ষিত হয়েছে এবং সিডির জন্য অপেক্ষমাণ এন্ট্রি তৈরি হয়েছে।')));
    }
    _clearForm(keepDate: true);
    await _loadHistory();
  }

  Future<void> _showArrestSuggestions() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('প্রয়োজনীয় পরবর্তী প্রক্রিয়া'),
        content: const Text('অভিযান/গ্রেপ্তারের এন্ট্রি পাওয়া গেছে। ফরওয়ার্ডিং প্রতিবেদন, অভিযুক্তের মেডিক্যাল পরীক্ষা, গ্রেপ্তারের আনুষ্ঠানিকতা, আত্মীয়কে সংবাদ প্রদান এবং প্রয়োজন হলে পুলিশ হেফাজত/বিচারবিভাগীয় হেফাজতের প্রার্থনা প্রস্তুত করুন। এই নির্দেশনাগুলি সিডির অপেক্ষমাণ এন্ট্রিতেও যোগ হয়েছে।'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('ঠিক আছে'))],
      ),
    );
  }

  void _clearForm({bool keepDate = false}) {
    if (!keepDate) _date.text = DateTime.now().toIso8601String().split('T').first;
    _departureTime.clear();
    _arrivalTime.clear();
    _returnTime.clear();
    _details.clear();
    _personName.clear();
    _repeatReason.clear();
    _sopResponse.clear();
    setState(() {
      _arrestInvolved = false;
      _seizureInvolved = false;
      _courtForwardingSuggested = false;
      _pcPrayerSuggested = false;
    });
  }

  Widget _chipForStep(String label, String containsText) {
    final found = _history.any((e) => e.actionType.toLowerCase().contains(containsText));
    return Chip(
      avatar: Icon(found ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: found ? Colors.green : Colors.orange),
      label: Text('${found ? 'সম্পন্ন' : 'অপেক্ষমাণ'}: $label'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sopRules = _sop.buildRules(widget.caseFile);
    return Scaffold(
      appBar: AppBar(title: const Text('এসওপি-ভিত্তিক তদন্ত')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _saveAction,
            icon: const Icon(Icons.save),
            label: const Text('তদন্ত সংরক্ষণ ও সিডিতে যোগ করুন'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('ধারা: ${widget.caseFile.sections}'),
                const SizedBox(height: 8),
                const Text('এই মডিউলে তদন্তকারী অফিসার যে কাজ লিখবেন, তা তারিখ অনুযায়ী সিডি-২ ও পরবর্তী সিডির অপেক্ষমাণ এন্ট্রি হিসেবে যাবে। থানার বাইরে কাজ হলে প্রস্থান ও আগমন—দুটি এন্ট্রিই আবশ্যক।'),
              ]),
            ),
          ),
          AppSectionCard(
            title: 'স্মার্ট তদন্ত যাচাইতালিকা',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('একবার সম্পন্ন হওয়া ধাপ অন্ধভাবে পুনরায় নথিভুক্ত হবে না। ঘটনাস্থল পরিদর্শন, খসড়া নকশা এবং একই ব্যক্তির বিবৃতি পুনরায় দিতে গেলে সতর্কতা দেখাবে।'),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _chipForStep('ঘটনাস্থল পরিদর্শন', 'po'),
                _chipForStep('খসড়া নকশা', 'sketch'),
                _chipForStep('অভিযোগকারীর বিবৃতি', 'complainant'),
                _chipForStep('সাক্ষীর বিবৃতি', 'witness'),
                _chipForStep('চিকিৎসা', 'medical'),
                _chipForStep('জব্দ', 'seizure'),
                _chipForStep('গ্রেপ্তার/অনুসন্ধান', 'arrest'),
              ]),
            ]),
          ),
          AppSectionCard(
            title: 'দৈনিক তদন্ত এন্ট্রি',
            child: Column(children: [
              FormHelpers.textField(controller: _date, label: 'তারিখ', maxLines: 1),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _actionType,
                decoration: const InputDecoration(labelText: 'তদন্তের কাজের ধরন', border: OutlineInputBorder()),
                items: _actions.map((e) => DropdownMenuItem(value: e, child: Text(_actionLabel(e)))).toList(),
                onChanged: (v) => setState(() {
                  _actionType = v ?? _actionType;
                  final lower = _actionType.toLowerCase();
                  _outsidePs = lower.contains('po') || lower.contains('raid') || lower.contains('search') || lower.contains('hospital') || lower.contains('court') || lower.contains('notice');
                  _arrestInvolved = lower.contains('arrest') || lower.contains('raid');
                }),
              ),
              if (_actionType.toLowerCase().contains('witness') || _actionType.toLowerCase().contains('complainant') || _actionType.toLowerCase().contains('victim'))
                FormHelpers.textField(controller: _personName, label: 'ব্যক্তি/সাক্ষী/অভিযোগকারীর নাম', autoTranslate: false),
              FormHelpers.yesNoTile(title: 'থানার বাইরে কাজ? রওনা ও পৌঁছানোর সময় বাধ্যতামূলক', value: _outsidePs, onChanged: (v) => setState(() => _outsidePs = v)),
              if (_isFieldAction) ...[
                FormHelpers.textField(controller: _departureTime, label: 'থানা থেকে রওনা হওয়ার সময়', maxLines: 1),
                FormHelpers.textField(controller: _arrivalTime, label: 'স্থানে পৌঁছানো/কাজ শুরুর সময়', maxLines: 1),
                FormHelpers.textField(controller: _returnTime, label: 'থানায় ফেরার সময় (ফিরে থাকলে)', maxLines: 1),
                FormHelpers.textField(controller: _place, label: 'পরিদর্শিত স্থান / অভিযান / ঘটনাস্থল / হাসপাতাল / আদালত', maxLines: 2),
                FormHelpers.textField(controller: _accompaniedBy, label: 'সঙ্গে থাকা অফিসার/ফোর্সের বিবরণ', maxLines: 2),
              ],
              FormHelpers.textField(controller: _details, label: 'তদন্তের বিস্তারিত বিবরণ', maxLines: 5),
              FormHelpers.textField(controller: _sopResponse, label: 'এসওপির উত্তর / অনুবর্তিতা নোট', maxLines: 4),
              FormHelpers.yesNoTile(title: 'গ্রেপ্তার / আটক করা হয়েছে?', value: _arrestInvolved, onChanged: (v) => setState(() {
                _arrestInvolved = v;
                if (v) {
                  _courtForwardingSuggested = true;
                  _pcPrayerSuggested = true;
                }
              })),
              FormHelpers.yesNoTile(title: 'জব্দ / আলামত সংক্রান্ত কাজ হয়েছে?', value: _seizureInvolved, onChanged: (v) => setState(() => _seizureInvolved = v)),
              if (_arrestInvolved)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('অ্যাপ প্রস্তাব করবে: আদালতে ফরওয়ার্ডিং, মেডিক্যাল পরীক্ষা, গ্রেপ্তারের আনুষ্ঠানিকতা, আত্মীয়কে সংবাদ এবং প্রয়োজনমতো পুলিশ/বিচারবিভাগীয় হেফাজতের প্রার্থনা।', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
            ]),
          ),
          AppSectionCard(
            title: 'এই মামলার এসওপি নির্দেশনা',
            child: Column(
              children: sopRules.take(8).map((r) => ListTile(
                dense: true,
                leading: Icon(r.mandatory ? Icons.warning_amber_rounded : Icons.info_outline),
                title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${r.detail}\n${r.sectionRef}'),
              )).toList(),
            ),
          ),
          AppSectionCard(
            title: 'সাম্প্রতিক তদন্ত এন্ট্রি',
            child: _history.isEmpty
                ? const Text('এখনও কোনো তদন্ত এন্ট্রি সংরক্ষিত হয়নি।')
                : Column(children: _history.take(10).map((e) => ListTile(
                      title: Text('${e.actionDate} • ${_actionLabel(e.actionType)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${e.place}\n${e.details}', maxLines: 3),
                    )).toList()),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
