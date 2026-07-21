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
    final isEnglish = cd.languageCode == 'en';
    final lines = cd.tableLines.isNotEmpty
        ? cd.tableLines
        : [
            CdTableLine(
              noAndHour: '${isEnglish ? '1' : '১'}\n${cd.startTime}',
              placeOfEntry: cd.placeOfEntry,
              synopsis: cd.cdNumber == 1
                  ? (isEnglish
                      ? 'Receipt of FIR copy\n+\nBrief facts'
                      : 'এফআইআরের অনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা')
                  : (isEnglish ? 'Further investigation' : 'পরবর্তী তদন্ত'),
              proceedings: cd.body,
            ),
          ];
    final noHour = lines.map((e) => _e(e.noAndHour)).join('<br/><br/><br/>');
    final places =
        lines.map((e) => _e(e.placeOfEntry)).join('<br/><br/><br/>');
    final synopsis =
        lines.map((e) => _e(e.synopsis)).join('<br/><br/><br/>');
    final proceedings =
        lines.map((e) => '<p>${_e(e.proceedings)}</p>').join('');
    final year = DateTime.now().year;
    final ps = isEnglish
        ? officer.policeStation.trim()
        : officer.policeStation
            .replaceAll('Police Station', 'থানা')
            .replaceAll('P.S.', 'থানা')
            .replaceAll(' PS', ' থানা')
            .trim();

    final html = isEnglish
        ? '''
<div class="bold">
  <span>West Bengal Form No. 5363</span><span style="float:right">Year $year</span>
</div>
<div class="center bold">CASE DIARY UNDER SECTION 192 BNSS</div>
<div class="center bold">(P.R.B. Form No. 43 — See Regulation 229)</div>
<table class="no-border small">
<tr><td class="bold">Police Station: ${_e(ps)}</td><td class="bold right">District: ${_e(officer.district)}</td></tr>
<tr><td class="bold">FIR/Case No.: ${_e(caseFile.psCaseNo)}</td><td class="bold">Date: ${_e(caseFile.caseDate)} &nbsp;&nbsp;&nbsp; Sections: ${_e(caseFile.sections)}</td></tr>
<tr><td colspan="2" class="bold">Name of complainant: ${_e(caseFile.complainantName)}</td></tr>
<tr><td class="bold">Case Diary No.: ${cd.cdNumber}</td><td class="bold">Date: ${_e(cd.cdDate)}</td></tr>
</table>
<table class="cd">
<tr><td class="center">Arrested and forwarded to Court</td><td class="center">Arrested and released on bail</td><td class="center" colspan="2">Absconding/not arrested</td></tr>
<tr><td colspan="4" class="bold">Particulars of Enquiry</td></tr>
<tr><td class="center" style="width:10%">Entry No.<br/>and time</td><td class="center" style="width:10%">Place of<br/>entry</td><td class="center" style="width:13%">Synopsis of<br/>entry</td><td style="width:67%"></td></tr>
<tr><td class="center">$noHour</td><td class="center">$places</td><td class="center">$synopsis</td><td class="justify">$proceedings</td></tr>
</table>
<div class="right" style="margin-top:18px;margin-right:70px">Submitted<br/><br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(ps)}</div>
'''
        : '''
<div class="bold">
  <span>পশ্চিমবঙ্গ ফর্ম নং ৫৩৬৩</span><span style="float:right">সাল $year</span>
</div>
<div class="center bold">বিএনএসএস-এর ১৯২ ধারার অধীন কেস ডায়েরি</div>
<div class="center bold">(পি.আর.বি. ফর্ম নং ৪৩ — বিধি ২২৯ দ্রষ্টব্য)</div>
<table class="no-border small">
<tr><td class="bold">থানা: ${_e(ps)}</td><td class="bold right">জেলা: ${_e(officer.district)}</td></tr>
<tr><td class="bold">প্রথম তথ্য/মামলা নং: ${_e(caseFile.psCaseNo)}</td><td class="bold">তারিখ: ${_e(caseFile.caseDate)} &nbsp;&nbsp;&nbsp; ধারা: ${_e(caseFile.sections)}</td></tr>
<tr><td colspan="2" class="bold">অভিযোগকারীর নাম: ${_e(caseFile.complainantName)}</td></tr>
<tr><td class="bold">কেস ডায়েরি নং: ${cd.cdNumber}</td><td class="bold">তারিখ: ${_e(cd.cdDate)}</td></tr>
</table>
<table class="cd">
<tr><td class="center">গ্রেপ্তার করে আদালতে প্রেরিত</td><td class="center">গ্রেপ্তার করে জামিনে মুক্ত</td><td class="center" colspan="2">পলাতক/ধরা যায়নি</td></tr>
<tr><td colspan="4" class="bold">তদন্তের বিবরণ</td></tr>
<tr><td class="center" style="width:10%">এন্ট্রি নং<br/>ও সময়</td><td class="center" style="width:10%">এন্ট্রির<br/>স্থান</td><td class="center" style="width:13%">এন্ট্রির<br/>সারাংশ</td><td style="width:67%"></td></tr>
<tr><td class="center">$noHour</td><td class="center">$places</td><td class="center">$synopsis</td><td class="justify">$proceedings</td></tr>
</table>
<div class="right" style="margin-top:18px;margin-right:70px">পেশ করা হলো<br/><br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(ps)}</div>
''';
    return _docBytes(
      _page(
        isEnglish ? 'Case Diary-${cd.cdNumber}' : 'কেস ডায়েরি-${cd.cdNumber}',
        html,
      ),
    );
  }

  
  Future<Uint8List> buildCaseDiaryBundleDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required List<CdEntry> cds,
  }) async {
    final sortedCds = List<CdEntry>.from(cds)
      ..sort((a, b) => a.cdNumber.compareTo(b.cdNumber));

    final sections = <String>[];

    for (var index = 0; index < sortedCds.length; index++) {
      final cd = sortedCds[index];
      final isEnglish = cd.languageCode == 'en';

      final lines = cd.tableLines.isNotEmpty
          ? cd.tableLines
          : <CdTableLine>[
              CdTableLine(
                noAndHour: '${isEnglish ? '1' : '১'}\n${cd.startTime}',
                placeOfEntry: cd.placeOfEntry,
                synopsis: cd.cdNumber == 1
                    ? (isEnglish
                        ? 'Receipt of FIR copy\n+\nBrief facts'
                        : 'এফআইআরের অনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা')
                    : (isEnglish
                        ? 'Further investigation'
                        : 'পরবর্তী তদন্ত'),
                proceedings: cd.body,
              ),
            ];

      final rows = lines.map((line) => '''
<tr>
  <td>${_e(line.noAndHour)}</td>
  <td>${_e(line.placeOfEntry)}</td>
  <td>${_e(line.synopsis)}</td>
  <td>${_e(line.proceedings)}</td>
</tr>
''').join('\n');

      final pageBreak =
          index == 0 ? '' : 'style="page-break-before: always;"';

      final heading = isEnglish
          ? 'CASE DIARY UNDER SECTION 192 BNSS'
          : 'বিএনএসএস-এর ১৯২ ধারার অধীন কেস ডায়েরি';
      final policeStationLabel = isEnglish ? 'Police Station' : 'থানা';
      final districtLabel = isEnglish ? 'District' : 'জেলা';
      final caseLabel = isEnglish ? 'FIR/Case No.' : 'প্রথম তথ্য/মামলা নং';
      final dateLabel = isEnglish ? 'Date' : 'তারিখ';
      final sectionsLabel = isEnglish ? 'Sections' : 'ধারা';
      final complainantLabel =
          isEnglish ? 'Name of complainant' : 'অভিযোগকারীর নাম';
      final cdLabel = isEnglish ? 'Case Diary No.' : 'কেস ডায়েরি নং';
      final entryLabel =
          isEnglish ? 'Entry No. and time' : 'এন্ট্রি নং ও সময়';
      final placeLabel = isEnglish ? 'Place of entry' : 'এন্ট্রির স্থান';
      final synopsisLabel =
          isEnglish ? 'Synopsis of entry' : 'এন্ট্রির সারাংশ';
      final detailsLabel =
          isEnglish ? 'Particulars of enquiry' : 'তদন্তের বিবরণ';
      final submitted = isEnglish ? 'Submitted' : 'পেশ করা হলো';

      sections.add('''
<section $pageBreak>
  <h2>$heading</h2>
  <p>
    <b>$policeStationLabel:</b> ${_e(officer.policeStation)}
    &nbsp;&nbsp;
    <b>$districtLabel:</b> ${_e(officer.district)}
  </p>
  <p>
    <b>$caseLabel:</b> ${_e(caseFile.psCaseNo)}
    &nbsp;&nbsp;
    <b>$dateLabel:</b> ${_e(caseFile.caseDate)}
    &nbsp;&nbsp;
    <b>$sectionsLabel:</b> ${_e(caseFile.sections)}
  </p>
  <p><b>$complainantLabel:</b> ${_e(caseFile.complainantName)}</p>
  <p>
    <b>$cdLabel:</b> ${cd.cdNumber}
    &nbsp;&nbsp;
    <b>$dateLabel:</b> ${_e(cd.cdDate)}
  </p>
  <table border="1" cellspacing="0" cellpadding="6"
         style="width:100%; border-collapse:collapse;">
    <tr>
      <th>$entryLabel</th>
      <th>$placeLabel</th>
      <th>$synopsisLabel</th>
      <th>$detailsLabel</th>
    </tr>
    $rows
  </table>
  <p style="text-align:right;">
    $submitted<br>
    (${_e(officer.name)})<br>
    ${_e(officer.rank)}<br>
    ${_e(officer.policeStation)}
  </p>
</section>
''');
    }

    final allEnglish = sortedCds.isNotEmpty &&
        sortedCds.every((cd) => cd.languageCode == 'en');
    final title = allEnglish ? 'Case Diary Bundle' : 'কেস ডায়েরি সমষ্টি';

    return _docBytes(_page(title, sections.join('\n')));
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
    final isEnglish = form.languageCode == 'en';
    final reference = isEnglish
        ? 'Reference: ${_e(officer.policeStation)} Case No. ${_e(caseFile.psCaseNo)} dated ${_e(caseFile.caseDate)}, U/S ${_e(caseFile.sections)}'
        : 'মামলার সূত্র: ${_e(officer.policeStation)} থানা মামলা নং ${_e(caseFile.psCaseNo)}, তারিখ ${_e(caseFile.caseDate)}, ধারা ${_e(caseFile.sections)}';
    final submitted = isEnglish ? 'Submitted by,' : 'নিবেদক,';
    final mobile = officer.mobile.trim().isEmpty
        ? ''
        : '<br/>${isEnglish ? 'Mobile' : 'মোবাইল'}: ${_e(officer.mobile)}';
    final html = '''
<div class="center bold">${_e(form.title)}</div><br/>
<p class="small">$reference</p>
<p class="justify">${_e(form.body)}</p>
<div class="right" style="margin-top:36px">$submitted<br/><br/>${_e(officer.name)}<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}, ${_e(officer.district)}$mobile</div>
''';
    return _docBytes(_page(form.title, html));
  }

  Future<Uint8List> buildGeneralReportDoc({
    required OfficerProfile officer,
    required FormNotice form,
  }) async {
    final isEnglish = form.languageCode == 'en';
    final html = '''
<div class="center bold">${_e(form.title)}</div><br/>
<p class="justify">${_e(form.body)}</p>
<div class="right" style="margin-top:36px">${_e(officer.rank)} ${_e(officer.name)}<br/>${_e(officer.policeStation)}<br/>${isEnglish ? 'District' : 'জেলা'}: ${_e(officer.district)}</div>
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
