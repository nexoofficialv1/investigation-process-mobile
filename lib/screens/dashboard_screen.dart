import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';
import 'officer_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final OfficerProfile profile;
  const DashboardScreen({super.key, required this.profile});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalStoreService _store = LocalStoreService();
  late OfficerProfile _profile;
  List<CaseFile> _cases = [];

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _load();
  }

  Future<void> _load() async {
    final cases = await _store.loadCases();
    if (!mounted) return;
    setState(() => _cases = cases);
  }

  Future<void> _newCase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaseFormScreen(profile: _profile)),
    );
    await _load();
  }

  Future<void> _editProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfficerProfileScreen(
          profile: _profile,
          onSaved: (updated) async {
            await _store.saveOfficerProfile(updated);
            if (!mounted) return;
            setState(() => _profile = updated);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _openCase(CaseFile file) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaseDetailScreen(profile: _profile, caseFile: file)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investigation & Process'),
        actions: [IconButton(onPressed: _editProfile, icon: const Icon(Icons.person))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newCase,
        label: const Text('New Case'),
        icon: const Icon(Icons.add),
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
                    Text('${_profile.rank} ${_profile.name}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${_profile.policeStation}, ${_profile.district}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _summaryCard('Active Cases', _cases.length.toString(), Icons.folder_open)),
                const SizedBox(width: 10),
                Expanded(child: _summaryCard('CD Ready', 'MVP', Icons.note_alt)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Recent Cases', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_cases.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No case created yet. Tap New Case.')))
            else
              ..._cases.map((file) => Card(
                    child: ListTile(
                      title: Text(file.displayTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Sections: ${file.sections}\nComplainant: ${file.complainantName}', maxLines: 2),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openCase(file),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title),
          ],
        ),
      ),
    );
  }
}
