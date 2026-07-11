import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../models/statement_entry.dart';
import '../models/form_notice.dart';

class PdfService {
  Future<Uint8List> buildCaseDiaryPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
  }) async {
    final doc = pw.Document();

    // Locked official-style A4 Case Diary template.
    // Do not change the layout here without changing the official CD template.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
        build: (context) => [
          _officialCdHeader(officer: officer, caseFile: caseFile, cd: cd),
          pw.SizedBox(height: 8),
          _officialCdBodyTable(cd),
          pw.SizedBox(height: 26),
          _officialCdSignature(officer: officer, cd: cd),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _officialCdHeader({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            'CASE DIARY',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(
            'UNDER SECTION 192 BNSS',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 0.55),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.15),
            1: pw.FlexColumnWidth(2.25),
            2: pw.FlexColumnWidth(1.15),
            3: pw.FlexColumnWidth(2.25),
          },
          children: [
            _officialInfoRow('Police Station', officer.policeStation, 'District', officer.district),
            _officialInfoRow('P.S. Case No.', caseFile.psCaseNo, 'Date', caseFile.caseDate),
            _officialInfoRow('Sections of Law', caseFile.sections, 'C.D. No.', cd.cdNumber.toString()),
            _officialInfoRow('Date of C.D.', cd.cdDate, 'I.O.', '${officer.rank} ${officer.name}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _officialCdBodyTable(CdEntry cd) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.65),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.20),
        1: pw.FlexColumnWidth(1.30),
        2: pw.FlexColumnWidth(5.80),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            _officialCell('No. and hour of entry', bold: true, center: true),
            _officialCell('Place of entry', bold: true, center: true),
            _officialCell('Diary of proceedings in investigation', bold: true, center: true),
          ],
        ),
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            _officialCell('C.D. No. ${cd.cdNumber}\n${cd.startTime}\nto\n${cd.endTime}', center: true),
            _officialCell(cd.placeOfEntry),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(7, 6, 7, 6),
              child: pw.Text(
                cd.body,
                style: const pw.TextStyle(fontSize: 11),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _officialCdSignature({
    required OfficerProfile officer,
    required CdEntry cd,
  }) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(height: 24),
          pw.Text('Signature of the I.O.', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text('${officer.rank} ${officer.name}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(officer.policeStation, style: const pw.TextStyle(fontSize: 11)),
          pw.Text('Date: ${cd.cdDate}', style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.TableRow _officialInfoRow(String a, String b, String c, String d) {
    return pw.TableRow(children: [
      _officialCell(a, bold: true),
      _officialCell(b),
      _officialCell(c, bold: true),
      _officialCell(d),
    ]);
  }

  pw.Widget _officialCell(String text, {bool bold = false, bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(5, 4, 5, 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10.5, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
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
          pw.SizedBox(height: 10),
          pw.Text('Case Reference: ${officer.policeStation} PS Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.Text(form.body, style: const pw.TextStyle(fontSize: 11.5), textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 26),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('${officer.rank} ${officer.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Investigating Officer'),
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
