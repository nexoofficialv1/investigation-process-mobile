import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../models/officer_profile.dart';
import '../models/ud_case.dart';
import '../services/doc_export_service.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../services/ud_official_documents_service.dart';

class UdCaseScreen extends StatefulWidget {
  final OfficerProfile profile;
  const UdCaseScreen({super.key, required this.profile});

  @override
  State<UdCaseScreen> createState() => _UdCaseScreenState();
}

class _UdCaseScreenState extends State<UdCaseScreen> {
  final _store = LocalStoreService();
  final _pdf = PdfService();
  final _doc = DocExportService();
  final _udDocs = UdOfficialDocumentsService();
  final Map<String, TextEditingController> _c = {};
  List<UdCase> _saved = [];
  UdCase _ud = UdCase.empty();
  String _injuryPart = 'injuryHead';
  String _dischargePart = 'nostrils';

  static const Map<String, String> _injuryOptions = {
    'injuryHead': 'Head',
    'injuryFace': 'Face',
    'injuryNeck': 'Neck',
    'injuryChest': 'Chest',
    'injuryStomach': 'Stomach',
    'injuryShoulder': 'Shoulder',
    'injuryRightHand': 'Right Hand',
    'injuryLeftHand': 'Left Hand',
    'injuryRightLeg': 'Right Leg',
    'injuryLeftLeg': 'Left Leg',
    'injuryPrivateParts': 'Private parts',
    'injuryBack': 'Back',
    'injuryOther': 'Any other injury',
  };

  static const Map<String, String> _dischargeOptions = {
    'nostrils': 'Nostrils',
    'earsEyes': 'Ears / Eyes',
    'mouth': 'Mouth',
    'penisVagina': 'Penis/Vagina',
    'anus': 'Anus',
  };

  final List<_F> _fields = const [
    _F('district', 'District'),
    _F('policeStation', 'PS'),
    _F('udNo', 'FIR/UD No.'),
    _F('gdeNo', 'GDE No. & Date'),
    _F('dateTime', 'Date & Time'),
    _F('distanceFromPs', 'Distance from PS'),
    _F('directionFromPs', 'Direction from PS'),
    _F('placeFound', 'Place where dead body found'),
    _F('longitude', 'Longitude'),
    _F('latitude', 'Latitude'),
    _F('deadBodyFoundDate', 'Dead body found/traced Date'),
    _F('deadBodyFoundTime', 'Dead body found/traced Time'),
    _F('informantName', 'Informant Name'),
    _F('informantAge', 'Informant Age'),
    _F('informantSex', 'Informant Sex'),
    _F('informantAddress', 'Informant Address', lines: 2),
    _F('identifiedByName', 'Dead Body identified by Name'),
    _F('identifiedByAge', 'Identifier Age'),
    _F('identifiedBySex', 'Identifier Sex'),
    _F('identifiedByRelation', 'Relation, if any'),
    _F('identifiedByAddress', 'Identifier Address', lines: 2),
    _F('deceasedName', 'Name of deceased'),
    _F('deceasedSex', 'Sex: Male/Female'),
    _F('deceasedAge', 'Approx. Age'),
    _F('deceasedAddress', 'Deceased Address', lines: 2),
    _F('bodyPosition', 'Position of dead body including PM staining', lines: 3),
    _F('build', 'Build'),
    _F('height', 'Height'),
    _F('rigorMortis', 'Rigor Mortis'),
    _F('complexion', 'Complexion'),
    _F('deformities', 'Deformities, if any'),
    _F('religionRaceCommunity', 'Religion/Race/Community'),
    _F('teeth', 'Identification mark: Teeth'),
    _F('eyes', 'Eyes'),
    _F('laceDerma', 'Lace derma'),
    _F('mole', 'Mole'),
    _F('tattoo', 'Tattoo'),
    _F('dress', 'Dress/wearing apparel', lines: 2),
    _F('otherFeatures', 'Other features, if any', lines: 2),
    _F('weaponOpinion', 'Opinion on nature of weapon/injury manner', lines: 3),
    _F('ligatureDescription', 'Ligature mark / rope / knot description', lines: 3),
    _F('foreignMaterial', 'Foreign material found on body', lines: 3),
    _F('poDescription', 'Description of place of occurrence', lines: 3),
    _F('articlesAtPo', 'Articles at PO including weapon/ornaments', lines: 3),
    _F('probableCauseOfDeath', 'Probable cause of death', lines: 2),
    _F('remarks', 'Remarks', lines: 3),
    _F('witness1NameAddress', 'Witness (i) Name/Address', lines: 2),
    _F('witness2NameAddress', 'Witness (ii) Name/Address', lines: 2),
    _F('briefFacts', 'Brief facts', lines: 5),
  ];

