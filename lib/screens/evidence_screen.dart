import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/local_store_service.dart';
import '../widgets/form_helpers.dart';

class EvidenceScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const EvidenceScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final LocalStoreService _store = LocalStoreService();
  late CaseFile _caseFile;
  late TextEditingController _physical;
  late TextEditingController _digital;
  late TextEditingController _medical;
  late TextEditingController _seizure;
  late TextEditingController _remarks;

  @override
  void initState() {
    super.initState();
    _caseFile = widget.caseFile;
    final existing = _caseFile.investigationStart.evidenceDetails;
    _physical = TextEditingController(text: _extract(existing, 'ভৌত প্রমাণ'));
    _digital = TextEditingController(text: _extract(existing, 'ডিজিটাল প্রমাণ'));
    _medical = TextEditingController(text: _extract(existing, 'চিকিৎসা / নথিগত প্রমাণ'));
    _seizure = TextEditingController(text: _extract(existing, 'জব্দ / মালখানা / এফএসএল'));
    _remarks = TextEditingController(text: _extract(existing, 'মন্তব্য'));
  }

  String _extract(String source, String title) {
    final marker = '$title:';
    final idx = source.indexOf(marker);
    if (idx < 0) return '';
    final start = idx + marker.length;
    final next = RegExp(r'\n[A-Za-z /]+:').firstMatch(source.substring(start));
    final end = next == null ? source.length : start + next.start;
    return source.substring(start, end).trim();
  }

  @override
  void dispose() {
    _physical.dispose();
    _digital.dispose();
    _medical.dispose();
    _seizure.dispose();
    _remarks.dispose();
    super.dispose();
  }

  String _combinedEvidence() {
    return [
      'ভৌত প্রমাণ: ${_physical.text.trim()}',
      'ডিজিটাল প্রমাণ: ${_digital.text.trim()}',
      'চিকিৎসা / নথিগত প্রমাণ: ${_medical.text.trim()}',
      'জব্দ / মালখানা / এফএসএল: ${_seizure.text.trim()}',
      'মন্তব্য: ${_remarks.text.trim()}',
    ].join('\n');
  }

  Future<void> _save({bool askCd = false}) async {
    final start = _caseFile.investigationStart;
    final updatedStart = InvestigationStart(
      ioName: start.ioName,
      tookUpDate: start.tookUpDate,
      visitedPo: start.visitedPo,
      poDetails: start.poDetails,
      sketchPrepared: start.sketchPrepared,
      sketchDetails: start.sketchDetails,
      witnessExamined: start.witnessExamined,
      witnessDetails: start.witnessDetails,
      medicalRequired: start.medicalRequired,
      medicalDetails: start.medicalDetails,
      seizureRequired: start.seizureRequired,
      seizureDetails: start.seizureDetails,
      evidenceRequired: true,
      evidenceDetails: _combinedEvidence(),
    );
    final updated = _caseFile.copyWith(investigationStart: updatedStart);
    await _store.saveCase(updated);
    if (!mounted) return;
    setState(() => _caseFile = updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('প্রমাণের বিবরণ সংরক্ষিত হয়েছে')));
    if (askCd) await _askMentionInCd();
  }

  Future<void> _askMentionInCd() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('কেস ডায়েরিতে উল্লেখ করবেন?'),
        content: const Text('প্রমাণ/জব্দ/ডিজিটাল প্রমাণের বিবরণ সিডিতে অপেক্ষমাণ এন্ট্রি হিসেবে রাখবেন?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('হ্যাঁ')),
        ],
      ),
    );
    if (yes != true) return;
    final action = PendingCdAction.create(
      caseId: _caseFile.id,
      sourceType: 'প্রমাণ',
      sourceId: _caseFile.id,
      title: 'প্রমাণের বিবরণ হালনাগাদ হয়েছে',
      actionDate: DateTime.now().toIso8601String().split('T').first,
      paragraph: 'এই মামলার সূত্রে প্রমাণ/আলামতের বিবরণ যাচাই/সংগ্রহ করা হয়েছে। বিস্তারিত: ${_combinedEvidence()}',
    );
    await _store.savePendingCdAction(action);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অপেক্ষমাণ সিডি এন্ট্রি তৈরি হয়েছে')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('প্রমাণ ব্যবস্থাপক')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save), label: const Text('সংরক্ষণ'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: () => _save(askCd: true), icon: const Icon(Icons.note_add), label: const Text('সংরক্ষণ + সিডি'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('ধারা: ${_caseFile.sections}'),
                  const SizedBox(height: 8),
                  const Text('এখানে ভৌত/ডিজিটাল/চিকিৎসা/জব্দ সংক্রান্ত প্রমাণের বিবরণ লিখুন। পরে সিডি/আইএফ-৫-এ এগুলি ব্যবহার হবে।', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          FormHelpers.textField(controller: _physical, label: 'ভৌত প্রমাণ/আলামত/নথি', maxLines: 4),
          FormHelpers.textField(controller: _digital, label: 'ডিজিটাল প্রমাণ/সিসিটিভি/সিডিআর/সিএএফ/ব্যাংক/ইউপিআই', maxLines: 4),
          FormHelpers.textField(controller: _medical, label: 'চিকিৎসা/বিএইচটি/আঘাত/ময়নাতদন্ত/প্রতিবেদন প্রমাণ', maxLines: 4),
          FormHelpers.textField(controller: _seizure, label: 'জব্দ/মালখানা/এফএসএল/সম্পত্তি রেজিস্টার', maxLines: 4),
          FormHelpers.textField(controller: _remarks, label: 'মন্তব্য/পরবর্তী পদক্ষেপ', maxLines: 4),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
