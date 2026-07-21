import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../services/doc_export_service.dart';
import 'case_form_screen.dart';
import 'cd_builder_screen.dart';
import 'cd_editor_screen.dart';
import 'forms_screen.dart';
import 'statement_screen.dart';
import 'compliance_screen.dart';
import 'sketch_map_screen.dart';
import 'evidence_screen.dart';
import 'investigation_screen.dart';
import 'pdf_preview_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const CaseDetailScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final LocalStoreService _store = LocalStoreService();
  late CaseFile _caseFile;
  List<CdEntry> _cds = [];

  @override
  void initState() {
    super.initState();
    _caseFile = widget.caseFile;
    _load();
  }

  Future<void> _load() async {
    final cds = await _store.loadCds(_caseFile.id);
    final allCases = await _store.loadCases();
    CaseFile? refreshed;
    for (final item in allCases) {
      if (item.id == _caseFile.id) {
        refreshed = item;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _cds = cds;
      if (refreshed != null) _caseFile = refreshed;
    });
  }

  Future<void> _editCase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaseFormScreen(profile: widget.profile, existing: _caseFile)),
    );
    await _load();
  }

  Future<void> _newCd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CdBuilderScreen(profile: widget.profile, caseFile: _caseFile)),
    );
    await _load();
  }

  Future<void> _openCd(CdEntry cd) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CdEditorScreen(profile: widget.profile, caseFile: _caseFile, cd: cd)),
    );
    await _load();
  }

  Future<void> _openStatements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatementScreen(profile: widget.profile, caseFile: _caseFile)),
    );
  }

  Future<void> _openForms() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormsScreen(profile: widget.profile, caseFile: _caseFile)),
    );
  }


  Future<void> _openSketchMap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SketchMapScreen(profile: widget.profile, caseFile: _caseFile)),
    );
    await _load();
  }

  Future<void> _openInvestigation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvestigationScreen(profile: widget.profile, caseFile: _caseFile)),
    );
    await _load();
  }

  Future<void> _openEvidence() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EvidenceScreen(profile: widget.profile, caseFile: _caseFile)),
    );
    await _load();
  }

  Future<void> _openCompliance() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComplianceScreen(caseFile: _caseFile)),
    );
  }


  bool get _firstFiveCdsReady {
    final numbers = _cds.map((e) => e.cdNumber).toSet();
    for (var i = 1; i <= 5; i++) {
      if (!numbers.contains(i)) return false;
    }
    return true;
  }

  List<CdEntry> get _firstFiveCds {
    final byNumber = {for (final cd in _cds) cd.cdNumber: cd};
    return [for (var i = 1; i <= 5; i++) byNumber[i]!];
  }

  Future<void> _previewCdOneToFive() async {
    if (!_firstFiveCdsReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CD 1 থেকে CD 5 পর্যন্ত তৈরি হলে একসাথে share/export করা যাবে।')));
      return;
    }
    final cds = _firstFiveCds;
    final baseName = 'CD_1_to_5_${_caseFile.psCaseNo.replaceAll('/', '_')}';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Preview CD 1 to 5',
          filename: '$baseName.pdf',
          docFilename: '$baseName.doc',
          buildPdf: () => PdfService().buildCaseDiaryBundlePdf(officer: widget.profile, caseFile: _caseFile, cds: cds),
          buildDoc: () => DocExportService().buildCaseDiaryBundleDoc(officer: widget.profile, caseFile: _caseFile, cds: cds),
        ),
      ),
    );
  }

  Future<void> _deleteCd(CdEntry cd) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete CD-${cd.cdNumber}?'),
        content: const Text('এই CD delete করলে local saved CD list থেকে মুছে যাবে। আগে backup নেওয়া থাকলে ভালো।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          FilledButton.icon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.delete), label: const Text('মুছুন')),
        ],
      ),
    );
    if (ok != true) return;
    await _store.deleteCd(cd.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CD-${cd.cdNumber} deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_caseFile.displayTitle),
        actions: [IconButton(onPressed: _editCase, icon: const Icon(Icons.edit))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newCd,
        icon: const Icon(Icons.add),
        label: const Text('সিডি যোগ করুন'),
      ),
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
                    Text(_caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('তারিখ: ${_caseFile.caseDate}'),
                    Text('ধারা: ${_caseFile.sections}'),
                    if (_caseFile.complainantName.isNotEmpty) Text('অভিযোগকারী: ${_caseFile.complainantName}', maxLines: 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _moduleCard('তদন্ত', Icons.manage_search, _openInvestigation),
                _moduleCard('সিডি প্রস্তুতকারী', Icons.note_alt, _newCd),
                _moduleCard('বিবৃতি', Icons.record_voice_over, _openStatements),
                _moduleCard('ফর্ম ও নোটিশ', Icons.description, _openForms),
                _moduleCard('অনুবর্তিতা', Icons.checklist, _openCompliance),
                _moduleCard('আলামত/প্রমাণ', Icons.inventory_2, _openEvidence),
                _moduleCard('খসড়া নকশা', Icons.map, _openSketchMap),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Text('কেস ডায়েরিসমূহ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                if (_firstFiveCdsReady)
                  OutlinedButton.icon(
                    onPressed: _previewCdOneToFive,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share CD 1-5'),
                  ),
              ],
            ),
            if (!_firstFiveCdsReady)
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: Text('CD 1-5 ready হলে এখানে একসাথে Preview/Share PDF-DOC option দেখাবে।', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 8),
            if (_cds.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('এখনও কোনো সিডি তৈরি হয়নি। “সিডি যোগ করুন” চাপুন।')))
            else
              ..._cds.map((cd) => Card(
                    child: ListTile(
                      title: Text('সিডি-${cd.cdNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${cd.cdDate} • ${cd.isFinal ? 'Final Saved' : 'Draft'}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'open') _openCd(cd);
                          if (value == 'delete') _deleteCd(cd);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'open', child: Text('Open/Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete CD')),
                        ],
                      ),
                      onTap: () => _openCd(cd),
                    ),
                  )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

}