  final List<_F> _surathalFields = const [
    _F('inquestFromTime', 'Inquest Time From'),
    _F('inquestToTime', 'Inquest Time To'),
    _F('morgueOrPlace', 'Morgue / place where Surathal prepared', lines: 2),
    _F('escortConstable', 'Escort / accompanying constable'),
    _F('bodyOrientation', 'Body orientation / position in morgue', lines: 2),
    _F('weight', 'Approx. weight'),
    _F('eyeState', 'Eyes condition'),
    _F('mouthState', 'Mouth condition'),
    _F('noseCondition', 'Nose condition'),
    _F('earCondition', 'Ear condition'),
    _F('hairDescription', 'Hair description'),
    _F('beardDescription', 'Beard description'),
    _F('moustacheDescription', 'Moustache description'),
    _F('handsFingers', 'Hands / fingers'),
    _F('legsDescription', 'Legs'),
    _F('nailsDescription', 'Nails'),
    _F('domGender', 'Dom: মহিলা/পুরুষ'),
    _F('nearRelativeVersion', 'Near-relative / witness version for Surathal', lines: 5),
    _F('pmMorgueName', 'PM Morgue / hospital name', lines: 2),
    _F('handoverTo', 'After PM body handover to'),
    _F('preparedDate', 'Prepared Date'),
  ];

  final List<_F> _challanFields = const [
    _F('challanRef', 'Challan Ref, if different'),
    _F('deceasedCaste', 'Caste / religion text for challan'),
    _F('challanResidence', 'Residence for challan', lines: 2),
    _F('bodyFoundPlaceChallan', 'Where dead body was found', lines: 2),
    _F('dispatchDateHourDistance', 'Date/hour of dispatch and distance from PM place', lines: 2),
    _F('dispatchMeans', 'Means of Dispatch', lines: 3),
    _F('identifyingPoliceOfficer', 'Name of identifying police officer'),
    _F('marksOnBody', 'Marks on the body'),
    _F('causeOfDeathKnown', 'Cause of death as far as known'),
    _F('challanRemarksArticles', 'Remarks / clothes / articles / viscera preservation', lines: 4),
  ];

  final List<_F> _finalReportFields = const [
    _F('firstInformationDetails', '1. Station, number and date of first information', lines: 2),
    _F('spotVisitDateHour', '3. Date and hour of going to the spot'),
    _F('finalReportDispatchDateHour', '4. Date and hour of dispatch of final report'),
    _F('finalReportNarrative', 'UD Final Report facts / enquiry narrative', lines: 8),
    _F('pmReportDetails', 'PM report details / PM No. / date', lines: 2),
    _F('pmDoctorOpinion', 'Doctor opinion / cause of death', lines: 3),
    _F('finalFinding', 'Final finding / no foul play paragraph', lines: 3),
    _F('finalPrayer', 'Final prayer', lines: 3),
  ];

  List<_F> get _allFields => [..._fields, ..._surathalFields, ..._challanFields, ..._finalReportFields];

  @override
  void initState() {
    super.initState();
    _ud = UdCase.empty(ps: widget.profile.policeStation, district: widget.profile.district);
    _initControllers();
    _loadSaved();
  }

