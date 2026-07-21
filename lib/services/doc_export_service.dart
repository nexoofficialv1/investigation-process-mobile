import 'dart:convert';
import 'dart:typed_data';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../models/sketch_map.dart';
import '../models/statement_entry.dart';
import '../models/ud_case.dart';

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
        : [CdTableLine(noAndHour: '১\n${cd.startTime}', placeOfEntry: cd.placeOfEntry, synopsis: cd.cdNumber == 1 ? 'এফআইআরের অনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা' : 'পরবর্তী তদন্ত', proceedings: cd.body)];
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
<tr><td class="bold">PS: -${_e(ps)}</td><td class="bold right">District: -${_e(officer.district)}</td></tr>
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
    return _docBytes(_page('কেস ডায়েরি-${cd.cdNumber}', html));
  }


  Future<Uint8List> buildCaseDiaryBundleDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required List<CdEntry> cds,
  }) async {
    final sortedCds = [...cds]..sort((a, b) => a.cdNumber.compareTo(b.cdNumber));
    final sections = <String>[];
    for (final cd in sortedCds) {
      final lines = cd.tableLines.isNotEmpty
          ? cd.tableLines
          : [CdTableLine(noAndHour: '১\n${cd.startTime}', placeOfEntry: cd.placeOfEntry, synopsis: cd.cdNumber == 1 ? 'এফআইআরের অনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা' : 'পরবর্তী তদন্ত', proceedings: cd.body)];
      final noHour = lines.map((e) => _e(e.noAndHour)).join('<br/><br/><br/>');
      final places = lines.map((e) => _e(e.placeOfEntry)).join('<br/><br/><br/>');
      final synopsis = lines.map((e) => _e(e.synopsis)).join('<br/><br/><br/>');
      final proceedings = lines.map((e) => '<p>${_e(e.proceedings)}</p>').join('');
      final year = DateTime.now().year;
      final ps = officer.policeStation.replaceAll('Police Station', 'PS').trim();
      final pageBreak = sections.isEmpty ? '' : 'page-break';
      sections.add('''
<div class="$pageBreak">
<div class="bold"><span>West Bengal form No. 5363</span><span style="float:right">OF $year</span></div>
<div class="center bold">CASE DIARY UNDER SECTION 192 BNSS</div>
<div class="center bold">(P.R.B FROM NO. 43 - Vide <i>Rule 229</i>)</div>
<table class="no-border small">
<tr><td class="bold">PS: -${_e(ps)}</td><td class="bold right">District: -${_e(officer.district)}</td></tr>
<tr><td class="bold">First information No: -${_e(caseFile.psCaseNo)}</td><td class="bold">Dated: -${_e(caseFile.caseDate)} &nbsp;&nbsp;&nbsp; Section: -${_e(caseFile.sections)}</td></tr>
<tr><td colspan="2" class="bold">Name of Complainant: - ${_e(caseFile.complainantName)}</td></tr>
<tr><td class="bold">Case Diary No: -${cd.cdNumber}</td><td class="bold">Dated: -${_e(cd.cdDate)}</td></tr>
</table>
<table class="cd">
<tr><td class="center">Arrested and sent up</td><td class="center">Arrested and released on bail.</td><td class="center" colspan="2">At large.</td></tr>
<tr><td colspan="3" class="bold">Particulars of Enquiry.</td><td></td></tr>
<tr><td class="center" style="width:10%">No. and<br/>hour of<br/>entry.</td><td class="center" style="width:10%">Place of<br/>entry.</td><td class="center" style="width:13%">Synopsis of<br/>entry.</td><td style="width:67%"></td></tr>
<tr><td class="center">$noHour</td><td class="center">$places</td><td class="center">$synopsis</td><td class="justify">$proceedings</td></tr>
</table>
<div class="right" style="margin-top:18px;margin-right:70px">Submitted<br/><br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(ps)}</div>
</div>
''');
    }
    return _docBytes(_page('CD 1 to 5 Bundle', sections.join('\n')));
  }

  Future<Uint8List> buildStatementDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required StatementEntry statement,
  }) async {
    final html = '''
<div class="center bold">বিএনএসএস-এর ১৮০ ধারায় লিপিবদ্ধ সাক্ষীর বিবৃতি</div><br/>
<p>মামলার রেফারেন্স: ${_e(officer.policeStation)} থানা মামলা নং ${_e(caseFile.psCaseNo)}, তারিখ ${_e(caseFile.caseDate)}, ধারা ${_e(caseFile.sections)}</p>
<p>সাক্ষীর নাম: ${_e(statement.witnessName)}<br/>সাক্ষীর বিবরণ: ${_e(statement.witnessDetails)}<br/>বিবৃতির ধরন: ${_e(statement.statementType)}</p>
<p class="justify">${_e(statement.body)}</p>
<table class="no-border" style="margin-top:40px"><tr><td>সাক্ষীর স্বাক্ষর/বাম হাতের ছাপ/ডান হাতের ছাপ</td><td class="right">লিপিবদ্ধ করেছেন<br/><br/>${_e(officer.rank)} ${_e(officer.name)}<br/>${_e(officer.policeStation)}</td></tr></table>
''';
    return _docBytes(_page('সাক্ষীর বিবৃতি', html));
  }

  Future<Uint8List> buildFormNoticeDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required FormNotice form,
  }) async {
    final html = '''
<div class="center bold">${_e(form.title)}</div><br/>
<p class="small">রেফারেন্স: ${_e(officer.policeStation)} থানা মামলা নং ${_e(caseFile.psCaseNo)}, তারিখ ${_e(caseFile.caseDate)}, ধারা ${_e(caseFile.sections)}</p>
<p class="justify">${_e(form.body)}</p>
<div class="right" style="margin-top:36px">পেশ করা হলো,<br/><br/>${_e(officer.name)}<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}, ${_e(officer.district)}</div>
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
<div class="right" style="margin-top:36px">${_e(officer.rank)} ${_e(officer.name)}<br/>${_e(officer.policeStation)}<br/>জেলা: ${_e(officer.district)}</div>
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
<div class="center bold">সূচিসহ ঘটনাস্থলের খসড়া নকশা</div>
<p>মামলার রেফারেন্স: ${_e(officer.policeStation)} থানা মামলা নং ${_e(caseFile.psCaseNo)}, তারিখ ${_e(caseFile.caseDate)}, ধারা ${_e(caseFile.sections)}</p>
<p>ঘটনাস্থল: ${_e(sketch.poDescription)}</p>
<table><tr><th>চিহ্ন</th><th>নাম</th><th>দিক</th><th>সূচির বিবরণ</th></tr>$rows</table>
<p>উত্তর: ${_e(sketch.north)}<br/>দক্ষিণ: ${_e(sketch.south)}<br/>পূর্ব: ${_e(sketch.east)}<br/>পশ্চিম: ${_e(sketch.west)}</p>
<div class="right" style="margin-top:36px">প্রস্তুত করেছেন<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}</div>
''';
    return _docBytes(_page('খসড়া নকশা', html));
  }
}

