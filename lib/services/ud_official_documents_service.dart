import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/officer_profile.dart';
import '../models/ud_case.dart';

class UdOfficialDocumentsService {
  Future<pw.ThemeData> _theme() async {
    try {
      final regular = await PdfGoogleFonts.notoSerifBengaliRegular();
      final bold = await PdfGoogleFonts.notoSerifBengaliBold();
      return pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      final regular = await PdfGoogleFonts.notoSansBengaliRegular();
      final bold = await PdfGoogleFonts.notoSansBengaliBold();
      return pw.ThemeData.withFont(base: regular, bold: bold);
    }
  }

  String _ps(String value) => value.replaceAll('Police Station', 'PS').trim();
  String _v(String value, [String fallback = '']) => value.trim().isEmpty ? fallback : value.trim();
  String _e(String value) => const HtmlEscape().convert(value).replaceAll('\n', '<br/>');

  String _deceasedFull(UdCase ud) {
    final name = _v(ud.deceasedName, 'deceased');
    final age = ud.deceasedAge.trim().isEmpty ? '' : ', Age- ${ud.deceasedAge}';
    final sex = ud.deceasedSex.trim().isEmpty ? '' : ', ${ud.deceasedSex}';
    final address = ud.deceasedAddress.trim().isEmpty ? '' : ' of ${ud.deceasedAddress}';
    return '$name$sex$age$address';
  }

  String _physicalDescription(UdCase ud) {
    final parts = <String>[];
    void add(String label, String value) {
      if (value.trim().isNotEmpty) parts.add('$label ${value.trim()}');
    }
    add('উচ্চতা আনুমান', ud.height);
    add('ওজন আনুমানিক', ud.weight);
    add('গায়ের রঙ', ud.complexion);
    add('চোখ', _v(ud.eyeState, ud.eyes));
    add('মুখ', ud.mouthState);
    add('দাঁত', ud.teeth);
    add('নাক', ud.noseCondition);
    add('কান', ud.earCondition);
    add('চুল', ud.hairDescription);
    add('দাঁড়ি', ud.beardDescription);
    add('গোঁফ', ud.moustacheDescription);
    add('হাত ও আঙুল', ud.handsFingers);
    add('পা', ud.legsDescription);
    add('নখ', ud.nailsDescription);
    add('পরিহিত বস্ত্র', ud.dress);
    return parts.isEmpty ? ud.otherFeatures : parts.join(', ');
  }

  String _injurySummary(UdCase ud) {
    final parts = <String>[];
    void add(String label, String value) {
      if (value.trim().isNotEmpty) parts.add('$label: ${value.trim()}');
    }
    add('Head', ud.injuryHead);
    add('Face', ud.injuryFace);
    add('Neck', ud.injuryNeck);
    add('Chest', ud.injuryChest);
    add('Stomach', ud.injuryStomach);
    add('Shoulder', ud.injuryShoulder);
    add('Right Hand', ud.injuryRightHand);
    add('Left Hand', ud.injuryLeftHand);
    add('Right Leg', ud.injuryRightLeg);
    add('Left Leg', ud.injuryLeftLeg);
    add('Private parts', ud.injuryPrivateParts);
    add('Back', ud.injuryBack);
    add('Other', ud.injuryOther);
    return parts.isEmpty ? 'আপাত দৃষ্টিতে কোন চোট আঘাত বা ক্ষত চিহ্ন দেখা গেল না।' : parts.join('; ');
  }

