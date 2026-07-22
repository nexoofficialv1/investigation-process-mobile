import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/guided_daily_entry.dart';
import '../models/officer_profile.dart';
import '../services/guided_daily_entry_store.dart';
import 'daily_cd_mode_screen.dart';
import 'evidence_screen.dart';
import 'guided_daily_entry_screen.dart';
import 'investigation_screen.dart';

class DailyWorkHubScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;
  final DailyEntrySource source;

  const DailyWorkHubScreen({
    super.key,
    required this.profile,
    required this.caseFile,
    required this.source,
  });

  factory DailyWorkHubScreen.investigation({
    Key? key,
    required OfficerProfile profile,
    required CaseFile caseFile,
  }) {
    return DailyWorkHubScreen(
      key: key,
      profile: profile,
      caseFile: caseFile,
      source: DailyEntrySource.investigation,
    );
  }

  factory DailyWorkHubScreen.evidence({
    Key? key,
    required OfficerProfile profile,
    required CaseFile caseFile,
  }) {
    return DailyWorkHubScreen(
      key: key,
      profile: profile,
      caseFile: caseFile,
      source: DailyEntrySource.evidence,
    );
  }

  @override
  State<DailyWorkHubScreen> createState() => _DailyWorkHubScreenState();
}

class _DailyWorkHubScreenState extends State<DailyWorkHubScreen> {
  final GuidedDailyEntryStore _store = GuidedDailyEntryStore();
  List<GuidedDailyEntry> _entries = <GuidedDailyEntry>[];

  bool get _isEvidence => widget.source == DailyEntrySource.evidence;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _store.loadForCase(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      _entries = all.where((item) => item.source == widget.source).toList();
    });
  }

  Future<void> _openToday({String? date}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedDailyEntryScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
          source: widget.source,
          initialDate: date,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openDetailed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _isEvidence
            ? EvidenceScreen(
                profile: widget.profile,
                caseFile: widget.caseFile,
              )
            : InvestigationScreen(
                profile: widget.profile,
                caseFile: widget.caseFile,
              ),
      ),
    );
    await _load();
  }

  Future<void> _openCd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCdModeScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.source.banglaLabel;
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(
                      _isEvidence ? Icons.inventory_2 : Icons.manage_search,
                      size: 42,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'আজকের $label Entry',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isEvidence
                          ? 'আজ পাওয়া, সংগ্রহ, জব্দ, পরীক্ষা বা সংরক্ষণ করা Evidence নিজের ভাষায় বলুন বা লিখুন। অ্যাপ প্রয়োজনমতো প্রশ্ন করবে।'
                          : 'আজ তদন্তে যা যা করেছেন নিজের ভাষায় বলুন বা লিখুন। অ্যাপ প্রয়োজনমতো প্রশ্ন করে সম্পূর্ণ তথ্য নেবে।',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _openToday,
                      icon: const Icon(Icons.mic),
                      label: const Text('নিজের ভাষায় দিনের Entry দিন'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _openDetailed,
              icon: const Icon(Icons.fact_check_outlined),
              label: Text('পুরোনো বিস্তারিত $label Form খুলুন'),
            ),
            OutlinedButton.icon(
              onPressed: _openCd,
              icon: const Icon(Icons.note_alt_outlined),
              label: const Text('দিনের Case Diary তৈরি করুন'),
            ),
            const SizedBox(height: 18),
            Text(
              'তারিখ অনুযায়ী সংরক্ষিত Entry',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (_entries.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('এখনও কোনো দিনের Entry সংরক্ষিত হয়নি।'),
                ),
              )
            else
              ..._entries.map((entry) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(entry.actionDate),
                      subtitle: Text(
                        '${entry.actions.where((item) => item.includeInCd).length}টি কাজ • ${entry.documentLanguageCode == 'en' ? 'English CD' : 'বাংলা CD'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openToday(date: entry.actionDate),
                    ),
                  )),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
