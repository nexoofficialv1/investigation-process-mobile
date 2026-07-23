import 'package:flutter/material.dart';

import '../models/case_chronology.dart';
import '../models/case_file.dart';
import '../services/chronology_engine_service.dart';

class InvestigationChecklistScreen extends StatefulWidget {
  final CaseFile caseFile;

  const InvestigationChecklistScreen({
    super.key,
    required this.caseFile,
  });

  @override
  State<InvestigationChecklistScreen> createState() =>
      _InvestigationChecklistScreenState();
}

class _InvestigationChecklistScreenState
    extends State<InvestigationChecklistScreen> {
  final ChronologyEngineService _engine = ChronologyEngineService();
  CaseChronologySnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snapshot = await _engine.buildSnapshot(widget.caseFile);
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('স্বয়ংক্রিয় তদন্ত যাচাইতালিকা'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Chronology পুনরায় যাচাই',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : snapshot == null
              ? const Center(child: Text('Chronology load করা যায়নি।'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: <Widget>[
                      _summaryCard(snapshot),
                      const SizedBox(height: 10),
                      _nextQuestionCard(snapshot.nextQuestion),
                      const SizedBox(height: 10),
                      _readinessCard(snapshot.readiness),
                      if (snapshot.issues.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        _issuesCard(snapshot.issues),
                      ],
                      const SizedBox(height: 10),
                      ..._groupedChecklist(snapshot.checklist),
                      const SizedBox(height: 70),
                    ],
                  ),
                ),
    );
  }

  Widget _summaryCard(CaseChronologySnapshot snapshot) {
    final percent = (snapshot.progress * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.caseFile.displayTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text('ধারা: ${widget.caseFile.sections}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: snapshot.progress),
            const SizedBox(height: 8),
            Text(
              'App verified: ${snapshot.completeCount}/${snapshot.totalCount} ($percent%)',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'এই তালিকা Officer manually tick করবেন না। Investigation, '
              'Evidence, Statement, Form, Sketch Map ও CD দেখে app নিজে status নির্ধারণ করে।',
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextQuestionCard(String question) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.question_answer)),
        title: const Text(
          'Chronology অনুযায়ী পরবর্তী প্রশ্ন',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(question),
        ),
      ),
    );
  }

  Widget _readinessCard(DocumentReadiness readiness) {
    Widget row(String title, bool ready) => ListTile(
          dense: true,
          leading: Icon(
            ready ? Icons.check_circle : Icons.lock_clock,
            color: ready ? Colors.green : Colors.orange,
          ),
          title: Text(title),
          subtitle: Text(ready ? 'Ready for officer review' : 'Not ready'),
        );

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text(
          'Document Readiness',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        children: <Widget>[
          row('Case Diary', readiness.caseDiaryReady),
          row('Memo of Evidence', readiness.memoOfEvidenceReady),
          row('Final Report', readiness.finalReportReady),
          row('Charge Sheet / IF5', readiness.chargeSheetReady),
          if (readiness.blockers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Blockers:\n• ${readiness.blockers.join('\n• ')}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _issuesCard(List<ChronologyIssue> issues) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.warning_amber),
        title: Text(
          'Chronology issue: ${issues.length}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        children: issues
            .map(
              (issue) => ListTile(
                dense: true,
                leading: Icon(
                  issue.blocksFinalization ? Icons.block : Icons.info_outline,
                ),
                title: Text(issue.message),
                subtitle: Text(
                  issue.blocksFinalization
                      ? 'Final document blocked'
                      : 'Review advised',
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<Widget> _groupedChecklist(
    List<ChronologyChecklistItem> checklist,
  ) {
    final groups = <String, List<ChronologyChecklistItem>>{};
    for (final item in checklist) {
      groups.putIfAbsent(item.group, () => <ChronologyChecklistItem>[]).add(item);
    }

    return groups.entries
        .map(
          (entry) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              children: entry.value.map(_checklistTile).toList(),
            ),
          ),
        )
        .toList();
  }

  Widget _checklistTile(ChronologyChecklistItem item) {
    IconData icon;
    Color color;
    switch (item.state) {
      case ChecklistState.done:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ChecklistState.repeated:
        icon = Icons.repeat_on;
        color = Colors.blue;
        break;
      case ChecklistState.notApplicable:
        icon = Icons.remove_circle_outline;
        color = Colors.grey;
        break;
      case ChecklistState.partial:
        icon = Icons.timelapse;
        color = Colors.orange;
        break;
      case ChecklistState.needsVerification:
        icon = Icons.help;
        color = Colors.deepOrange;
        break;
      case ChecklistState.pending:
        icon = Icons.radio_button_unchecked;
        color = Colors.redAccent;
        break;
    }

    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(item.title),
      subtitle: item.sourceReference.trim().isEmpty
          ? Text(item.mandatory ? 'Pending' : 'Optional')
          : Text('Source: ${item.sourceReference}'),
    );
  }
}