extension UdInquestDocExport on DocExportService {
  Future<Uint8List> buildUdInquestDoc({
    required OfficerProfile officer,
    required UdCase ud,
  }) async {
    String e(String v) => const HtmlEscape().convert(v).replaceAll('\n', '<br/>');
    String row(String label, String value) => '<p>$label <span style="border-bottom:1px dotted #777;display:inline-block;min-width:480px">${e(value)}</span></p>';
    final html = _page('ইউডি সুরতহাল প্রতিবেদন', '''
<div class="center bold">সুরতহাল প্রতিবেদন</div>
<div class="center bold">বিএনএসএস-এর ১৯৪/১৯৬ ধারা</div>
${row('1. District:', ud.district)}
${row('PS:', ud.policeStation)}
${row('Date & Time:', ud.dateTime)}
${row('2. FIR/UD No.:', ud.udNo)}
${row('GDE No. & Date:', ud.gdeNo)}
${row('3. a) Distance from PS:', ud.distanceFromPs)}
${row('b) Direction from PS:', ud.directionFromPs)}
${row('c) Place Where Dead Body Found:', ud.placeFound)}
${row('Longitude:', ud.longitude)} ${row('Latitude:', ud.latitude)}
${row('d) Dead body found/traced Date:', ud.deadBodyFoundDate)} ${row('Time:', ud.deadBodyFoundTime)}
${row('4. Informant’s Particulars: Name:', ud.informantName)}
${row('Age:', ud.informantAge)} ${row('Sex:', ud.informantSex)}
${row('Address:', ud.informantAddress)}
${row('5. Dead Body identified by: Name:', ud.identifiedByName)}
${row('Age:', ud.identifiedByAge)} ${row('Sex:', ud.identifiedBySex)}
${row('Relation (if any):', ud.identifiedByRelation)}
${row('Address:', ud.identifiedByAddress)}
${row('6. Name & address of deceased: Name:', ud.deceasedName)}
${row('Sex: Male/Female:', ud.deceasedSex)} ${row('Approx. Age:', ud.deceasedAge)}
${row('Address:', ud.deceasedAddress)}
${row('7. Position of dead body (including PM staining):', ud.bodyPosition)}
${row('8. Description of Dead Body Build:', ud.build)} ${row('Height:', ud.height)}
${row('(Rigor Mortis):', ud.rigorMortis)} ${row('Complexion:', ud.complexion)}
${row('Deformities, if any:', ud.deformities)} ${row('Religion/Race/Community:', ud.religionRaceCommunity)}
${row('9. Identification Mark Teeth:', ud.teeth)} ${row('Eyes:', ud.eyes)} ${row('Lace derma:', ud.laceDerma)}
${row('Mole:', ud.mole)} ${row('Tattoo:', ud.tattoo)}
${row('Dress/wearing apparel:', ud.dress)}
${row('Other features (if any):', ud.otherFeatures)}
<p>১০। মৃতদেহে পাওয়া বাহ্যিক আঘাতের বিবরণ (প্রয়োজনে পৃথক পাতা সংযুক্ত করুন)।</p>
${row('a. Head:', ud.injuryHead)} ${row('b. Face:', ud.injuryFace)} ${row('c. Neck:', ud.injuryNeck)} ${row('d. Chest:', ud.injuryChest)}
${row('e. Stomach:', ud.injuryStomach)} ${row('f. Shoulder:', ud.injuryShoulder)} ${row('g. Right Hand:', ud.injuryRightHand)}
${row('h. Left Hand:', ud.injuryLeftHand)} ${row('i. Right Leg:', ud.injuryRightLeg)} ${row('j. Left Leg:', ud.injuryLeftLeg)}
${row('k. Private parts:', ud.injuryPrivateParts)} ${row('l. Back:', ud.injuryBack)} ${row('m. Any other injury:', ud.injuryOther)}
${row('11. a. Nostrils:', ud.nostrils)} ${row('b. Ears/Eyes:', ud.earsEyes)} ${row('c. Mouth:', ud.mouth)}
${row('d. Penis/Vagina:', ud.penisVagina)} ${row('e. Anus:', ud.anus)}
${row('12. Opinion on nature of weapon used and manner in which injuries may have been caused/inflicted:', ud.weaponOpinion)}
${row('13. If death by hanging strangulation, description of ligature mark, rope & knot around the neck:', ud.ligatureDescription)}
${row('14. Foreign material:', ud.foreignMaterial)}
${row('15. Description of place of occurrence:', ud.poDescription)}
${row('16. Description of articles at the PO including weapon, ornaments etc.:', ud.articlesAtPo)}
${row('17. Opinion as to probable cause to death:', ud.probableCauseOfDeath)}
${row('18. Remarks:', ud.remarks)}
${row('19. Witness (i) Name/Address:', ud.witness1NameAddress)}
${row('Witness (ii) Name/Address:', ud.witness2NameAddress)}
<p>সংক্ষিপ্ত ঘটনা (প্রয়োজনে পৃথক পাতা সংযুক্ত করুন)</p>
<p>${e(ud.briefFacts)}</p>
<div class="right" style="margin-top:40px">তদন্তকারী অফিসারের স্বাক্ষর<br/><br/>নাম: ${e(officer.name)}<br/>পদমর্যাদা: ${e(officer.rank)}</div>
''');
    return _docBytes(html);
  }
}
