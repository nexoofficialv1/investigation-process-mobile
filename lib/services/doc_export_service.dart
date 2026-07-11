import 'dart:convert';
import 'dart:typed_data';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../models/sketch_map.dart';
import '../models/statement_entry.dart';

class DocExportService {
  Uint8List _docBytes(String html) => Uint8List.fromList(utf8.encode(html));

  String _e(String value) => const HtmlEscape().convert(value).replaceAll('\n', '<br/>');

  String _page(String title, String body) => '''
<html>
<head>
<meta charset="utf-8">
<title>${_e(title)}</title>
<style>
  @page { size: A4; margin: 18mm 14mm 18mm 14mm; }
  body { font-family: "Times New Roman", serif; font-size: 12pt; color: #000; }
  table { border-collapse: collapse; width: 100%; }
  td, th { border: 1px solid #555; padding: 4px; vertical-align: top; }
  .center { text-align: center; }
  .right { text-align: right; }
  .bold { font-weight: bold; }
  .small { font-size: 10.5pt; }
  .cd td { font-size: 10.5pt; }
  .no-border td, .no-border th { border: none; }
  .justify { text-align: justify; }
  .page-break { page-break-before: always; }
</style>
</head>
<body>$body</body>
</html>
''';

  Future<Uint8List> buildCaseDiaryDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
  }) async {
    final lines = cd.tableLines.isNotEmpty
        ? cd.tableLines
        : [CdTableLine(noAndHour: 'I\n${cd.startTime}', placeOfEntry: cd.placeOfEntry, synopsis: cd.cdNumber == 1 ? 'Received copy of FIR\n+\nGist' : 'Further investigation', proceedings: cd.body)];
    final noHour = lines.map((e) => _e(e.noAndHour)).join('<br/><br/><br/>');
    final places = lines.map((e) => _e(e.placeOfEntry)).join('<br/><br/><br/>');
    final synopsis = lines.map((e) => _e(e.synopsis)).join('<br/><br/><br/>');
    final proceedings = lines.map((e) => '<p>${_e(e.proceedings)}</p>').join('');
    final year = DateTime.now().year;
    final ps = officer.policeStation.replaceAll('Police Station', 'PS').trim();
    final html = '''
<div class="bold">
  <span>West Bengal form No. 5363</span><span style="float:right">OF $year</span>
</div>
<div class="center bold">CASE DIARY UNDER SECTION 192 BNSS</div>
<div class="center bold">(P.R.B FROM NO. 43 – Vide <i>Rule 229</i>)</div>
<table class="no-border small">
<tr><td class="bold">Police Station: -${_e(ps)}</td><td class="bold right">District: -${_e(officer.district)}</td></tr>
<tr><td class="bold">First information No: -${_e(caseFile.psCaseNo)}</td><td class="bold">Dated: -${_e(caseFile.caseDate)} &nbsp;&nbsp;&nbsp; Section: -${_e(caseFile.sections)}</td></tr>
<tr><td colspan="2" class="bold">Name of Complainant: - ${_e(caseFile.complainantName)}</td></tr>
<tr><td class="bold">Case Diary No: -${cd.cdNumber}</td><td class="bold">Dated: -${_e(cd.cdDate)}</td></tr>
</table>
<table class="cd">
<tr><td class="center">Arrested and sent up</td><td class="center">Arrested and released on bail.</td><td class="center" colspan="2">At large.</td></tr>
<tr><td colspan="4" class="bold">Particulars of Enquiry.</td></tr>
<tr><td class="center" style="width:10%">No. and<br/>hour of<br/>entry.</td><td class="center" style="width:10%">Place of<br/>entry.</td><td class="center" style="width:13%">Synopsis of<br/>entry.</td><td style="width:67%"></td></tr>
<tr><td class="center">$noHour</td><td class="center">$places</td><td class="center">$synopsis</td><td class="justify">$proceedings</td></tr>
</table>
<div class="right" style="margin-top:18px;margin-right:70px">Submitted<br/><br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(ps)}</div>
''';
    return _docBytes(_page('CD-${cd.cdNumber}', html));
  }

  Future<Uint8List> buildStatementDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required StatementEntry statement,
  }) async {
    final html = '''
<div class="center bold">Statement of witness recorded u/s 180 BNSS</div><br/>
<p>Case Reference: ${_e(officer.policeStation)} PS Case No. ${_e(caseFile.psCaseNo)} dated ${_e(caseFile.caseDate)} u/s ${_e(caseFile.sections)}</p>
<p>Name of Witness: ${_e(statement.witnessName)}<br/>Witness Details: ${_e(statement.witnessDetails)}<br/>Statement Type: ${_e(statement.statementType)}</p>
<p class="justify">${_e(statement.body)}</p>
<table class="no-border" style="margin-top:40px"><tr><td>Signature/LTI/RTI of witness</td><td class="right">Recorded by<br/><br/>${_e(officer.rank)} ${_e(officer.name)}<br/>${_e(officer.policeStation)}</td></tr></table>
''';
    return _docBytes(_page('Statement', html));
  }

  Future<Uint8List> buildFormNoticeDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required FormNotice form,
  }) async {
    final html = '''
<div class="center bold">${_e(form.title)}</div><br/>
<p class="small">Ref: ${_e(officer.policeStation)} Case No. ${_e(caseFile.psCaseNo)} dated ${_e(caseFile.caseDate)} u/s ${_e(caseFile.sections)}</p>
<p class="justify">${_e(form.body)}</p>
<div class="right" style="margin-top:36px">Submitted,<br/><br/>${_e(officer.name)}<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}, ${_e(officer.district)}</div>
''';
    return _docBytes(_page(form.title, html));
  }

  Future<Uint8List> buildGeneralReportDoc({
    required OfficerProfile officer,
    required FormNotice form,
  }) async {
    final html = '''
<div class="center bold">${_e(form.title)}</div><br/>
<p class="justify">${_e(form.body)}</p>
<div class="right" style="margin-top:36px">${_e(officer.rank)} ${_e(officer.name)}<br/>${_e(officer.policeStation)}<br/>District: ${_e(officer.district)}</div>
''';
    return _docBytes(_page(form.title, html));
  }

  Future<Uint8List> buildSketchMapDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required SketchMapEntry sketch,
  }) async {
    final rows = sketch.objects.map((o) => '<tr><td>${_e(o.marker)}</td><td>${_e(o.label)}</td><td>${_e(o.direction)}</td><td>${_e(o.indexDescription)}</td></tr>').join();
    final html = '''
<div class="center bold">ROUGH SKETCH MAP WITH INDEX</div>
<p>Case Reference: ${_e(officer.policeStation)} PS Case No. ${_e(caseFile.psCaseNo)} dated ${_e(caseFile.caseDate)} u/s ${_e(caseFile.sections)}</p>
<p>PO: ${_e(sketch.poDescription)}</p>
<table><tr><th>Marker</th><th>Label</th><th>Direction</th><th>Index Description</th></tr>$rows</table>
<p>North: ${_e(sketch.north)}<br/>South: ${_e(sketch.south)}<br/>East: ${_e(sketch.east)}<br/>West: ${_e(sketch.west)}</p>
<div class="right" style="margin-top:36px">Prepared by<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}</div>
''';
    return _docBytes(_page('Sketch Map', html));
  }
}
