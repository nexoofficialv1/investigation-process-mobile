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
  Future<Uint8List> buildCaseDiaryPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
  }) async {
    final doc = pw.Document();

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
          _wbOfficialCdContinuousTable(cd),
          _wbOfficialCdSignature(officer: officer),
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

  pw.Widget _wbOfficialCdContinuousTable(CdEntry cd) {
    final lines = cd.tableLines.isNotEmpty
        ? cd.tableLines
        : [CdTableLine(noAndHour: 'I\n${cd.startTime}', placeOfEntry: cd.placeOfEntry, synopsis: cd.cdNumber == 1 ? 'Received copy of FIR\n+\nGist' : 'Further investigation', proceedings: cd.body)];

    final leftEntryColumn = lines.map((line) => line.noAndHour).join('\n\n\n');
    final placeColumn = lines.map((line) => line.placeOfEntry).join('\n\n\n');
    final synopsisColumn = lines.map((line) => line.synopsis).join('\n\n\n');
    final proceedingsColumn = lines.map((line) => line.proceedings).where((e) => e.trim().isNotEmpty).join('\n\n');

    // Official PRB Form No. 43 layout: "Particulars of Enquiry." is a single
    // heading spread across the three marginal columns. The right proceedings
    // column begins independently and no horizontal rule is inserted between
    // daily entries. Only the column boundaries remain visible.
    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.90),
        1: pw.FlexColumnWidth(7.10),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(width: 0.55)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.55)),
                    ),
                    padding: const pw.EdgeInsets.fromLTRB(8, 3, 8, 3),
                    child: pw.Text('Particulars of Enquiry.', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
                  ),
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
                          _officialCell(leftEntryColumn, center: true, fontSize: 9.4),
                          _officialCell(placeColumn, center: true, fontSize: 9.4),
                          _officialCell(synopsisColumn, center: true, fontSize: 9.4),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.Container(
              constraints: const pw.BoxConstraints(minHeight: 610),
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: pw.Text(proceedingsColumn, style: const pw.TextStyle(fontSize: 10.2), textAlign: pw.TextAlign.justify),
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
    final doc = pw.Document();
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
    final doc = pw.Document();
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
    final doc = pw.Document();
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
    final doc = pw.Document();
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
    final label = '${o.marker} ${o.label}'.trim();
    switch (o.type) {
      case SketchObjectType.house:
        return pw.Column(children: [
          pw.Container(width: w, height: h * .72, decoration: pw.BoxDecoration(border: pw.Border.all(width: .8), color: PdfColors.grey100), child: pw.Center(child: pw.Text(label, style: const pw.TextStyle(fontSize: 6.5)))),
          pw.Container(width: w * .88, height: h * .20, decoration: pw.BoxDecoration(border: pw.Border.all(width: .8), color: PdfColors.grey300)),
        ]);
      case SketchObjectType.shop:
        return pw.Container(width: w, height: h, decoration: pw.BoxDecoration(border: pw.Border.all(width: .8)), child: pw.Column(children: [
          pw.Container(width: w, height: h * .22, color: PdfColors.grey500, child: pw.Center(child: pw.Text('SHOP', style: const pw.TextStyle(fontSize: 5.5)))),
          pw.Expanded(child: pw.Center(child: pw.Text(label, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6.2)))),
        ]));
      case SketchObjectType.pond:
        return pw.Container(width: w, height: h, decoration: pw.BoxDecoration(border: pw.Border.all(width: .8), borderRadius: pw.BorderRadius.circular(18), color: PdfColors.blue100), child: pw.Center(child: pw.Text(label.isEmpty ? 'POND' : label, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6.2))));
      case SketchObjectType.tree:
        return pw.Column(children: [
          pw.Container(width: w * .70, height: h * .62, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(width: .8), color: PdfColors.green100), child: pw.Center(child: pw.Text(o.marker, style: const pw.TextStyle(fontSize: 7)))),
          pw.Container(width: w * .12, height: h * .28, color: PdfColors.brown300),
          pw.Text(o.label, style: const pw.TextStyle(fontSize: 5.5)),
        ]);
      case SketchObjectType.road:
        return pw.Container(width: w, height: h, decoration: pw.BoxDecoration(border: pw.Border.all(width: .8), color: PdfColors.grey300), child: pw.Center(child: pw.Text(label.isEmpty ? 'ROAD' : label, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6.2))));
      case SketchObjectType.field:
        return pw.Container(width: w, height: h, decoration: pw.BoxDecoration(border: pw.Border.all(width: .8), color: PdfColors.green50), child: pw.Center(child: pw.Text(label.isEmpty ? 'FIELD' : label, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6.2))));
      case SketchObjectType.po:
        return pw.Container(width: w, height: h, decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.4), color: PdfColors.red50), child: pw.Center(child: pw.Text(label.isEmpty ? 'PO' : label, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))));
      case SketchObjectType.arrow:
        return pw.Container(width: w, height: h, child: pw.Center(child: pw.Text('↑\nN\n$label', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))));
    }
  }

  pw.Widget _sketchIndexTable(SketchMapEntry sketch) {
    final rows = sketch.objects.isEmpty
        ? [const SketchMapObject(id: '', type: SketchObjectType.house, marker: '-', label: 'No object added', direction: '', indexDescription: '', x: 0, y: 0, width: 0, height: 0)]
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
