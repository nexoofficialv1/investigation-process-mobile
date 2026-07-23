import 'package:flutter/material.dart';

import '../core/document_language.dart';
import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/guided_daily_entry.dart';
import '../models/officer_profile.dart';
import '../services/daily_cd_assembly_service.dart';
import '../services/guided_daily_entry_store.dart';
import '../services/local_store_service.dart';
import 'cd_builder_screen.dart';
import 'cd_editor_screen.dart';
import 'guided_daily_entry_screen.dart';

class DailyCdModeScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  final String? initialDate;
  final bool lockDate;
  final bool autoGenerate;
  const DailyCdModeScreen({
    super.key,
    required this.profile,
    required this.caseFile,
    this.initialDate,
    this.lockDate = false,
    this.autoGenerate = false,
  });

  @override
  State<DailyCdModeScreen> createState() => _DailyCdModeScreenState();
}

class _DailyCdModeScreenState extends State<DailyCdModeScreen> {
  final GuidedDailyEntryStore _entryStore = GuidedDailyEntryStore();
  final LocalStoreService _localStore = LocalStoreService();
  final DailyCdAssemblyService _assembly = DailyCdAssemblyService();
  late final TextEditingController _date;
  DocumentLanguage _language = DocumentLanguage.bangla;
  List<GuidedDailyEntry> _entries = <GuidedDailyEntry>[];
  bool _busy = false;

  int get _investigationCount => _entries
      .where((item) => item.source == DailyEntrySource.investigation)
      .expand((item) => item.actions)
      .where((item) => item.includeInCd)
      .length;

  int get _evidenceCount => _entries
      .where((item) => item.source == DailyEntrySource.evidence)
      .expand((item) => item.actions)
      .where((item) => item.includeInCd)
      .length;

  @override
  void initState() {
    super.initState();
    _date = TextEditingController(
      text: widget.initialDate ??
          DateTime.now().toIso8601String().split('T').first,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _load();
      if (widget.autoGenerate && mounted) {
        await _automaticCd();
      }
    });
  }

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await _entryStore.loadForDate(
      widget.caseFile.id,
      _date.text.trim(),
    );
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _date.text = picked.toIso8601String().split('T').first;
    await _load();
  }

  Future<void> _addSource(DailyEntrySource source) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedDailyEntryScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
          source: source,
          initialDate: _date.text.trim(),
        ),
      ),
    );
    await _load();
  }

  Future<void> _automaticCd() async {
    if (_investigationCount + _evidenceCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('এই তারিখে Investigation বা Evidence Entry পাওয়া যায়নি।'),
        ),
      );
      return;
    }
    final existingCd = await _localStore.loadCdForDate(
      widget.caseFile.id,
      _date.text.trim(),
    );
    final nextNumber = existingCd?.cdNumber ??
        await _localStore.nextCdNumber(widget.caseFile.id);
    if (!mounted) return;


    setState(() => _busy = true);
    try {
      final result = await _assembly.build(
        caseId: widget.caseFile.id,
        caseFile: widget.caseFile,
        actionDate: _date.text.trim(),
        cdNumber: nextNumber,
        profile: widget.profile,
        language: _language,
        entries: _entries,
      );
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CD-তে নেওয়ার মতো Entry পাওয়া যায়নি।')),
        );
        return;
      }
      final savedCd = await _localStore.saveCdForDate(result.cd);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CdEditorScreen(
            profile: widget.profile,
            caseFile: widget.caseFile,
            cd: savedCd,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manualCd() async {
    final existingCd = await _localStore.loadCdForDate(
      widget.caseFile.id,
      _date.text.trim(),
    );
    if (existingCd != null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CdEditorScreen(
            profile: widget.profile,
            caseFile: widget.caseFile,
            cd: existingCd,
          ),
        ),
      );
      return;
    }
    final nextNumber = await _localStore.nextCdNumber(widget.caseFile.id);
    final station = widget.profile.policeStation.trim().isEmpty
        ? 'থানা'
        : widget.profile.policeStation.trim();
    final line = CdTableLine(
      noAndHour: _language.isBangla ? '১\n' : '1\n',
      placeOfEntry: station,
      synopsis: '',
      proceedings: '',
    );
    final draft = CdEntry.newDraft(
      caseId: widget.caseFile.id,
      cdNumber: nextNumber,
      body: '',
      placeOfEntry: station,
      tableLines: <CdTableLine>[line],
      languageCode: _language.code,
    ).copyWith(cdDate: _date.text.trim());
    final savedDraft = await _localStore.saveCdForDate(draft);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CdEditorScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
          cd: savedDraft,
        ),
      ),
    );
  }

  Future<void> _legacyBuilder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CdBuilderScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case Diary তৈরির পদ্ধতি')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _date,
            readOnly: true,
            onTap: widget.lockDate ? null : _pickDate,
            decoration: InputDecoration(
              labelText: widget.lockDate
                  ? 'Case Diary-এর তারিখ (দিনের Entry থেকে নেওয়া)'
                  : 'Case Diary-এর তারিখ',
              suffixIcon: Icon(
                widget.lockDate
                    ? Icons.lock_outline
                    : Icons.calendar_month,
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DocumentLanguage>(
            value: _language,
            decoration: const InputDecoration(
              labelText: 'Case Diary-এর ভাষা',
              border: OutlineInputBorder(),
            ),
            items: DocumentLanguage.values
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.displayLabel),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _language = value ?? DocumentLanguage.bangla),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _sourceCard(
                  title: 'Investigation',
                  count: _investigationCount,
                  icon: Icons.manage_search,
                  onTap: () => _addSource(DailyEntrySource.investigation),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _sourceCard(
                  title: 'Evidence',
                  count: _evidenceCount,
                  icon: Icons.inventory_2,
                  onTap: () => _addSource(DailyEntrySource.evidence),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Automatic CD',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(_automaticDescription()),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _automaticCd,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('এই দিনের Automatic CD তৈরি করুন'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Manual CD',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'IO নিজে Entry No., Time, Place, Synopsis ও Proceedings লিখে আগের official CD Editor-এ CD প্রস্তুত করবেন।',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _manualCd,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Manual CD খুলুন'),
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _legacyBuilder,
            icon: const Icon(Icons.history),
            label: const Text('পুরোনো existing CD Builder খুলুন'),
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  String _automaticDescription() {
    if (_investigationCount > 0 && _evidenceCount > 0) {
      return 'এই তারিখের Investigation ও Evidence মিলিয়ে chronology অনুযায়ী একটি CD হবে। Duplicate Entry বাদ যাবে।';
    }
    if (_investigationCount > 0) {
      return 'এই তারিখে শুধু Investigation Entry আছে। শুধু Investigation নিয়েই CD হবে।';
    }
    if (_evidenceCount > 0) {
      return 'এই তারিখে শুধু Evidence Entry আছে। শুধু Evidence নিয়েই CD হবে।';
    }
    return 'এই তারিখে এখনও কোনো দিনের Entry নেই।';
  }

  Widget _sourceCard({
    required String title,
    required int count,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 30),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('$countটি CD Entry'),
              const SizedBox(height: 6),
              const Text('Add/Edit', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
