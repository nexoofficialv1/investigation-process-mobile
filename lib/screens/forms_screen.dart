import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/forms_generator_service.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _store.loadForms(widget.caseFile.id);
    if (!mounted) return;
    setState(() => forms = list);
  }

  Future<void> _create(FormTemplateInfo template) async {
    final body = _generator.generate(templateId: template.id, officer: widget.profile, caseFile: widget.caseFile);
    final form = FormNotice.create(
      caseId: widget.caseFile.id,
      templateId: template.id,
      title: template.title,
      body: body,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormEditorScreen(profile: widget.profile, caseFile: widget.caseFile, form: form)),
    );
    await _load();
  }

  Future<void> _open(FormNotice form) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormEditorScreen(profile: widget.profile, caseFile: widget.caseFile, form: form)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forms & Notices')),
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
                    Text('Auto-fill Forms', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('${widget.caseFile.displayTitle}\nSections: ${widget.caseFile.sections}\nIO: ${widget.profile.rank} ${widget.profile.name}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Generate New', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
            Text('Saved Forms', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (forms.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No saved forms yet. Select a template above.')))
            else
              ...forms.map((form) => Card(
                    child: ListTile(
                      leading: Icon(form.isFinal ? Icons.lock : Icons.description),
                      title: Text(form.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(form.isFinal ? 'Final saved' : 'Draft'),
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

  @override
  void initState() {
    super.initState();
    _form = widget.form;
    title = TextEditingController(text: _form.title);
    body = TextEditingController(text: _form.body);
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  FormNotice _currentForm({bool? finalSave}) => _form.copyWith(
        title: title.text.trim(),
        body: body.text.trim(),
        isFinal: finalSave == true ? true : _form.isFinal,
      );

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
      return 'Submitted prayer before the Ld. Court for recording statement u/s 183 BNSS in connection with this case.';
    }
    if (lower.contains('35')) {
      return 'Prepared/served notice u/s 35(3) BNSS upon the concerned person in connection with this case.';
    }
    if (lower.contains('94')) {
      return 'Sent requisition u/s 94 BNSS for collection/production of relevant document/material in connection with this case.';
    }
    if (lower.contains('medical')) {
      return 'Sent medical requisition for examination/collection of medical papers in connection with this case.';
    }
    if (lower.contains('bht') || lower.contains('injury')) {
      return 'Sent requisition for collection of BHT/injury report in connection with this case.';
    }
    if (lower.contains('cdr') || lower.contains('caf')) {
      return 'Sent requisition for collection of CDR/CAF in connection with this case.';
    }
    if (lower.contains('bank')) {
      return 'Sent requisition to the concerned bank/authority for collection of account/transaction details in connection with this case.';
    }
    if (lower.contains('fsl')) {
      return 'Sent requisition for FSL/scientific examination in connection with this case.';
    }
    if (lower.contains('forwarding')) {
      return 'Prepared forwarding report/prayer in connection with this case.';
    }
    return 'Prepared ${form.title} in connection with this case.';
  }

  Future<void> _askMentionInCaseDiary(FormNotice form) async {
    if (!mounted) return;
    final mention = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mention in Case Diary?'),
        content: Text('“${form.title}” CD-তে mention করা হবে? Yes করলে date-wise pending CD entry হিসেবে save হবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CD pending entry saved. Daily CD builder-এ দেখা যাবে.')));
  }

  Future<void> _previewPdf() async {
    final previewForm = await _save(askCdMention: false);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Preview ${previewForm.title}',
          filename: '${previewForm.title.replaceAll(' ', '_')}_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.pdf',
          buildPdf: () => PdfService().buildFormNoticePdf(officer: widget.profile, caseFile: widget.caseFile, form: previewForm),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
              Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save), label: const Text('Draft'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _finalSave, icon: const Icon(Icons.lock), label: const Text('Final'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _previewPdf, icon: const Icon(Icons.preview), label: const Text('Preview'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_form.isFinal)
            const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('This form is final saved. Edit carefully if required.', style: TextStyle(fontWeight: FontWeight.bold)))),
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
