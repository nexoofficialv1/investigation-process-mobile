import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../models/statement_entry.dart';
import '../models/form_notice.dart';
import '../models/sketch_map.dart';

class PdfService {
  Future<pw.ThemeData> _pdfTheme() async {
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

  Future<Uint8List> buildCaseDiaryPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());

    // STRICT OFFICIAL CD FORMAT - West Bengal Form No. 5363 / P.R.B Form No. 43.
    // Important: no horizontal lines between individual diary entries. Entry no/time,
    // place, synopsis and proceedings are placed inside one continuous enquiry block.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _wbOfficialCdHeader(officer: officer, caseFile: caseFile, cd: cd, continued: true),
                  _wbOfficialCdStatusRow(),
                ],
              ),
        build: (context) => [
          _wbOfficialCdHeader(officer: officer, caseFile: caseFile, cd: cd),
          _wbOfficialCdStatusRow(),
          _wbOfficialCdContinuousTable(cd, officer),
        ],
      ),
    );

    return doc.save();
  }

  String _shortPsName(String ps) => ps.replaceAll('Police Station', 'PS').trim();

  pw.Widget _wbOfficialCdHeader({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
    bool continued = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('West Bengal form No. 5363', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('OF ${DateTime.now().year}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text('CASE DIARY UNDER SECTION 192 BNSS${continued ? ' (Continued)' : ''}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 8),
        pw.Center(child: pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: '(P.R.B FROM NO. 43 – Vide ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: 'Rule 229', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: ')', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ]))),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('Police Station: -${_shortPsName(officer.policeStation)}', style: _cdTopStyle())),
            pw.Expanded(flex: 2, child: pw.Text('District: -${officer.district}', style: _cdTopStyle())),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            pw.Expanded(flex: 2, child: pw.Text('First information No: -${caseFile.psCaseNo}', style: _cdTopStyle())),
            pw.Expanded(flex: 1, child: pw.Text('Dated: -${caseFile.caseDate}', style: _cdTopStyle())),
            pw.Expanded(flex: 2, child: pw.Text('Section: -${caseFile.sections}', style: _cdTopStyle())),
          ],
        ),
        pw.Text('Name of Complainant: -${caseFile.complainantName}', style: _cdTopStyle()),
        pw.Row(
          children: [
            pw.Expanded(child: pw.Text('Case Diary No: -${cd.cdNumber}', style: _cdTopStyle())),
            pw.Expanded(child: pw.Text('Dated: -${cd.cdDate}', style: _cdTopStyle())),
          ],
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.TextStyle _cdTopStyle() => pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold);

  pw.Widget _wbOfficialCdStatusRow() {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1.1), 2: pw.FlexColumnWidth(1.1)},
      children: [
        pw.TableRow(children: [
          _officialCell('Arrested and sent up', center: true, fontSize: 11),
          _officialCell('Arrested and released on bail.', center: true, fontSize: 11),
          _officialCell('At large.', center: true, fontSize: 11),
        ]),
      ],
    );
  }

  pw.Widget _wbOfficialCdContinuousTable(CdEntry cd, OfficerProfile officer) {
    final lines = cd.tableLines.isNotEmpty
        ? cd.tableLines
        : [CdTableLine(noAndHour: 'I\n${cd.startTime}', placeOfEntry: cd.placeOfEntry, synopsis: cd.cdNumber == 1 ? 'Received copy of FIR\n+\nGist' : 'Further investigation', proceedings: cd.body)];

    final leftEntryColumn = lines.map((line) => line.noAndHour).join('\n\n\n');
    final placeColumn = lines.map((line) => line.placeOfEntry).join('\n\n\n');
    final synopsisColumn = lines.map((line) => line.synopsis).join('\n\n\n');
    final proceedingsColumn = lines.map((line) => line.proceedings).where((e) => e.trim().isNotEmpty).join('\n\n');

    // Official PRB Form No. 43 layout:
    // Row 1: "Particulars of Enquiry." is merged only over the three marginal columns.
    // Row 2: three marginal columns + the large proceedings column.
    // No horizontal line is inserted between individual CD entries.
    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.90),
        1: pw.FlexColumnWidth(7.10),
      },
      children: [
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(8, 3, 8, 3),
            child: pw.Text('Particulars of Enquiry.', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 22),
        ]),
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            pw.Table(
              border: const pw.TableBorder(
                verticalInside: pw.BorderSide(width: 0.55),
                horizontalInside: pw.BorderSide(width: 0.55),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.86),
                1: pw.FlexColumnWidth(0.90),
                2: pw.FlexColumnWidth(1.14),
              },
              children: [
                pw.TableRow(children: [
                  _officialCell('No. and\nhour of\nentry.', center: true, fontSize: 9.4),
                  _officialCell('Place of\nentry.', center: true, fontSize: 9.4),
                  _officialCell('Synopsis of\nentry.', center: true, fontSize: 9.4),
                ]),
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.top,
                  children: [
                    _officialCell(leftEntryColumn, center: true, fontSize: 9.4, minHeight: 520),
                    _officialCell(placeColumn, center: true, fontSize: 9.4, minHeight: 520),
                    _officialCell(synopsisColumn, center: true, fontSize: 9.4, minHeight: 520),
                  ],
                ),
              ],
            ),
            pw.Container(
              constraints: const pw.BoxConstraints(minHeight: 575),
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(proceedingsColumn, style: const pw.TextStyle(fontSize: 10.2), textAlign: pw.TextAlign.justify),
                    pw.SizedBox(height: 18),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('Submitted', style: const pw.TextStyle(fontSize: 10.5)),
                          pw.SizedBox(height: 28),
                          pw.Text('(${officer.name})', style: const pw.TextStyle(fontSize: 10.5)),
                          pw.Text(officer.rank, style: const pw.TextStyle(fontSize: 10.5)),
                          pw.Text(_shortPsName(officer.policeStation), style: const pw.TextStyle(fontSize: 10.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }



  pw.Widget _wbOfficialCdSignature({required OfficerProfile officer}) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, right: 80),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Submitted', style: const pw.TextStyle(fontSize: 10.5)),
            pw.SizedBox(height: 28),
            pw.Text('(${officer.name})', style: const pw.TextStyle(fontSize: 10.5)),
            pw.Text(officer.rank, style: const pw.TextStyle(fontSize: 10.5)),
            pw.Text(_shortPsName(officer.policeStation), style: const pw.TextStyle(fontSize: 10.5)),
          ],
        ),
      ),
    );
  }



  pw.Widget _officialCell(String text, {bool bold = false, bool center = false, double fontSize = 10.5, double? minHeight}) {
    final content = pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(4, 3, 4, 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
    if (minHeight == null) return content;
    return pw.Container(constraints: pw.BoxConstraints(minHeight: minHeight), child: content);
  }

  Future<Uint8List> buildStatementPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required StatementEntry statement,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 36, 42, 36),
        build: (context) => [
          _centerBold('Statement of witness recorded u/s 180 BNSS'),
          pw.SizedBox(height: 16),
          pw.Text('Case Reference: ${officer.policeStation} PS Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}'),
          pw.SizedBox(height: 8),
          pw.Text('Name of Witness: ${statement.witnessName}'),
          pw.Text('Witness Details: ${statement.witnessDetails}'),
          pw.Text('Statement Type: ${statement.statementType}'),
          pw.SizedBox(height: 14),
          pw.Text(statement.body, style: const pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Signature/LTI/RTI of witness'),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Recorded by'),
                  pw.SizedBox(height: 24),
                  pw.Text('${officer.rank} ${officer.name}'),
                  pw.Text(officer.policeStation),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> shareCaseDiaryPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
  }) async {
    final bytes = await buildCaseDiaryPdf(officer: officer, caseFile: caseFile, cd: cd);
    await Printing.sharePdf(bytes: bytes, filename: 'CD_${caseFile.psCaseNo.replaceAll('/', '_')}_${cd.cdNumber}.pdf');
  }

  Future<void> shareStatementPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required StatementEntry statement,
  }) async {
    final bytes = await buildStatementPdf(officer: officer, caseFile: caseFile, statement: statement);
    await Printing.sharePdf(bytes: bytes, filename: 'Statement_${statement.witnessName}.pdf');
  }


  Future<Uint8List> buildFormNoticePdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required FormNotice form,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    final body = form.body;
    final is35 = form.templateId == 'bnss_35_3';
    final is94 = form.templateId == 'bnss_94' || form.templateId == 'medical_exam' || form.templateId == 'bht_injury';
    final isForwarding = form.templateId == 'forwarding';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(46, 30, 46, 30),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
        ),
        build: (context) {
          if (is35) return _notice35Pdf(officer, caseFile, body);
          if (isForwarding) return _forwardingPdf(officer, caseFile, body);
          if (is94) return _notice94Pdf(officer, caseFile, body);
          return [
            _centerBold(form.title),
            pw.SizedBox(height: 10),
            pw.Text('Ref: ${officer.policeStation} Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}', style: const pw.TextStyle(fontSize: 10.5)),
            pw.SizedBox(height: 16),
            pw.Text(body, style: const pw.TextStyle(fontSize: 11.5), textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 26),
            _rightOfficerBlock(officer),
          ];
        },
      ),
    );
    return doc.save();
  }

  List<pw.Widget> _notice35Pdf(OfficerProfile officer, CaseFile caseFile, String body) => [
        pw.Center(child: pw.Text('NOTICE OF APPEARANCE BY THE POLICE', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text('[As per section – 35 (3) BNSS Act.]', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Serial\nNo.............', style: const pw.TextStyle(fontSize: 10.5)),
          pw.Text('Annexure-A', style: const pw.TextStyle(fontSize: 11)),
        ]),
        pw.SizedBox(height: 12),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(_shortPsName(officer.policeStation).replaceAll('PS', 'Police Station'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 10),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11.2), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 28),
        _submittedOfficerBlock(officer),
      ];

  List<pw.Widget> _notice94Pdf(OfficerProfile officer, CaseFile caseFile, String body) => [
        pw.Center(child: pw.Text('NOTICE U/S 94 BNSS, 2023', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 18),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11.5), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 30),
        _rightOfficerBlock(officer),
      ];

  List<pw.Widget> _forwardingPdf(OfficerProfile officer, CaseFile caseFile, String body) => [
        pw.Text('In the court of ${officer.courtName}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text('Through GRO Kalna Court', style: const pw.TextStyle(fontSize: 11))),
        pw.SizedBox(height: 22),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11.3), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 24),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(child: pw.Text('Enclosure:\n1. Original FIR.\n2. Memo of Arrest.\n3. Inspection Memos.\n4. Medical treatment Slip.\n5. Intimation of arrest.', style: const pw.TextStyle(fontSize: 10.8))),
            pw.Expanded(child: _submittedOfficerBlock(officer)),
          ],
        ),
      ];

  pw.Widget _rightOfficerBlock(OfficerProfile officer) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('${officer.rank} ${officer.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (officer.mobile.trim().isNotEmpty) pw.Text(officer.mobile),
          pw.Text('${_shortPsName(officer.policeStation)}, ${officer.district}'),
        ]),
      );

  pw.Widget _submittedOfficerBlock(OfficerProfile officer) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Text('Submitted,', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 26),
          pw.Text(officer.name, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(officer.rank, style: const pw.TextStyle(fontSize: 11)),
          pw.Text('${_shortPsName(officer.policeStation)}, ${officer.district}', style: const pw.TextStyle(fontSize: 11)),
        ]),
      );

  Future<Uint8List> buildGeneralReportPdf({
    required OfficerProfile officer,
    required FormNotice form,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 36, 42, 36),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9)),
        ),
        build: (context) => [
          _centerBold(form.title),
          pw.SizedBox(height: 16),
          pw.Text(form.body, style: const pw.TextStyle(fontSize: 11.5), textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 26),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('${officer.rank} ${officer.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(officer.policeStation),
                pw.Text('District: ${officer.district}'),
              ],
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> shareFormNoticePdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required FormNotice form,
  }) async {
    final bytes = await buildFormNoticePdf(officer: officer, caseFile: caseFile, form: form);
    await Printing.sharePdf(bytes: bytes, filename: "${form.title.replaceAll(' ', '_')}_${caseFile.psCaseNo.replaceAll('/', '_')}.pdf");
  }


  Future<Uint8List> buildSketchMapPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required SketchMapEntry sketch,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    const canvasW = 500.0;
    const canvasH = 430.0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 24, 32, 24),
        build: (context) => [
          _centerBold('ROUGH SKETCH MAP WITH INDEX'),
          pw.SizedBox(height: 6),
          pw.Text('Case Reference: ${officer.policeStation} PS Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Date: ${sketch.date}', style: const pw.TextStyle(fontSize: 10)),
          if (sketch.poDescription.trim().isNotEmpty) pw.Text('PO: ${sketch.poDescription}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),
          pw.Container(
            width: canvasW,
            height: canvasH,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
            child: pw.Stack(
              children: [
                pw.Positioned(top: 8, right: 10, child: pw.Text('N', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
                ...sketch.objects.map((o) => pw.Positioned(
                      left: (o.x.clamp(0.0, 0.95)) * canvasW,
                      top: (o.y.clamp(0.0, 0.95)) * canvasH,
                      child: _pdfSketchObject(o, canvasW, canvasH),
                    )),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Index', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _sketchIndexTable(sketch),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text('North: ${sketch.north}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(child: pw.Text('South: ${sketch.south}', style: const pw.TextStyle(fontSize: 10))),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text('East: ${sketch.east}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(child: pw.Text('West: ${sketch.west}', style: const pw.TextStyle(fontSize: 10))),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Prepared by', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 24),
                pw.Text('(${officer.name})', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(officer.rank, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(officer.policeStation, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfSketchObject(SketchMapObject o, double canvasW, double canvasH) {
    final w = o.width * canvasW;
    final h = o.height * canvasH;
    final label = o.label.trim().isEmpty ? o.marker : o.label.trim();
    final symbol = pw.Stack(children: [
      pw.Positioned.fill(child: pw.SvgImage(svg: _sketchObjectSvg(o.type))),
      pw.Positioned(
        left: 2,
        right: 2,
        top: h * .34,
        child: pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.all(1.2),
          child: pw.Text(label, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: o.type == SketchObjectType.road ? 5.4 : 5.8, fontWeight: pw.FontWeight.bold)),
        ),
      ),
    ]);
    return pw.Transform.rotate(
      angle: o.rotationDeg * math.pi / 180,
      child: pw.Container(width: w, height: h, child: symbol),
    );
  }

  String _sketchObjectSvg(SketchObjectType type) {
    switch (type) {
      case SketchObjectType.house:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80">
          <polygon points="8,34 50,5 92,34" fill="#8D4B20" stroke="#111" stroke-width="2"/>
          <rect x="18" y="34" width="64" height="38" fill="#FFE0B2" stroke="#111" stroke-width="2"/>
          <rect x="44" y="52" width="12" height="20" fill="#FFF8E1" stroke="#111" stroke-width="1.5"/>
          <rect x="26" y="43" width="14" height="10" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
          <rect x="60" y="43" width="14" height="10" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
        </svg>''';
      case SketchObjectType.shop:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80">
          <rect x="12" y="28" width="76" height="44" fill="#F3E5F5" stroke="#111" stroke-width="2"/>
          <rect x="8" y="12" width="84" height="20" fill="#CE93D8" stroke="#111" stroke-width="2"/>
          <rect x="14" y="12" width="12" height="20" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
          <rect x="38" y="12" width="12" height="20" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
          <rect x="62" y="12" width="12" height="20" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
          <rect x="42" y="48" width="16" height="24" fill="#FFFFFF" stroke="#111" stroke-width="1.5"/>
        </svg>''';
      case SketchObjectType.pond:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80">
          <path d="M10 38 C8 12, 40 4, 65 14 C96 24, 94 62, 64 72 C36 82, 8 66, 10 38 Z" fill="#B3E5FC" stroke="#01579B" stroke-width="2"/>
          <path d="M25 34 H75 M24 47 H74 M30 60 H68" stroke="#0277BD" stroke-width="2"/>
        </svg>''';
      case SketchObjectType.tree:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 90">
          <rect x="45" y="52" width="10" height="30" fill="#795548"/>
          <circle cx="50" cy="34" r="24" fill="#A5D6A7" stroke="#111" stroke-width="1.5"/>
          <circle cx="36" cy="43" r="20" fill="#81C784" stroke="#111" stroke-width="1.2"/>
          <circle cx="64" cy="43" r="20" fill="#66BB6A" stroke="#111" stroke-width="1.2"/>
        </svg>''';
      case SketchObjectType.road:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 180 45">
          <rect x="2" y="8" width="176" height="29" rx="2" fill="#BDBDBD" stroke="#111" stroke-width="2"/>
          <path d="M15 23 H35 M55 23 H75 M95 23 H115 M135 23 H160" stroke="#FFFFFF" stroke-width="4"/>
        </svg>''';
      case SketchObjectType.field:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80">
          <rect x="8" y="10" width="84" height="60" fill="#DCECC5" stroke="#33691E" stroke-width="2"/>
          <path d="M24 10 V70 M40 10 V70 M56 10 V70 M72 10 V70" stroke="#7CB342" stroke-width="1.5"/>
          <path d="M8 30 H92 M8 50 H92" stroke="#AED581" stroke-width="1"/>
        </svg>''';
      case SketchObjectType.po:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 70">
          <rect x="10" y="10" width="80" height="50" fill="#FFEBEE" stroke="#B71C1C" stroke-width="4"/>
          <line x1="15" y1="15" x2="85" y2="55" stroke="#B71C1C" stroke-width="2"/>
          <line x1="85" y1="15" x2="15" y2="55" stroke="#B71C1C" stroke-width="2"/>
        </svg>''';
      case SketchObjectType.arrow:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 100">
          <path d="M30 90 V18" stroke="#111" stroke-width="5"/>
          <polygon points="30,5 10,28 50,28" fill="#111"/>
        </svg>''';
    }
  }

  pw.Widget _sketchIndexTable(SketchMapEntry sketch) {
    final rows = sketch.objects.isEmpty
        ? [const SketchMapObject(id: '', type: SketchObjectType.house, marker: '-', label: 'No object added', direction: '', indexDescription: '', x: 0, y: 0, width: 0, height: 0, rotationDeg: 0)]
        : sketch.objects;
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.55),
        1: pw.FlexColumnWidth(1.0),
        2: pw.FlexColumnWidth(1.0),
        3: pw.FlexColumnWidth(4.0),
      },
      children: [
        pw.TableRow(children: [
          _cell('Mark', bold: true),
          _cell('Direction', bold: true),
          _cell('Type', bold: true),
          _cell('Description', bold: true),
        ]),
        ...rows.map((o) => pw.TableRow(children: [
              _cell(o.marker),
              _cell(o.direction),
              _cell(o.type.label),
              _cell(o.indexDescription.trim().isEmpty ? o.label : o.indexDescription),
            ])),
      ],
    );
  }

  pw.Widget _centerBold(String text) => pw.Center(
        child: pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      );

  pw.TableRow _infoRow(String a, String b, String c, String d) {
    return pw.TableRow(children: [
      _cell(a, bold: true),
      _cell(b),
      _cell(c, bold: true),
      _cell(d),
    ]);
  }

  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}