  String _surathalBody(OfficerProfile officer, UdCase ud) {
    final ps = _ps(_v(ud.policeStation, officer.policeStation));
    final morgue = _v(ud.morgueOrPlace, 'কালনা মহকুমা হাসপাতালের পুলিশ মর্গে');
    final constable = _v(ud.escortConstable, 'কনস্টেবল ................................');
    final orientation = _v(ud.bodyOrientation, 'উত্তর দিকে মাথা ও দক্ষিণ দিকে পা করে শায়িত রয়েছে');
    final physical = _physicalDescription(ud);
    final injury = _injurySummary(ud);
    final version = _v(ud.nearRelativeVersion, ud.briefFacts);
    final pmMorgue = _v(ud.pmMorgueName, 'কালনা মহকুমা হাসপাতালের পুলিশ মর্গে');
    final handover = _v(ud.handoverTo, 'নিকট আত্মীয়ের হাতে');
    final date = _v(ud.preparedDate, ud.dateTime);
    return '''মহাশয়,
আমি ${officer.rank} ${officer.name}, বর্তমানে $ps-এ কর্মরত। থানার বড়বাবুর নির্দেশ অনুযায়ী, আজ $date তারিখে $constable-কে সঙ্গে নিয়ে $morgue উপস্থিত হয়ে মৃত/মৃতা ${_deceasedFull(ud)}-এর সুরতহাল রিপোর্ট প্রস্তুত করি। মৃতদেহটি $orientation। দেখা গেল যে $physical।
${_v(ud.domGender, 'মহিলা/পুরুষ')} ডোম দ্বারা পর্যাপ্ত আলোতে মৃতদেহটি ওলট-পালট করে দেখা যায় যে $injury
মৃত/মৃতার নিকট আত্মীয়/সাক্ষীদের বয়ান অনুযায়ী মৃত্যুর কারণ সম্বন্ধে প্রাথমিক তদন্তে জানা গেল যে $version
তথাপি মৃত/মৃতার মৃত্যুর সঠিক কারণ নির্ণয়ের হেতু মৃতদেহটি $constable মারফত প্রয়োজনীয় কাগজপত্রসহ $pmMorgue ময়নাতদন্তের জন্য প্রেরণ করা হলো। ময়নাতদন্তের পর মৃতদেহটি $handover তুলে দেওয়ার আবেদন জানাই।''';
  }