  void _initControllers() {
    final map = _ud.toJson();
    for (final f in _allFields) {
      _c[f.key] = TextEditingController(text: (map[f.key] ?? '').toString());
    }
    for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys]) {
      _c[key] = TextEditingController(text: (map[key] ?? '').toString());
    }
  }

  Future<void> _loadSaved() async {
    final list = await _store.loadUdCases();
    if (!mounted) return;
    setState(() => _saved = list);
  }

  UdCase _collect() {
    final values = {
      for (final f in _allFields) f.key: _c[f.key]!.text.trim(),
      for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys]) key: _c[key]!.text.trim(),
    };
    return _ud.copyWith(values);
  }

  Future<void> _save() async {
    _ud = _collect();
    await _store.saveUdCase(_ud);
    await _loadSaved();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UD draft saved')));
  }

  Future<void> _previewPdf(Future<Uint8List> Function() builder) async {
    _ud = _collect();
    final bytes = await builder();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _sharePdf(String prefix, Future<Uint8List> Function() builder) async {
    _ud = _collect();
    final bytes = await builder();
    await Printing.sharePdf(bytes: bytes, filename: '${prefix}_${_fileSafe(_ud.udNo)}.pdf');
  }

  Future<void> _shareDoc(String prefix, Future<Uint8List> Function() builder) async {
    _ud = _collect();
    final bytes = await builder();
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${prefix}_${_fileSafe(_ud.udNo)}.doc';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(path)], text: prefix.replaceAll('_', ' '));
  }

  String _fileSafe(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_');
    return cleaned.isEmpty ? 'UD_Draft' : cleaned;
  }

  Future<void> _previewInquest() => _previewPdf(() => _pdf.buildUdInquestPdf(officer: widget.profile, ud: _ud));
  Future<void> _exportInquestPdf() => _sharePdf('UD_Inquest', () => _pdf.buildUdInquestPdf(officer: widget.profile, ud: _ud));
  Future<void> _exportInquestDoc() => _shareDoc('UD_Inquest', () => _doc.buildUdInquestDoc(officer: widget.profile, ud: _ud));

  Future<void> _previewSurathal() => _previewPdf(() => _udDocs.buildSurathalReportPdf(officer: widget.profile, ud: _ud));
  Future<void> _exportSurathalPdf() => _sharePdf('Surathal_Report', () => _udDocs.buildSurathalReportPdf(officer: widget.profile, ud: _ud));
  Future<void> _exportSurathalDoc() => _shareDoc('Surathal_Report', () => _udDocs.buildSurathalReportDoc(officer: widget.profile, ud: _ud));

  Future<void> _previewChallan() => _previewPdf(() => _udDocs.buildDeadBodyChallanPdf(officer: widget.profile, ud: _ud));
  Future<void> _exportChallanPdf() => _sharePdf('Dead_Body_Challan', () => _udDocs.buildDeadBodyChallanPdf(officer: widget.profile, ud: _ud));
  Future<void> _exportChallanDoc() => _shareDoc('Dead_Body_Challan', () => _udDocs.buildDeadBodyChallanDoc(officer: widget.profile, ud: _ud));

  Future<void> _previewFinalReport() => _previewPdf(() => _udDocs.buildUdFinalReportPdf(officer: widget.profile, ud: _ud));
  Future<void> _exportFinalReportPdf() => _sharePdf('UD_Final_Report', () => _udDocs.buildUdFinalReportPdf(officer: widget.profile, ud: _ud));
  Future<void> _exportFinalReportDoc() => _shareDoc('UD_Final_Report', () => _udDocs.buildUdFinalReportDoc(officer: widget.profile, ud: _ud));

  void _loadUd(UdCase ud) {
    setState(() {
      _ud = ud;
      final map = ud.toJson();
      for (final f in _allFields) {
        _c[f.key]!.text = (map[f.key] ?? '').toString();
      }
      for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys]) {
        _c[key]!.text = (map[key] ?? '').toString();
      }
    });
  }

  void _newUd() {
    setState(() {
      _ud = UdCase.empty(ps: widget.profile.policeStation, district: widget.profile.district);
      final map = _ud.toJson();
      for (final f in _allFields) {
        _c[f.key]!.text = (map[f.key] ?? '').toString();
      }
      for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys]) {
        _c[key]!.text = (map[key] ?? '').toString();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('UD Case'),
        actions: [IconButton(onPressed: _newUd, icon: const Icon(Icons.add))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_saved.isNotEmpty) _savedList(),
          _introCard(),
          _section('UD Case Entry / Inquest Form', 'Section 194 / 196 OF BNSS', _fields),
          _injuryDropdownCard(),
          _dischargeDropdownCard(),
          _actionsCard('Inquest Form', _previewInquest, _exportInquestPdf, _exportInquestDoc),
          _section('Surathal Report / সুরতহাল রিপোর্ট', 'Bengali narrative report from uploaded format', _surathalFields),
          _actionsCard('Surathal Report', _previewSurathal, _exportSurathalPdf, _exportSurathalDoc),
          _section('Dead Body Challan', 'West Bengal Form No-5371 / PRB Form No-54 vide Rule-252', _challanFields),
          _actionsCard('Dead Body Challan', _previewChallan, _exportChallanPdf, _exportChallanDoc),
          _section('UD Final Report', 'West Bengal Form No. 5370 / PRB Form No.-53 vide Rule 276', _finalReportFields),
          _actionsCard('UD Final Report', _previewFinalReport, _exportFinalReportPdf, _exportFinalReportDoc),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save UD Draft')),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _introCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('UD Case Package', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text('একই UD data থেকে Inquest, Surathal Report, Dead Body Challan এবং UD Final Report তৈরি হবে। আগে Save/Preview করে তারপর PDF/DOC export করুন।', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _section(String title, String subtitle, List<_F> fields) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: title.startsWith('UD Case Entry'),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: fields.map(_field).toList(),
      ),
    );
  }

  Widget _field(_F f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _c[f.key],
        minLines: f.lines,
        maxLines: f.lines > 1 ? f.lines + 3 : 1,
        decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
      ),
    );
  }

  Widget _actionsCard(String title, Future<void> Function() preview, Future<void> Function() exportPdf, Future<void> Function() exportDoc) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(onPressed: preview, icon: const Icon(Icons.visibility), label: const Text('Preview')),
              ElevatedButton.icon(onPressed: exportPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
              ElevatedButton.icon(onPressed: exportDoc, icon: const Icon(Icons.description), label: const Text('DOC')),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _injuryDropdownCard() {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('10. Description of external injuries found on Dead Body', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _injuryPart,
              decoration: const InputDecoration(labelText: 'Select body part', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
              items: _injuryOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _injuryPart = v ?? _injuryPart),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _c[_injuryPart],
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Entry for ${_injuryOptions[_injuryPart]}',
                helperText: 'Select body part from dropdown, then enter injury details. It will export in official Sl. No. 10 format.',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _summaryList(_injuryOptions),
          ],
        ),
      ),
    );
  }

  Widget _dischargeDropdownCard() {
    return Card(
      color: Colors.blueGrey.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('11. Discharge form', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _dischargePart,
              decoration: const InputDecoration(labelText: 'Select discharge part', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
              items: _dischargeOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _dischargePart = v ?? _dischargePart),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _c[_dischargePart],
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Entry for ${_dischargeOptions[_dischargePart]}',
                helperText: 'Select item from dropdown, then enter discharge details. It will export in official Sl. No. 11 format.',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _summaryList(_dischargeOptions),
          ],
        ),
      ),
    );
  }

  Widget _summaryList(Map<String, String> options) {
    final filled = options.entries.where((e) => (_c[e.key]?.text.trim().isNotEmpty ?? false)).toList();
    if (filled.isEmpty) {
      return const Text('No entry added yet.', style: TextStyle(fontStyle: FontStyle.italic));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filled.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('• ${e.value}: ${_c[e.key]!.text.trim()}', maxLines: 2, overflow: TextOverflow.ellipsis),
      )).toList(),
    );
  }

  Widget _savedList() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.history),
        title: const Text('Saved UD Drafts', style: TextStyle(fontWeight: FontWeight.w900)),
        children: _saved.map((ud) => ListTile(
              title: Text(ud.displayTitle),
              subtitle: Text('Deceased: ${ud.deceasedName}\nPlace: ${ud.placeFound}', maxLines: 2),
              isThreeLine: true,
              onTap: () => _loadUd(ud),
            )).toList(),
      ),
    );
  }
}

class _F {
  final String key;
  final String label;
  final int lines;
  const _F(this.key, this.label, {this.lines = 1});
}
