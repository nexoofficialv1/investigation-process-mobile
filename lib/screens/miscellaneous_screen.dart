import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../screens/pdf_preview_screen.dart';
import '../services/doc_export_service.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import 'report_screen.dart';
import '../models/case_file.dart';

class MiscellaneousScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile? latestCase;
  const MiscellaneousScreen({super.key, required this.profile, this.latestCase});

  @override
  State<MiscellaneousScreen> createState() => _MiscellaneousScreenState();
}

class _MiscellaneousScreenState extends State<MiscellaneousScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Miscellaneous'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.summarize), text: 'Reports'),
            Tab(icon: Icon(Icons.badge), text: 'Duty Column'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportsTab(profile: widget.profile, latestCase: widget.latestCase),
          _DutyColumnTab(profile: widget.profile),
          _InventoryTab(profile: widget.profile),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  final OfficerProfile profile;
  final CaseFile? latestCase;
  const _ReportsTab({required this.profile, this.latestCase});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('এখান থেকে case-related report অথবা case ছাড়া general office report তৈরি করা যাবে। Preview দেখে PDF/DOC export করবেন।', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: Colors.white,
          leading: const CircleAvatar(child: Icon(Icons.folder_copy)),
          title: const Text('Case Related / General Report'),
          subtitle: Text(latestCase == null ? 'General report mode. Case থাকলে optional tag করা যাবে।' : 'Latest case available: ${latestCase!.displayTitle}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(profile: profile, caseFile: latestCase))),
        ),
      ],
    );
  }
}

class _DutyColumnTab extends StatefulWidget {
  final OfficerProfile profile;
  const _DutyColumnTab({required this.profile});

  @override
  State<_DutyColumnTab> createState() => _DutyColumnTabState();
}

class _DutyColumnTabState extends State<_DutyColumnTab> {
  final _store = LocalStoreService();
  final _pdf = PdfService();
  final _date = TextEditingController();
  final _dutyType = TextEditingController();
  final _staffName = TextEditingController();
  final _rank = TextEditingController();
  final _place = TextEditingController();
  final _time = TextEditingController();
  final _mobile = TextEditingController();
  final _remarks = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  static const _key = 'misc_duty_entries_v1';

  @override
  void initState() {
    super.initState();
    _date.text = _today();
    _rank.text = widget.profile.rank;
    _load();
  }

  @override
  void dispose() {
    for (final c in [_date, _dutyType, _staffName, _rank, _place, _time, _mobile, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  String _today() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    setState(() => _rows = (jsonDecode(raw) as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_rows));
  }

  void _addRow() {
    final row = {
      'date': _date.text.trim(),
      'dutyType': _dutyType.text.trim(),
      'staffName': _staffName.text.trim(),
      'rank': _rank.text.trim(),
      'place': _place.text.trim(),
      'time': _time.text.trim(),
      'mobile': _mobile.text.trim(),
      'remarks': _remarks.text.trim(),
    };
    setState(() => _rows.insert(0, row));
    _persist();
    _staffName.clear();
    _place.clear();
    _time.clear();
    _mobile.clear();
    _remarks.clear();
  }

  String _body() {
    final buffer = StringBuffer();
    buffer.writeln('Duty Column / Duty Roster');
    buffer.writeln('Prepared by: ${widget.profile.rank} ${widget.profile.name}, ${widget.profile.policeStation}');
    buffer.writeln('');
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      buffer.writeln('${i + 1}. Date: ${r['date']}');
      buffer.writeln('Duty Type: ${r['dutyType']}');
      buffer.writeln('Officer/Staff: ${r['rank']} ${r['staffName']}');
      buffer.writeln('Duty Point/Place: ${r['place']}');
      buffer.writeln('Timing: ${r['time']}');
      buffer.writeln('Mobile: ${r['mobile']}');
      buffer.writeln('Remarks: ${r['remarks']}');
      buffer.writeln('');
    }
    return buffer.toString().trim();
  }

  Future<void> _saveDraft() async {
    await _store.saveForm(FormNotice.create(caseId: 'misc_duty', templateId: 'misc_duty_column', title: 'Duty Column / Duty Roster', body: _body()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duty Column saved.')));
  }

  Future<void> _preview() async {
    final form = FormNotice.create(caseId: 'misc_duty', templateId: 'misc_duty_column', title: 'Duty Column / Duty Roster', body: _body());
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(
      title: 'Duty Column Preview',
      filename: 'Duty_Column.pdf',
      docFilename: 'Duty_Column.doc',
      buildPdf: () => _pdf.buildGeneralReportPdf(officer: widget.profile, form: form),
      buildDoc: () => DocExportService().buildGeneralReportDoc(officer: widget.profile, form: form),
      onFinalSave: () async => _store.saveForm(form.copyWith(isFinal: true)),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Duty Column / Duty Roster', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        TextField(controller: _date, decoration: const InputDecoration(labelText: 'Date')),
        TextField(controller: _dutyType, decoration: const InputDecoration(labelText: 'Duty Type')),
        TextField(controller: _staffName, decoration: const InputDecoration(labelText: 'Officer/Staff Name')),
        TextField(controller: _rank, decoration: const InputDecoration(labelText: 'Rank')),
        TextField(controller: _place, decoration: const InputDecoration(labelText: 'Duty Point / Place')),
        TextField(controller: _time, decoration: const InputDecoration(labelText: 'Duty Timing')),
        TextField(controller: _mobile, decoration: const InputDecoration(labelText: 'Mobile No.')),
        TextField(controller: _remarks, decoration: const InputDecoration(labelText: 'Remarks'), minLines: 2, maxLines: 4),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: const Text('Add Duty Entry')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _saveDraft, icon: const Icon(Icons.save), label: const Text('Save'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: _rows.isEmpty ? null : _preview, icon: const Icon(Icons.preview), label: const Text('Preview'))),
        ]),
        const SizedBox(height: 14),
        ..._rows.map((r) => Card(child: ListTile(
          title: Text('${r['rank']} ${r['staffName']}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${r['date']} • ${r['dutyType']} • ${r['place']}\n${r['time']} • ${r['remarks']}'),
          isThreeLine: true,
          trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () { setState(() => _rows.remove(r)); _persist(); }),
        ))),
      ],
    );
  }
}