  Future<Uint8List> buildSurathalReportPdf({required OfficerProfile officer, required UdCase ud}) async {
    final doc = pw.Document(theme: await _theme());
    final ps = _ps(_v(ud.policeStation, officer.policeStation));
    final titleStyle = pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold);
    final normal = const pw.TextStyle(fontSize: 11);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 36, 42, 36),
        build: (_) => [
          pw.Text(
            'Preparing the Surathal Report of the deceased ${_deceasedFull(ud)} in c/w $ps U/D case No: - ${ud.udNo}, Date :- ${ud.dateTime}',
            style: titleStyle,
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text('Inquest Time: From ${_v(ud.inquestFromTime, '................')} To ${_v(ud.inquestToTime, '................')}', style: normal),
          pw.SizedBox(height: 14),
          pw.Text(_surathalBody(officer, ud), style: normal, textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 26),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Prepared by me', style: normal),
              pw.SizedBox(height: 18),
              pw.Text('(${officer.name})', style: normal),
              pw.Text('${officer.rank} of Police, $ps', style: normal),
              pw.Text('Date- ${_v(ud.preparedDate, ud.dateTime)}', style: normal),
            ]),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> buildDeadBodyChallanPdf({required OfficerProfile officer, required UdCase ud}) async {
    final doc = pw.Document(theme: await _theme());
    final ps = _ps(_v(ud.policeStation, officer.policeStation));
    final normal = const pw.TextStyle(fontSize: 8.4);
    final small = const pw.TextStyle(fontSize: 7.2);
    pw.Widget cell(String text, {bool bold = false, double? height}) => pw.Container(
          height: height,
          padding: const pw.EdgeInsets.all(3),
          alignment: pw.Alignment.topLeft,
          child: pw.Text(text, style: bold ? pw.TextStyle(fontSize: 8.2, fontWeight: pw.FontWeight.bold) : small),
        );
    final headers = [
      'Name and caste of deceased',
      'Sex and Age',
      'Residence',
      'Where dead body was found',
      'Date and hours of dispatch and distance from place of postmortem',
      'Means of Dispatch',
      'Name of identifying Police officer',
      'Marks on the body',
      'Cause of death as for as known',
      'Remarks, Mention what clothes articles were sent herewith the body',
    ];
    final values = [
      '${_v(ud.deceasedName)} ${ud.deceasedCaste.trim().isEmpty ? '' : '(${ud.deceasedCaste})'}',
      '${_v(ud.deceasedSex)} ${ud.deceasedAge.trim().isEmpty ? '' : ', Age- ${ud.deceasedAge}'}',
      _v(ud.challanResidence, ud.deceasedAddress),
      _v(ud.bodyFoundPlaceChallan, ud.placeFound),
      _v(ud.dispatchDateHourDistance, 'On ${_v(ud.preparedDate, ud.dateTime)} Inquest Time: From ${ud.inquestFromTime} To ${ud.inquestToTime}, ${ud.distanceFromPs}'),
      _v(ud.dispatchMeans, 'By Govt. Stretcher of Hospital / By govt. vehicle / By Hire vehicle'),
      _v(ud.identifyingPoliceOfficer, ud.escortConstable),
      _v(ud.marksOnBody, 'As per surathal-report'),
      _v(ud.causeOfDeathKnown, 'As per surathal-report'),
      _v(ud.challanRemarksArticles, '(i) Wearing appearance\n(ii) Viscera\n(iii)\n(iv)\nThis above articles may kindly be preserved.'),
    ];
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 22),
        build: (_) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('West Bengal Form No- 5371', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Ref: $ps U/D case No: - ${ud.udNo}, Date :- ${ud.dateTime}', style: normal),
          ]),
          pw.Center(child: pw.Text('Challan for use when a Dead Body is sent for examination', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
          pw.Center(child: pw.Text('(P.R.B Form No-54 vide Rule-252)', style: normal)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: .5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.15),
              1: pw.FlexColumnWidth(.75),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.05),
              4: pw.FlexColumnWidth(1.35),
              5: pw.FlexColumnWidth(1.0),
              6: pw.FlexColumnWidth(1.1),
              7: pw.FlexColumnWidth(.8),
              8: pw.FlexColumnWidth(.85),
              9: pw.FlexColumnWidth(1.45),
            },
            children: [
              pw.TableRow(children: headers.map((h) => cell(h, bold: true, height: 48)).toList()),
              pw.TableRow(children: values.map((v) => cell(v, height: 150)).toList()),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Forwarded the dead body of the deceased namely ${_deceasedFull(ud)} to ${_v(ud.pmMorgueName, 'Police Morgue')} with all connected papers through ${_v(ud.escortConstable, 'Constable')} of $ps for holding Post Mortem Examination over the dead-body of the deceased to ascertain the actual cause of death.',
            style: normal,
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Submitted –', style: normal),
              pw.SizedBox(height: 14),
              pw.Text('(${officer.name})', style: normal),
              pw.Text('${officer.rank} of Police, $ps', style: normal),
              pw.Text('Date- ${_v(ud.preparedDate, ud.dateTime)}', style: normal),
            ]),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> buildUdFinalReportPdf({required OfficerProfile officer, required UdCase ud}) async {
    final doc = pw.Document(theme: await _theme());
    final ps = _ps(_v(ud.policeStation, officer.policeStation));
    final normal = const pw.TextStyle(fontSize: 10.5);
    final bold = pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold);
    pw.Widget item(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.RichText(text: pw.TextSpan(style: normal, children: [pw.TextSpan(text: label, style: bold), pw.TextSpan(text: value)])),
        );
    final body = _v(ud.finalReportNarrative, '''The fact of the case in brief is that ${_v(ud.firstInformationDetails, 'information was received regarding the unnatural death of ${_deceasedFull(ud)}.')} On the basis of such information started $ps U/D Case No. ${ud.udNo} and investigation was taken up. Inquest report was prepared over the dead body duly identified by the near relatives/witnesses. The dead body was forwarded to police morgue for holding post mortem examination to ascertain the actual cause of death. ${_v(ud.pmReportDetails)} ${_v(ud.pmDoctorOpinion)}''');
    final finding = _v(ud.finalFinding, 'From the preliminary enquiry as well as the PM report, no foul play could be detected behind the death of the deceased.');
    final prayer = _v(ud.finalPrayer, 'Therefore, I am praying that this U/D Case may kindly be filed with a view to re-open the case if any complaint or clue comes out from any corner in near future.');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 34, 42, 36),
        build: (_) => [
          pw.Text('West Bengal form No. 5370', style: bold),
          pw.SizedBox(height: 6),
          pw.Center(child: pw.Text('FINAL REPORT OF A REPORTED CASE OF UNNATURAL DEATH SENT TO THE MAGISTRATE', style: bold, textAlign: pw.TextAlign.center)),
          pw.Center(child: pw.Text('UNDER SECTION 174, CR.P.CODE', style: bold)),
          pw.Center(child: pw.Text('(P.R.B. From No.- 53 Vide Rule 276)', style: normal)),
          pw.SizedBox(height: 16),
          item('1. Station, Number and date of first information : ', _v(ud.firstInformationDetails, '$ps U/D Case No. ${ud.udNo}, Dated- ${ud.dateTime}.')),
          item('2. Name of the deceased : ', _deceasedFull(ud)),
          item('3. Date and hour of going to the spot : ', _v(ud.spotVisitDateHour, ud.dateTime)),
          item('4. Date and hour of dispatch of the final report : ', _v(ud.finalReportDispatchDateHour)),
          pw.SizedBox(height: 12),
          pw.Text('Officer-In-Charge of $ps', style: normal),
          pw.SizedBox(height: 10),
          pw.Text(body, style: normal, textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 10),
          pw.Text(finding, style: normal, textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 10),
          pw.Text(prayer, style: normal, textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 26),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Submitted', style: normal),
              pw.SizedBox(height: 18),
              pw.Text('(${officer.name})', style: normal),
              pw.Text('${officer.rank} of Police, $ps', style: normal),
              pw.Text('${officer.district}, Dt- ${_v(ud.preparedDate, ud.dateTime)}', style: normal),
            ]),
          ),
        ],
      ),
    );
    return doc.save();
  }

  String _htmlPage(String title, String body) => '''<!DOCTYPE html><html><head><meta charset="UTF-8"><title>${_e(title)}</title><style>
body{font-family:Noto Serif Bengali, Nirmala UI, SolaimanLipi, serif;font-size:12pt;line-height:1.35}.center{text-align:center}.right{text-align:right}.bold{font-weight:700}.justify{text-align:justify}table{border-collapse:collapse;width:100%}td,th{border:1px solid #111;padding:5px;vertical-align:top}.small{font-size:10pt}.page-break{page-break-before:always}
</style></head><body>$body</body></html>''';

  Uint8List _docBytes(String html) => Uint8List.fromList(utf8.encode(html));

  Future<Uint8List> buildSurathalReportDoc({required OfficerProfile officer, required UdCase ud}) async {
    final ps = _ps(_v(ud.policeStation, officer.policeStation));
    final html = _htmlPage('Surathal Report', '''
<div class="center bold">Preparing the Surathal Report of the deceased ${_e(_deceasedFull(ud))} in c/w ${_e(ps)} U/D case No: - ${_e(ud.udNo)}, Date :- ${_e(ud.dateTime)}</div>
<p>Inquest Time: From ${_e(_v(ud.inquestFromTime, '................'))} To ${_e(_v(ud.inquestToTime, '................'))}</p>
<p class="justify">${_e(_surathalBody(officer, ud))}</p>
<div class="right">Prepared by me<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)} of Police, ${_e(ps)}<br/>Date- ${_e(_v(ud.preparedDate, ud.dateTime))}</div>''');
    return _docBytes(html);
  }

  Future<Uint8List> buildDeadBodyChallanDoc({required OfficerProfile officer, required UdCase ud}) async {
    final ps = _ps(_v(ud.policeStation, officer.policeStation));
    final headers = [
      'Name and caste of deceased','Sex and Age','Residence','Where dead body was found','Date and hours of dispatch and distance from place of postmortem','Means of Dispatch','Name of identifying Police officer','Marks on the body','Cause of death as for as known','Remarks, Mention what clothes articles were sent herewith the body'
    ];
    final values = [
      '${_v(ud.deceasedName)} ${ud.deceasedCaste.trim().isEmpty ? '' : '(${ud.deceasedCaste})'}',
      '${_v(ud.deceasedSex)} ${ud.deceasedAge.trim().isEmpty ? '' : ', Age- ${ud.deceasedAge}'}',
      _v(ud.challanResidence, ud.deceasedAddress),
      _v(ud.bodyFoundPlaceChallan, ud.placeFound),
      _v(ud.dispatchDateHourDistance, 'On ${_v(ud.preparedDate, ud.dateTime)} Inquest Time: From ${ud.inquestFromTime} To ${ud.inquestToTime}, ${ud.distanceFromPs}'),
      _v(ud.dispatchMeans, 'By Govt. Stretcher of Hospital / By govt. vehicle / By Hire vehicle'),
      _v(ud.identifyingPoliceOfficer, ud.escortConstable),
      _v(ud.marksOnBody, 'As per surathal-report'),
      _v(ud.causeOfDeathKnown, 'As per surathal-report'),
      _v(ud.challanRemarksArticles, '(i) Wearing appearance\n(ii) Viscera\n(iii)\n(iv)\nThis above articles may kindly be preserved.'),
    ];
    final h = headers.map((e) => '<th>${_e(e)}</th>').join();
    final v = values.map((e) => '<td>${_e(e)}</td>').join();
    final html = _htmlPage('Dead Body Challan', '''
<div class="bold">West Bengal Form No- 5371 <span style="float:right">Ref: ${_e(ps)} U/D case No: - ${_e(ud.udNo)}, Date :- ${_e(ud.dateTime)}</span></div>
<div class="center bold">Challan for use when a Dead Body is sent for examination</div>
<div class="center">(P.R.B Form No-54 vide Rule-252)</div><br/>
<table><tr>$h</tr><tr>$v</tr></table>
<p class="justify">Forwarded the dead body of the deceased namely ${_e(_deceasedFull(ud))} to ${_e(_v(ud.pmMorgueName, 'Police Morgue'))} with all connected papers through ${_e(_v(ud.escortConstable, 'Constable'))} of ${_e(ps)} for holding Post Mortem Examination over the dead-body of the deceased to ascertain the actual cause of death.</p>
<div class="right">Submitted –<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)} of Police, ${_e(ps)}<br/>Date- ${_e(_v(ud.preparedDate, ud.dateTime))}</div>''');
    return _docBytes(html);
  }

  Future<Uint8List> buildUdFinalReportDoc({required OfficerProfile officer, required UdCase ud}) async {
    final ps = _ps(_v(ud.policeStation, officer.policeStation));
    final body = _v(ud.finalReportNarrative, '''The fact of the case in brief is that ${_v(ud.firstInformationDetails, 'information was received regarding the unnatural death of ${_deceasedFull(ud)}.')} On the basis of such information started $ps U/D Case No. ${ud.udNo} and investigation was taken up. Inquest report was prepared over the dead body duly identified by the near relatives/witnesses. The dead body was forwarded to police morgue for holding post mortem examination to ascertain the actual cause of death. ${_v(ud.pmReportDetails)} ${_v(ud.pmDoctorOpinion)}''');
    final finding = _v(ud.finalFinding, 'From the preliminary enquiry as well as the PM report, no foul play could be detected behind the death of the deceased.');
    final prayer = _v(ud.finalPrayer, 'Therefore, I am praying that this U/D Case may kindly be filed with a view to re-open the case if any complaint or clue comes out from any corner in near future.');
    final html = _htmlPage('UD Final Report', '''
<div class="bold">West Bengal form No. 5370</div>
<div class="center bold">FINAL REPORT OF A REPORTED CASE OF UNNATURAL DEATH SENT TO THE MAGISTRATE</div>
<div class="center bold">UNDER SECTION 174, CR.P.CODE</div>
<div class="center">(P.R.B. From No.- 53 Vide Rule 276)</div><br/>
<p><b>1. Station, Number and date of first information :</b> ${_e(_v(ud.firstInformationDetails, '$ps U/D Case No. ${ud.udNo}, Dated- ${ud.dateTime}.'))}</p>
<p><b>2. Name of the deceased :</b> ${_e(_deceasedFull(ud))}</p>
<p><b>3. Date and hour of going to the spot :</b> ${_e(_v(ud.spotVisitDateHour, ud.dateTime))}</p>
<p><b>4. Date and hour of dispatch of the final report :</b> ${_e(_v(ud.finalReportDispatchDateHour))}</p>
<p>Officer-In-Charge of ${_e(ps)}</p>
<p class="justify">${_e(body)}</p>
<p class="justify">${_e(finding)}</p>
<p class="justify">${_e(prayer)}</p>
<div class="right">Submitted<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)} of Police, ${_e(ps)}<br/>${_e(officer.district)}, Dt- ${_e(_v(ud.preparedDate, ud.dateTime))}</div>''');
    return _docBytes(html);
  }
}
