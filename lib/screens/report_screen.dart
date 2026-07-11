import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../screens/pdf_preview_screen.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';

class ReportScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const ReportScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _store = LocalStoreService();
  final _pdf = PdfService();
  late _ReportTemplate _selected;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  late TextEditingController _recipientController;
  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _selected = _templates.first;
    _recipientController = TextEditingController(text: _selected.recipient);
    _subjectController = TextEditingController(text: _selected.subject(widget.caseFile));
    _bodyController = TextEditingController(text: _selected.body(widget.profile, widget.caseFile));
    _memoController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _recipientController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _applyTemplate(_ReportTemplate template) {
    setState(() {
      _selected = template;
      _recipientController.text = template.recipient;
      _subjectController.text = template.subject(widget.caseFile);
      _bodyController.text = template.body(widget.profile, widget.caseFile);
    });
  }

  FormNotice _buildReport({bool finalSave = false}) {
    final title = 'Report to ${_recipientController.text.trim()}';
    final memo = _memoController.text.trim().isEmpty ? '' : 'Memo No.: ${_memoController.text.trim()}\n\n';
    final body = '''To\n${_recipientController.text.trim()}\n\nSubject: ${_subjectController.text.trim()}\n\n$memo${_bodyController.text.trim()}\n\nSubmitted for favour of kind information and necessary action.''';
    return FormNotice.create(
      caseId: widget.caseFile.id,
      templateId: 'report_${_selected.id}',
      title: title,
      body: body,
    ).copyWith(isFinal: finalSave);
  }

  Future<void> _saveDraft() async {
    await _store.saveForm(_buildReport());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report draft saved.')));
  }

  Future<void> _preview() async {
    final report = _buildReport();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Report Preview',
          filename: 'Report_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.pdf',
          buildPdf: () => _pdf.buildFormNoticePdf(officer: widget.profile, caseFile: widget.caseFile, form: report),
          onFinalSave: () async => _store.saveForm(report.copyWith(isFinal: true)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Draft'),
                  onPressed: _saveDraft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview'),
                  onPressed: _preview,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Sections: ${widget.caseFile.sections}'),
                  const SizedBox(height: 8),
                  const Text('SP / SDPO / SDO বা অন্য অফিসে পাঠানোর report এখান থেকে তৈরি করা যাবে। Preview দেখে তারপর export করবেন।', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_ReportTemplate>(
            value: _selected,
            decoration: const InputDecoration(labelText: 'Report Type'),
            items: _templates.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
            onChanged: (value) {
              if (value != null) _applyTemplate(value);
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _recipientController,
            decoration: const InputDecoration(labelText: 'To / Recipient Office'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(labelText: 'Subject'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _memoController,
            decoration: const InputDecoration(labelText: 'Memo No. / Reference, if any'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _bodyController,
            decoration: const InputDecoration(labelText: 'Report Body'),
            minLines: 12,
            maxLines: 22,
            textAlignVertical: TextAlignVertical.top,
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _ReportTemplate {
  final String id;
  final String name;
  final String recipient;
  final String Function(CaseFile file) subject;
  final String Function(OfficerProfile officer, CaseFile file) body;

  const _ReportTemplate({required this.id, required this.name, required this.recipient, required this.subject, required this.body});
}

final List<_ReportTemplate> _templates = [
  _ReportTemplate(
    id: 'sp_progress',
    name: 'Report to Superintendent of Police',
    recipient: 'The Superintendent of Police, Purba Bardhaman',
    subject: (file) => 'Progress report in connection with ${file.displayTitle}',
    body: (officer, file) => '''Most respectfully I beg to submit that the above noted case was started on ${file.caseDate} u/s ${file.sections} on the basis of a written complaint/FIR.\n\nDuring investigation, I took up investigation, perused the case record, visited/verified the relevant place and examined available witnesses as applicable. The present status of investigation is submitted below:\n\n1. Brief fact: ${file.firGist}\n2. PO: ${file.placeOfOccurrence}\n3. Complainant: ${file.complainantName}\n4. Victim: ${file.victimName}\n5. Accused/Suspect: ${file.accusedName}\n6. Present progress: \n7. Further action proposed: \n\nThis is submitted for favour of kind information.''',
  ),
  _ReportTemplate(
    id: 'sdpo_progress',
    name: 'Report to SDPO',
    recipient: 'The Sub-Divisional Police Officer, Kalna',
    subject: (file) => 'Report regarding ${file.displayTitle}',
    body: (officer, file) => '''Most respectfully I submit that in connection with the above noted case, the undersigned has conducted investigation and the following facts have come to light.\n\nCase reference: ${officer.policeStation} Case No. ${file.psCaseNo} dated ${file.caseDate} u/s ${file.sections}.\n\nBrief fact: ${file.firGist}\n\nSteps taken during investigation:\n1. Case record perused.\n2. Relevant witnesses examined.\n3. Necessary requisition/document collection steps taken as applicable.\n4. Present status: \n\nFurther action: \n\nSubmitted for kind perusal and necessary direction.''',
  ),
  _ReportTemplate(
    id: 'sdo_report',
    name: 'Report to SDO / Executive Magistrate',
    recipient: 'The Sub-Divisional Officer, Kalna',
    subject: (file) => 'Enquiry report regarding ${file.displayTitle}',
    body: (officer, file) => '''Most respectfully I beg to submit that as per direction/endorsement, an enquiry/investigation was conducted in connection with the above noted matter.\n\nDuring enquiry/investigation, local enquiry was held and available persons were contacted. The relevant facts are as follows:\n\n1. Case/Matter reference: ${file.displayTitle}\n2. Sections/Subject: ${file.sections}\n3. Place: ${file.placeOfOccurrence}\n4. Brief fact: ${file.firGist}\n5. Enquiry finding: \n6. Present situation: \n7. Police action taken/proposed: \n\nSubmitted for favour of kind information and necessary order.''',
  ),
  _ReportTemplate(
    id: 'general_office',
    name: 'General Office Report',
    recipient: 'The Officer Concerned',
    subject: (file) => 'Report in connection with ${file.displayTitle}',
    body: (officer, file) => '''Most respectfully I beg to submit the following report in connection with ${officer.policeStation} Case No. ${file.psCaseNo} dated ${file.caseDate} u/s ${file.sections}.\n\nBrief fact: ${file.firGist}\n\nAction taken:\n1. \n2. \n3. \n\nPresent status:\n\nPrayer / further action required:\n\nSubmitted for favour of kind information and necessary action.''',
  ),
];