class _InventoryTab extends StatefulWidget {
  final OfficerProfile profile;
  const _InventoryTab({required this.profile});

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  final _store = LocalStoreService();
  final _pdf = PdfService();
  final _item = TextEditingController();
  final _category = TextEditingController();
  final _quantity = TextEditingController();
  final _issuedTo = TextEditingController();
  final _issueDate = TextEditingController();
  final _returnDate = TextEditingController();
  final _condition = TextEditingController();
  final _remarks = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  static const _key = 'misc_inventory_entries_v1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_item, _category, _quantity, _issuedTo, _issueDate, _returnDate, _condition, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    setState(() => _rows = (jsonDecode(raw) as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_rows));
  }

  void _addRow() {
    final row = {
      'item': _item.text.trim(),
      'category': _category.text.trim(),
      'quantity': _quantity.text.trim(),
      'issuedTo': _issuedTo.text.trim(),
      'issueDate': _issueDate.text.trim(),
      'returnDate': _returnDate.text.trim(),
      'condition': _condition.text.trim(),
      'remarks': _remarks.text.trim(),
    };
    setState(() => _rows.insert(0, row));
    _persist();
    _item.clear();
    _quantity.clear();
    _issuedTo.clear();
    _issueDate.clear();
    _returnDate.clear();
    _condition.clear();
    _remarks.clear();
  }

  String _body() {
    final buffer = StringBuffer();
    buffer.writeln('Inventory Register / Stock Statement');
    buffer.writeln('Prepared by: ${widget.profile.rank} ${widget.profile.name}, ${widget.profile.policeStation}');
    buffer.writeln('');
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      buffer.writeln('${i + 1}. Item: ${r['item']}');
      buffer.writeln('Category: ${r['category']}');
      buffer.writeln('Quantity: ${r['quantity']}');
      buffer.writeln('Issued To: ${r['issuedTo']}');
      buffer.writeln('Issue Date: ${r['issueDate']}');
      buffer.writeln('Return Date: ${r['returnDate']}');
      buffer.writeln('Condition: ${r['condition']}');
      buffer.writeln('Remarks: ${r['remarks']}');
      buffer.writeln('');
    }
    return buffer.toString().trim();
  }

  Future<void> _saveDraft() async {
    await _store.saveForm(FormNotice.create(caseId: 'misc_inventory', templateId: 'misc_inventory', title: 'Inventory Register / Stock Statement', body: _body()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory saved.')));
  }

  Future<void> _preview() async {
    final form = FormNotice.create(caseId: 'misc_inventory', templateId: 'misc_inventory', title: 'Inventory Register / Stock Statement', body: _body());
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(
      title: 'Inventory Preview',
      filename: 'Inventory_Register.pdf',
      docFilename: 'Inventory_Register.doc',
      buildPdf: () => _pdf.buildGeneralReportPdf(officer: widget.profile, form: form),
      buildDoc: () => DocExportService().buildGeneralReportDoc(officer: widget.profile, form: form),
      onFinalSave: () async => _store.saveForm(form.copyWith(isFinal: true)),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        TextField(controller: _item, decoration: const InputDecoration(labelText: 'Item Name')),
        TextField(controller: _category, decoration: const InputDecoration(labelText: 'Category')),
        TextField(controller: _quantity, decoration: const InputDecoration(labelText: 'Quantity / Balance Stock')),
        TextField(controller: _issuedTo, decoration: const InputDecoration(labelText: 'Issued To')),
        TextField(controller: _issueDate, decoration: const InputDecoration(labelText: 'Issue Date')),
        TextField(controller: _returnDate, decoration: const InputDecoration(labelText: 'Return Date')),
        TextField(controller: _condition, decoration: const InputDecoration(labelText: 'Condition')),
        TextField(controller: _remarks, decoration: const InputDecoration(labelText: 'Remarks'), minLines: 2, maxLines: 4),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: const Text('Add Inventory Entry')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _saveDraft, icon: const Icon(Icons.save), label: const Text('Save'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: _rows.isEmpty ? null : _preview, icon: const Icon(Icons.preview), label: const Text('Preview'))),
        ]),
        const SizedBox(height: 14),
        ..._rows.map((r) => Card(child: ListTile(
          title: Text('${r['item']} (${r['quantity']})', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${r['category']} • Issued to: ${r['issuedTo']}\nCondition: ${r['condition']} • ${r['remarks']}'),
          isThreeLine: true,
          trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () { setState(() => _rows.remove(r)); _persist(); }),
        ))),
      ],
    );
  }
}
