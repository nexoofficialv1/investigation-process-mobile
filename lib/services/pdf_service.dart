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
import '../models/ud_case.dart';

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

  // INVESTIGO_CD_PREVIEW_STABILITY_V094
Future<Uint8List> buildCaseDiaryPdf({
  required OfficerProfile officer,
  required CaseFile caseFile,
  required CdEntry cd,
}) async {
  final doc = pw.Document(theme: await _pdfTheme());
  final pageCds = _caseDiaryPageCds(cd);

  for (var pageIndex = 0; pageIndex < pageCds.length; pageIndex++) {
    final pageCd = pageCds[pageIndex];
    final isEnglish = pageCd.languageCode == 'en';
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _wbOfficialCdHeader(
              officer: officer,
              caseFile: caseFile,
              cd: pageCd,
              continued: pageIndex > 0,
            ),
            _wbOfficialCdStatusRow(isEnglish),
            pw.Expanded(
              child: _wbOfficialCdContinuousTable(pageCd, officer),
            ),
          ],
        ),
      ),
    );
  }

  return doc.save();
}

List<CdTableLine> _sourceCaseDiaryLines(CdEntry cd) {
  if (cd.tableLines.isNotEmpty) {
    return List<CdTableLine>.from(cd.tableLines);
  }
  final isEnglish = cd.languageCode == 'en';
  return [
    CdTableLine(
      noAndHour: '${isEnglish ? '1' : '১'}\n${cd.startTime}',
      placeOfEntry: cd.placeOfEntry,
      synopsis: cd.cdNumber == 1
          ? (isEnglish
              ? 'Receipt of FIR copy\n+\nBrief facts'
              : 'এফআইআর অনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা')
          : (isEnglish ? 'Further investigation' : 'পরবর্তী তদন্ত'),
      proceedings: cd.body,
    ),
  ];
}

List<String> _splitCaseDiaryText(String source, {int maxChars = 620}) {
  final text = source.trim();
  if (text.isEmpty) return const [''];

  final words = text.split(RegExp(r'\s+'));
  final chunks = <String>[];
  var buffer = StringBuffer();

  void flush() {
    final value = buffer.toString().trim();
    if (value.isNotEmpty) chunks.add(value);
    buffer = StringBuffer();
  }

  for (final word in words) {
    if (word.length > maxChars) {
      flush();
      final runes = word.runes.toList();
      for (var start = 0; start < runes.length; start += maxChars) {
        final end = math.min(start + maxChars, runes.length);
        chunks.add(String.fromCharCodes(runes.sublist(start, end)));
      }
      continue;
    }

    final currentLength = buffer.length;
    final nextLength = currentLength + (currentLength == 0 ? 0 : 1) + word.length;
    if (nextLength > maxChars) flush();
    if (buffer.length > 0) buffer.write(' ');
    buffer.write(word);
  }

  flush();
  return chunks.isEmpty ? const [''] : chunks;
}

List<CdEntry> _caseDiaryPageCds(CdEntry cd) {
  const pageBudget = 650;
  final isEnglish = cd.languageCode == 'en';
  final pages = <CdEntry>[];
  var currentLines = <CdTableLine>[];
  var used = 0;

  void flushPage() {
    if (currentLines.isEmpty) return;
    pages.add(
      cd.copyWith(
        body: currentLines
            .map((line) => line.proceedings)
            .where((text) => text.trim().isNotEmpty)
            .join('\n\n'),
        tableLines: List<CdTableLine>.from(currentLines),
      ),
    );
    currentLines = <CdTableLine>[];
    used = 0;
  }

  for (final line in _sourceCaseDiaryLines(cd)) {
    final parts = _splitCaseDiaryText(line.proceedings);
    for (var partIndex = 0; partIndex < parts.length; partIndex++) {
      final firstPart = partIndex == 0;
      final part = parts[partIndex];
      final metadataCost = firstPart
          ? line.noAndHour.length + line.placeOfEntry.length + line.synopsis.length
          : 24;
      final cost = part.length + (metadataCost ~/ 2) + 40;

      if (currentLines.isNotEmpty && used + cost > pageBudget) {
        flushPage();
      }

      currentLines.add(
        CdTableLine(
          noAndHour: firstPart ? line.noAndHour : '',
          placeOfEntry: firstPart ? line.placeOfEntry : '',
          synopsis: firstPart
              ? line.synopsis
              : (isEnglish ? 'Continued' : 'চলমান'),
          proceedings: part,
        ),
      );
      used += cost;

      if (used >= pageBudget) flushPage();
    }
  }

  flushPage();
  if (pages.isEmpty) {
    pages.add(cd.copyWith(tableLines: _sourceCaseDiaryLines(cd)));
  }
  return pages;
}

  String _shortPsName(String ps) => ps
      .replaceAll('Police Station', 'থানা')
      .replaceAll('P.S.', 'থানা')
      .replaceAll(' PS', ' থানা')
      .trim();

  String _displayPsName(String ps, bool isEnglish) {
    if (isEnglish) return ps.trim();
    return _shortPsName(ps);
  }

  pw.Widget _wbOfficialCdHeader({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
    bool continued = false,
  }) {
    final isEnglish = cd.languageCode == 'en';
    final ps = _displayPsName(officer.policeStation, isEnglish);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              isEnglish
                  ? 'West Bengal Form No. 5363'
                  : 'পশ্চিমবঙ্গ ফর্ম নং ৫৩৬৩',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              isEnglish
                  ? 'Year ${DateTime.now().year}'
                  : 'সন ${DateTime.now().year}',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            isEnglish
                ? 'CASE DIARY UNDER SECTION 192 BNSS${continued ? ' (Continued)' : ''}'
                : 'বিএনএসএস-এর ১৯২ ধারার অধীন কেস ডায়েরি${continued ? ' (চলমান)' : ''}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            isEnglish
                ? '(P.R.B. Form No. 43 — See Regulation 229)'
                : '(পি.আর.বি ফর্ম নং ৪৩ — বিধি ২২৯ দ্রষ্টব্য)',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                isEnglish ? 'Police Station: $ps' : 'থানা: -$ps',
                style: _cdTopStyle(),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                isEnglish
                    ? 'District: ${officer.district}'
                    : 'জেলা: -${officer.district}',
                style: _cdTopStyle(),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                isEnglish
                    ? 'FIR/Case No.: ${caseFile.psCaseNo}'
                    : 'প্রথম সংবাদ নং: -${caseFile.psCaseNo}',
                style: _cdTopStyle(),
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                isEnglish
                    ? 'Date: ${caseFile.caseDate}'
                    : 'তারিখ: -${caseFile.caseDate}',
                style: _cdTopStyle(),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                isEnglish
                    ? 'Sections: ${caseFile.sections}'
                    : 'ধারা: -${caseFile.sections}',
                style: _cdTopStyle(),
              ),
            ),
          ],
        ),
        pw.Text(
          isEnglish
              ? 'Name of complainant: ${caseFile.complainantName}'
              : 'অভিযোগকারীর নাম: -${caseFile.complainantName}',
          style: _cdTopStyle(),
        ),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                isEnglish
                    ? 'Case Diary No.: ${cd.cdNumber}'
                    : 'কেস ডায়েরি নং: -${cd.cdNumber}',
                style: _cdTopStyle(),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                isEnglish ? 'Date: ${cd.cdDate}' : 'তারিখ: -${cd.cdDate}',
                style: _cdTopStyle(),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.TextStyle _cdTopStyle() =>
      pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold);

  pw.Widget _wbOfficialCdStatusRow(bool isEnglish) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(1.1),
      },
      children: [
        pw.TableRow(
          children: [
            _officialCell(
              isEnglish
                  ? 'Arrested and forwarded to Court'
                  : 'গ্রেপ্তার করে আদালতে প্রেরিত',
              center: true,
              fontSize: 11,
            ),
            _officialCell(
              isEnglish
                  ? 'Arrested and released on bail'
                  : 'গ্রেপ্তার করে জামিনে মুক্ত।',
              center: true,
              fontSize: 11,
            ),
            _officialCell(
              isEnglish ? 'Absconding' : 'পলাতক।',
              center: true,
              fontSize: 11,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _wbOfficialCdContinuousTable(
    CdEntry cd,
    OfficerProfile officer,
  ) {
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
                      : 'এফআইআর অনুলিপি গ্রহণ\n+\nসংক্ষিপ্ত ঘটনা')
                  : (isEnglish ? 'Further investigation' : 'পরবর্তী তদন্ত'),
              proceedings: cd.body,
            ),
          ];

    final leftEntryColumn = lines.map((line) => line.noAndHour).join('\n\n\n');
    final placeColumn = lines.map((line) => line.placeOfEntry).join('\n\n\n');
    final synopsisColumn = lines.map((line) => line.synopsis).join('\n\n\n');
    final proceedingsColumn = lines
        .map((line) => line.proceedings)
        .where((text) => text.trim().isNotEmpty)
        .join('\n\n');

    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.90),
        1: pw.FlexColumnWidth(7.10),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(8, 3, 8, 3),
              child: pw.Text(
                isEnglish ? 'Particulars of Enquiry' : 'তদন্তের বিবরণ।',
                style: pw.TextStyle(
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 22),
          ],
        ),
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
                pw.TableRow(
                  children: [
                    _officialCell(
                      isEnglish ? 'Entry No.\nand time' : 'এন্ট্রি নং ও\nসময়',
                      center: true,
                      fontSize: 9.4,
                    ),
                    _officialCell(
                      isEnglish ? 'Place of\nentry' : 'এন্ট্রির\nস্থান',
                      center: true,
                      fontSize: 9.4,
                    ),
                    _officialCell(
                      isEnglish ? 'Synopsis of\nentry' : 'এন্ট্রির\nসারাংশ',
                      center: true,
                      fontSize: 9.4,
                    ),
                  ],
                ),
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.top,
                  children: [
                    _officialCell(
                      leftEntryColumn,
                      center: true,
                      fontSize: 9.4,
                      minHeight: 520,
                    ),
                    _officialCell(
                      placeColumn,
                      center: true,
                      fontSize: 9.4,
                      minHeight: 520,
                    ),
                    _officialCell(
                      synopsisColumn,
                      center: true,
                      fontSize: 9.4,
                      minHeight: 520,
                    ),
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
                    pw.Text(
                      proceedingsColumn,
                      style: const pw.TextStyle(fontSize: 10.2),
                      textAlign: pw.TextAlign.justify,
                    ),
                    pw.SizedBox(height: 18),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            isEnglish ? 'Submitted' : 'নিবেদিত',
                            style: const pw.TextStyle(fontSize: 10.5),
                          ),
                          pw.SizedBox(height: 28),
                          pw.Text(
                            '(${officer.name})',
                            style: const pw.TextStyle(fontSize: 10.5),
                          ),
                          pw.Text(
                            officer.rank,
                            style: const pw.TextStyle(fontSize: 10.5),
                          ),
                          pw.Text(
                            _displayPsName(
                              officer.policeStation,
                              isEnglish,
                            ),
                            style: const pw.TextStyle(fontSize: 10.5),
                          ),
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

  pw.Widget _wbOfficialCdSignature({
    required OfficerProfile officer,
    bool isEnglish = false,
  }) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, right: 80),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              isEnglish ? 'Submitted' : 'নিবেদিত',
              style: const pw.TextStyle(fontSize: 10.5),
            ),
            pw.SizedBox(height: 28),
            pw.Text(
              '(${officer.name})',
              style: const pw.TextStyle(fontSize: 10.5),
            ),
            pw.Text(
              officer.rank,
              style: const pw.TextStyle(fontSize: 10.5),
            ),
            pw.Text(
              _displayPsName(officer.policeStation, isEnglish),
              style: const pw.TextStyle(fontSize: 10.5),
            ),
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


  Future<Uint8List> buildCaseDiaryBundlePdf({
  required OfficerProfile officer,
  required CaseFile caseFile,
  required List<CdEntry> cds,
}) async {
  final doc = pw.Document(theme: await _pdfTheme());
  final sortedCds = List<CdEntry>.from(cds)
    ..sort((a, b) => a.cdNumber.compareTo(b.cdNumber));

  for (final cd in sortedCds) {
    final pageCds = _caseDiaryPageCds(cd);
    for (var pageIndex = 0; pageIndex < pageCds.length; pageIndex++) {
      final pageCd = pageCds[pageIndex];
      final isEnglish = pageCd.languageCode == 'en';
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _wbOfficialCdHeader(
                officer: officer,
                caseFile: caseFile,
                cd: pageCd,
                continued: pageIndex > 0,
              ),
              _wbOfficialCdStatusRow(isEnglish),
              pw.Expanded(
                child: _wbOfficialCdContinuousTable(pageCd, officer),
              ),
            ],
          ),
        ),
      );
    }
  }

  return doc.save();
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
          _centerBold('বিএনএসএস-এর ১৮০ ধারায় লিপিবদ্ধ সাক্ষীর বিবৃতি'),
          pw.SizedBox(height: 16),
          pw.Text('মামলার রেফারেন্স: ${officer.policeStation} থানা মামলা নং ${caseFile.psCaseNo}, তারিখ ${caseFile.caseDate}, ধারা ${caseFile.sections}'),
          pw.SizedBox(height: 8),
          pw.Text('সাক্ষীর নাম: ${statement.witnessName}'),
          pw.Text('সাক্ষীর বিবরণ: ${statement.witnessDetails}'),
          pw.Text('বিবৃতির ধরন: ${statement.statementType}'),
          pw.SizedBox(height: 14),
          pw.Text(statement.body, style: const pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('সাক্ষীর স্বাক্ষর/বাম হাতের ছাপ/ডান হাতের ছাপ'),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('লিপিবদ্ধকারী'),
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
    final isEnglish = form.languageCode == 'en';

    if (isEnglish) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(46, 34, 46, 34),
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          build: (context) => [
            _centerBold(form.title),
            pw.SizedBox(height: 10),
            pw.Text(
              'Reference: ${officer.policeStation} Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate}, U/S ${caseFile.sections}',
              style: const pw.TextStyle(fontSize: 10.5),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              body,
              style: const pw.TextStyle(fontSize: 11.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 28),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Submitted by,'),
                  pw.SizedBox(height: 24),
                  pw.Text(officer.name),
                  pw.Text(officer.rank),
                  pw.Text('${officer.policeStation}, ${officer.district}'),
                  if (officer.mobile.trim().isNotEmpty)
                    pw.Text('Mobile: ${officer.mobile}'),
                ],
              ),
            ),
          ],
        ),
      );
      return doc.save();
    }

    final is35 = form.templateId == 'bnss_35_3';
    final is94 = form.templateId == 'bnss_94' ||
        form.templateId == 'medical_exam' ||
        form.templateId == 'bht_injury';
    final isForwarding = form.templateId == 'forwarding';
    final isCdrCaf = form.templateId == 'cdr_caf';
    final isFsl = form.templateId == 'fsl';

    if (isFsl) {
      _addFslPackageOfficialPages(doc, officer, caseFile, body);
      return doc.save();
    }
    if (isCdrCaf) {
      _addCdrCafOfficialPages(doc, officer, caseFile, body);
      return doc.save();
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(46, 30, 46, 30),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'পৃষ্ঠা ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (context) {
          if (is35) return _notice35Pdf(officer, caseFile, body);
          if (isForwarding) return _forwardingPdf(officer, caseFile, body);
          if (is94) return _notice94Pdf(officer, caseFile, body);
          return [
            _centerBold(form.title),
            pw.SizedBox(height: 10),
            pw.Text(
              'মামলার সূত্র: ${officer.policeStation} থানা মামলা নং ${caseFile.psCaseNo}, তারিখ ${caseFile.caseDate}, ধারা ${caseFile.sections}',
              style: const pw.TextStyle(fontSize: 10.5),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              body,
              style: const pw.TextStyle(fontSize: 11.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 26),
            _rightOfficerBlock(officer),
          ];
        },
      ),
    );
    return doc.save();
  }

  List<String> _splitChunks(String text, {int max = 820}) {
    final clean = text.trim();
    if (clean.isEmpty) return [''];
    final out = <String>[];
    var rest = clean;
    while (rest.length > max) {
      var cut = rest.lastIndexOf(' ', max);
      if (cut < 250) cut = max;
      out.add(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trimLeft();
    }
    if (rest.isNotEmpty) out.add(rest);
    return out;
  }

  List<List<String>> _parsePipeRows(String raw, int count, {required List<String> fallback}) {
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return [fallback];
    return lines.map((line) {
      final parts = line.split('|').map((e) => e.trim()).toList();
      while (parts.length < count) {
        parts.add('');
      }
      return parts.take(count).toList();
    }).toList();
  }

  pw.TableRow _tableRow(List<String> cells, {bool header = false, double fontSize = 9.4}) {
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: cells
          .map((text) => pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(fontSize: fontSize, fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal),
                  textAlign: header ? pw.TextAlign.center : pw.TextAlign.left,
                ),
              ))
          .toList(),
    );
  }

  void _addCdrCafOfficialPages(pw.Document doc, OfficerProfile officer, CaseFile caseFile, String body) {
    final ref = '${_shortPsName(officer.policeStation)} মামলা নং-${caseFile.psCaseNo}, তারিখ-${caseFile.caseDate}, ধারা-${caseFile.sections}';
    final gist = _extractFormField(body, 'সংক্ষিপ্ত ঘটনা', fallback: caseFile.firGist.isEmpty ? '____________________________________________________________' : caseFile.firGist);
    final mobile = _extractFormField(body, 'প্রয়োজনীয় মোবাইল/আইএমইআই', fallback: '____________________________');
    final user = _extractFormField(body, 'প্রকৃত ব্যবহারকারী/সংশ্লিষ্টতা', fallback: '____________________________');
    final justification = _extractFormField(body, 'প্রয়োজনীয়তার যুক্তি', fallback: '____________________________');
    final dateRange = _extractFormField(body, 'সিডিআর-এর সময়সীমা', fallback: '____________ থেকে ____________ পর্যন্ত');
    final sdr = _extractFormField(body, 'এসডিআর প্রয়োজন', fallback: 'হ্যাঁ / না');
    final caf = _extractFormField(body, 'সিএএফ প্রয়োজন', fallback: 'হ্যাঁ / না');
    final imei = _extractFormField(body, 'আইএমইআই অনুসন্ধানের সময়সীমা', fallback: '---');
    final other = _extractFormField(body, 'অন্যান্য বিষয়', fallback: 'প্রযোজ্য নয়');
    final ioName = _extractFormField(body, 'তদন্তকারী অফিসারের নাম', fallback: '${officer.rank} ${officer.name}');
    final ioPhone = _extractFormField(body, 'তদন্তকারী অফিসারের ফোন', fallback: officer.mobile);
    final rows = <pw.Widget>[
      _twoColRow('থানা/আউটপোস্টের নাম', _shortPsName(officer.policeStation)),
      _twoColRow('মামলার রেফারেন্স/জিডিই নং', ref),
    ];
    final gistParts = _splitChunks(gist, max: 760);
    for (var i = 0; i < gistParts.length; i++) {
      rows.add(_twoColRow(i == 0 ? 'মামলা/জিডিই-এর সংক্ষিপ্ত ঘটনা' : 'মামলা/জিডিই-এর সংক্ষিপ্ত ঘটনা (চলমান)', gistParts[i], fontSize: 9.3));
    }
    rows.addAll([
      _twoColRow('প্রয়োজনীয় মোবাইল নং/আইএমইআই নং', mobile),
      _twoColRow('মোবাইল/আইএমইআই-এর প্রকৃত ব্যবহারকারীর নাম ও মামলায় সংশ্লিষ্টতা', user, fontSize: 9.6),
      _twoColRow('মামলা/জিডিই-তে উক্ত মোবাইল/আইএমইআই প্রয়োজন হওয়ার যুক্তি', justification, fontSize: 9.6),
      _twoColRow('প্রয়োজনীয় সিডিআর (কল ডিটেলস রিপোর্ট)-এর সময়সীমা', dateRange),
      _twoColRow('প্রয়োজনীয় এসডিআর (সাবস্ক্রাইবার ডিটেলস রিপোর্ট)', sdr),
      _twoColRow('প্রয়োজনীয় সিএএফ (কাস্টমার অ্যাপ্লিকেশন ফর্ম)', caf),
      _twoColRow('প্রয়োজনীয় আইএমইআই অনুসন্ধানের সময়সীমা', imei),
      _twoColRow('তদন্তকারী/অনুসন্ধানকারী অফিসারের নাম', ioName),
      _twoColRow('তদন্তকারী/অনুসন্ধানকারী অফিসারের ফোন নং', ioPhone),
      _twoColRow('অন্যান্য বিষয়', other),
      pw.SizedBox(height: 26),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('নিবেদিত', style: const pw.TextStyle(fontSize: 11))),
    ]);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 24, 32, 24),
      build: (_) => [
        pw.Text('প্রতি: পুলিশ সুপার, ${officer.district} মারফত ওসি, এসওজি সেল, ${officer.district} মারফত এসডিপিও, কালনা', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 12),
        pw.Text('প্রেরক: আইসি, ${_shortPsName(officer.policeStation)}', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 18),
        pw.Center(child: pw.Text('সিডিআর/এসডিআর/সিএএফ-এর রিকুইজিশন', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))),
        pw.SizedBox(height: 8),
        ...rows,
      ],
    ));
  }

  void _addFslPackageOfficialPages(pw.Document doc, OfficerProfile officer, CaseFile caseFile, String body) {
    final ref = '${_shortPsName(officer.policeStation)} মামলা নং ${caseFile.psCaseNo}, তারিখ ${caseFile.caseDate}, ধারা ${caseFile.sections}';
    final natureCrime = _extractFormField(body, 'অপরাধের প্রকৃতি', fallback: caseFile.firGist.isEmpty ? 'মামলার সংক্ষিপ্ত ঘটনা হলো ________________________________________________।' : caseFile.firGist);
    final exhibitsRaw = _extractFormField(body, 'আলামতসমূহ', fallback: _extractFormField(body, 'আলামতের বিবরণ', fallback: 'ক | একটি সিলমোহরযুক্ত প্যাকেট/জার/পাত্র, যার মধ্যে ________________________________ আছে বলে উল্লেখ | __________ তারিখে ________________________________ স্থান থেকে ${officer.rank} ${officer.name} কর্তৃক জব্দ | মাননীয় সিজেএম/ম্যাজিস্ট্রেট, ${officer.district} | পরীক্ষার পরে রাষ্ট্রের অনুকূলে বাজেয়াপ্ত/ফেরতযোগ্য'));
    final exam = _extractFormField(body, 'প্রয়োজনীয় পরীক্ষার প্রকৃতি', fallback: 'আলামত চিহ্ন “ক”-তে প্রাসঙ্গিক পদার্থ/বিষ/রক্ত/বীর্য/রাসায়নিক/জৈব চিহ্ন শনাক্ত করা যায় কি না।');
    final accusedRaw = _extractFormField(body, 'হেফাজতে থাকা ব্যক্তিবর্গ', fallback: _extractFormField(body, 'হেফাজতে থাকা ব্যক্তি', fallback: '${caseFile.accusedName} | পেশা | বয়স | লিঙ্গ | গ্রেপ্তারের তারিখ ও সময় | বিচারবিভাগীয়/পুলিশ হেফাজত/জামিন/পলাতক | বিজ্ঞ আদালত'));
    final fslOffice = _extractFormField(body, 'এফএসএল কার্যালয়', fallback: 'দপ্তর প্রধান ও সহকারী পরিচালক\nআঞ্চলিক ফরেনসিক বিজ্ঞানাগার\nশংকরপুর, দুর্গাপুর\nপশ্চিম বর্ধমান, ৭১৩২১২');
    final court = _extractFormField(body, 'আদালত', fallback: 'বিজ্ঞ সিজেএম/ম্যাজিস্ট্রেট, ${officer.district}');
    final contact = _extractFormField(body, 'তদন্তকারী অফিসার/থানার যোগাযোগের বিবরণ', fallback: 'তদন্তকারী অফিসারের নাম: ${officer.name}\nপদবি: ${officer.rank}\nমোবাইল: ${officer.mobile}\nথানা: ${officer.policeStation}\nজেলা: ${officer.district}');
    final exhibits = _parsePipeRows(exhibitsRaw, 5, fallback: ['ক', 'একটি সিলমোহরযুক্ত প্যাকেট/জার/পাত্র, যার মধ্যে ________________________________ আছে বলে উল্লেখ।', '__________ তারিখে ________________________________ স্থান থেকে ${officer.rank} ${officer.name} কর্তৃক জব্দ।', court, 'পরীক্ষার পরে রাষ্ট্রের অনুকূলে বাজেয়াপ্ত/ফেরতযোগ্য']);
    final accusedRows = _parsePipeRows(accusedRaw, 7, fallback: [caseFile.accusedName.isEmpty ? '____________________' : caseFile.accusedName, 'পেশা', 'বয়স', 'লিঙ্গ', 'গ্রেপ্তারের তারিখ ও সময়', 'বিচারবিভাগীয়/পুলিশ হেফাজত/জামিন/পলাতক', court]);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
      build: (_) => [
        pw.Text('পশ্চিমবঙ্গ ফর্ম নং–৫২০৩', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 8),
        pw.Center(child: pw.Text('পশ্চিমবঙ্গ পুলিশ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 12),
        pw.Text('মামলা নং: ${caseFile.psCaseNo}  তারিখ ${caseFile.caseDate}', style: const pw.TextStyle(fontSize: 10.5)),
        pw.Text('PS:- ${_shortPsName(officer.policeStation)}', style: const pw.TextStyle(fontSize: 10.5)),
        pw.Text('আইনের ধারা: ${caseFile.sections}        জেলা–${officer.district}', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('১। অপরাধের প্রকৃতি', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 4),
        ..._splitLongText(natureCrime, chunkSize: 850),
        pw.SizedBox(height: 14),
        _submittedOfficerBlock(officer),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
      build: (_) => [
        pw.Center(child: pw.Text('২। পরীক্ষার জন্য প্রেরিত আলামতের তালিকা', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: .5),
          columnWidths: const {0: pw.FlexColumnWidth(.75), 1: pw.FlexColumnWidth(2.7), 2: pw.FlexColumnWidth(2.1), 3: pw.FlexColumnWidth(1.55), 4: pw.FlexColumnWidth(1.55)},
          children: [
            _tableRow(['লেবেল নং', 'আলামতের বিবরণ', 'কীভাবে, কখন ও কার দ্বারা পাওয়া/জব্দ', 'আলামতের মালিকানা', 'মন্তব্য'], header: true, fontSize: 8.7),
            ...exhibits.map((e) => _tableRow(['আলামত- “${e[0]}”', e[1], e[2], e[3], e[4]], fontSize: 8.5)),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Center(child: pw.Text('৩। প্রয়োজনীয় পরীক্ষার প্রকৃতি', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 4),
        ..._splitLongText(exam, chunkSize: 850),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 28),
      build: (_) => [
        pw.Center(child: pw.Text('৪। হেফাজতে থাকা ব্যক্তিদের বিবরণ', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: .5),
          columnWidths: const {0: pw.FlexColumnWidth(.55), 1: pw.FlexColumnWidth(2.2), 2: pw.FlexColumnWidth(1.05), 3: pw.FlexColumnWidth(.65), 4: pw.FlexColumnWidth(.65), 5: pw.FlexColumnWidth(1.25), 6: pw.FlexColumnWidth(1.25), 7: pw.FlexColumnWidth(1.25)},
          children: [
            _tableRow(['ক্রমিক নং', 'পূর্ণ নাম', 'পেশা', 'বয়স', 'লিঙ্গ', 'গ্রেপ্তারের তারিখ ও সময়', 'জামিনে নাকি হেফাজতে', 'আদালত'], header: true, fontSize: 8.2),
            ...accusedRows.asMap().entries.map((entry) => _tableRow(['${entry.key + 1}', ...entry.value], fontSize: 8.1)),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('………………………………………\nতদন্তকারী অফিসারের স্বাক্ষর ও পদমর্যাদা\nতারিখ…………………', style: const pw.TextStyle(fontSize: 10.5))),
        pw.SizedBox(height: 18),
        pw.Text('মেমো নং……………..               তারিখ………..২০………', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 8),
        pw.Text('প্রেরিত\n$fslOffice', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 12),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('সিল', style: const pw.TextStyle(fontSize: 10.5)), pw.Text(court, style: const pw.TextStyle(fontSize: 10.5))]),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
      build: (_) => [
        pw.Text('প্রত্যয়ন করা যাচ্ছে যে, পশ্চিমবঙ্গ সরকারের আঞ্চলিক ফরেনসিক বিজ্ঞানাগারের দপ্তর প্রধান ও সহকারী পরিচালক রাষ্ট্র বনাম ${caseFile.accusedName.isEmpty ? '____________________' : caseFile.accusedName}, ধারা ${caseFile.sections} মামলার সূত্রে প্রেরিত আলামত পরীক্ষা করার এবং প্রয়োজনে পরীক্ষার জন্য আলামত খোলা বা অংশবিশেষ পৃথক/অপসারণ করার ক্ষমতাপ্রাপ্ত।', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 18),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('তারিখ………………\nস্থান…………..', style: const pw.TextStyle(fontSize: 10.5)), pw.Text('স্বাক্ষর………………………………………….\nসিজেএম/ম্যাজিস্ট্রেট', style: const pw.TextStyle(fontSize: 10.5))]),
        pw.SizedBox(height: 18),
        pw.Text('মাননীয় মুখ্য বিচারবিভাগীয় ম্যাজিস্ট্রেট/ম্যাজিস্ট্রেটের স্বাক্ষরের জন্য প্রত্যয়িত এবং আলামতসহ আঞ্চলিক ফরেনসিক বিজ্ঞানাগারের দপ্তর প্রধান ও সহকারী পরিচালকের নিকট প্রেরিত।', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
      build: (_) => [
        pw.Center(child: pw.Text('আলামত চালান', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 10),
        pw.Text('প্রতি\n$fslOffice\n\nমারফত $court\nরেফারেন্স:- $ref', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 10),
        pw.Text('মহাশয়,\nউপরোক্ত মামলার তদন্তের স্বার্থে পরীক্ষা ও মতামতের জন্য নিম্নলিখিত আলামতসমূহ প্রেরণ করা হলো।\n\nঅনুগ্রহ করে আলামতগুলি গ্রহণ করে প্রাপ্তিস্বীকার করবেন।', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 10),
        ...exhibits.asMap().entries.map((entry) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 5), child: pw.Text('${entry.key + 1}) আলামত চিহ্ন “${entry.value[0]}” ---- ${entry.value[1]}', style: const pw.TextStyle(fontSize: 10.5)))),
        pw.SizedBox(height: 16),
        _submittedOfficerBlock(officer),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
      build: (_) => [
        pw.Text(contact, style: const pw.TextStyle(fontSize: 10.5)),
      ],
    ));

    for (var i = 0; i < exhibits.length; i++) {
      final e = exhibits[i];
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
        build: (_) => [
          pw.Center(child: pw.Text(i == 0 ? 'লেবেল' : 'লেবেল - আলামত ${e[0]}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 8),
          pw.Text('প্রতি\n$fslOffice\n\nমারফত $court\n\nরেফারেন্স:- $ref\n\nবস্তুর বিবরণ।\nআলামত চিহ্ন “${e[0]}” ---- ${e[1]}\n\nলেবেলযুক্ত ও প্রস্তুত করেছেন -', style: const pw.TextStyle(fontSize: 10.5)),
          pw.SizedBox(height: 16),
          _submittedOfficerBlock(officer),
        ],
      ));
    }
  }

  String _extractFormField(String body, String key, {String fallback = ''}) {
    final pattern = RegExp('^' + RegExp.escape(key) + r'\s*:\s*(.*)$', multiLine: true, caseSensitive: false);
    final match = pattern.firstMatch(body);
    if (match == null) return fallback;
    final value = (match.group(1) ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  pw.Widget _twoColRow(String left, String right, {double leftFlex = 1.0, double rightFlex = 1.25, double fontSize = 10.5}) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),
      columnWidths: {
        0: pw.FlexColumnWidth(leftFlex),
        1: pw.FlexColumnWidth(rightFlex),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(left, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(right, style: pw.TextStyle(fontSize: fontSize))),
          ],
        ),
      ],
    );
  }

  List<pw.Widget> _cdrCafOfficialPdf(OfficerProfile officer, CaseFile caseFile, String body) {
    final ref = '${_shortPsName(officer.policeStation)} মামলা নং-${caseFile.psCaseNo}, তারিখ-${caseFile.caseDate}, ধারা-${caseFile.sections}';
    final gist = _extractFormField(body, 'সংক্ষিপ্ত ঘটনা', fallback: caseFile.firGist.isEmpty ? '____________________________________________________________' : caseFile.firGist);
    final mobile = _extractFormField(body, 'প্রয়োজনীয় মোবাইল/আইএমইআই', fallback: '____________________________');
    final user = _extractFormField(body, 'প্রকৃত ব্যবহারকারী/সংশ্লিষ্টতা', fallback: '____________________________');
    final justification = _extractFormField(body, 'প্রয়োজনীয়তার যুক্তি', fallback: '____________________________');
    final dateRange = _extractFormField(body, 'সিডিআর-এর সময়সীমা', fallback: '____________ থেকে ____________ পর্যন্ত');
    final sdr = _extractFormField(body, 'এসডিআর প্রয়োজন', fallback: 'হ্যাঁ / না');
    final caf = _extractFormField(body, 'সিএএফ প্রয়োজন', fallback: 'হ্যাঁ / না');
    final imei = _extractFormField(body, 'আইএমইআই অনুসন্ধানের সময়সীমা', fallback: '---');
    final other = _extractFormField(body, 'অন্যান্য বিষয়', fallback: 'প্রযোজ্য নয়');
    final ioName = _extractFormField(body, 'তদন্তকারী অফিসারের নাম', fallback: '${officer.rank} ${officer.name}');
    final ioPhone = _extractFormField(body, 'তদন্তকারী অফিসারের ফোন', fallback: officer.mobile);

    return [
      pw.Text('প্রতি: পুলিশ সুপার, ${officer.district} মারফত ওসি, এসওজি সেল, ${officer.district} মারফত এসডিপিও, কালনা', style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 14),
      pw.Text('প্রেরক: আইসি, ${_shortPsName(officer.policeStation)}', style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 20),
      pw.Center(child: pw.Text('সিডিআর/এসডিআর/সিএএফ-এর রিকুইজিশন', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))),
      pw.SizedBox(height: 8),
      _twoColRow('থানা/আউটপোস্টের নাম', _shortPsName(officer.policeStation)),
      _twoColRow('মামলার রেফারেন্স/জিডিই নং', ref),
      _twoColRow('মামলা/জিডিই-এর সংক্ষিপ্ত ঘটনা', gist, fontSize: 10.0),
      _twoColRow('প্রয়োজনীয় মোবাইল নং/আইএমইআই নং', mobile),
      _twoColRow('মোবাইল/আইএমইআই-এর প্রকৃত ব্যবহারকারীর নাম ও মামলায় সংশ্লিষ্টতা', user),
      _twoColRow('মামলা/জিডিই-তে উক্ত মোবাইল/আইএমইআই প্রয়োজন হওয়ার যুক্তি', justification),
      _twoColRow('প্রয়োজনীয় সিডিআর (কল ডিটেলস রিপোর্ট)-এর সময়সীমা', dateRange),
      _twoColRow('প্রয়োজনীয় এসডিআর (সাবস্ক্রাইবার ডিটেলস রিপোর্ট)', sdr),
      _twoColRow('প্রয়োজনীয় সিএএফ (কাস্টমার অ্যাপ্লিকেশন ফর্ম)', caf),
      _twoColRow('প্রয়োজনীয় আইএমইআই অনুসন্ধানের সময়সীমা', imei),
      _twoColRow('তদন্তকারী/অনুসন্ধানকারী অফিসারের নাম', ioName),
      _twoColRow('তদন্তকারী/অনুসন্ধানকারী অফিসারের ফোন নং', ioPhone),
      _twoColRow('অন্যান্য বিষয়', other),
      pw.SizedBox(height: 26),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('নিবেদিত', style: const pw.TextStyle(fontSize: 11))),
    ];
  }

  List<pw.Widget> _splitLongText(String text, {int chunkSize = 950, double fontSize = 10.5}) {
    final clean = text.trim().replaceAll('\r', '');
    if (clean.isEmpty) return [pw.Text('')];
    final widgets = <pw.Widget>[];
    var rest = clean;
    while (rest.length > chunkSize) {
      var cut = rest.lastIndexOf('\n\n', chunkSize);
      if (cut < 300) cut = rest.lastIndexOf('\n', chunkSize);
      if (cut < 300) cut = chunkSize;
      final part = rest.substring(0, cut).trim();
      widgets.add(pw.Text(part, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.justify));
      widgets.add(pw.SizedBox(height: 10));
      rest = rest.substring(cut).trimLeft();
    }
    widgets.add(pw.Text(rest, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.justify));
    return widgets;
  }

  List<pw.Widget> _fslPackageOfficialPdf(OfficerProfile officer, CaseFile caseFile, String body) {
    final ref = '${_shortPsName(officer.policeStation)} মামলা নং ${caseFile.psCaseNo}, তারিখ ${caseFile.caseDate}, ধারা ${caseFile.sections}';
    final natureCrime = _extractFormField(body, 'অপরাধের প্রকৃতি', fallback: caseFile.firGist.isEmpty ? 'মামলার সংক্ষিপ্ত ঘটনা হলো ________________________________________________।' : caseFile.firGist);
    final exhibit = _extractFormField(body, 'আলামতের বিবরণ', fallback: 'আলামত চিহ্ন "ক" ---- একটি সিলমোহরযুক্ত প্যাকেট/জার/পাত্র, যার মধ্যে ________________________________ আছে বলে উল্লেখ।');
    final found = _extractFormField(body, 'কীভাবে পাওয়া/জব্দ', fallback: '__________ তারিখে ________________________________ স্থান থেকে ${officer.rank} ${officer.name} কর্তৃক জব্দ।');
    final exam = _extractFormField(body, 'প্রয়োজনীয় পরীক্ষার প্রকৃতি', fallback: 'আলামত চিহ্ন "ক"-তে প্রাসঙ্গিক পদার্থ/বিষ/রক্ত/বীর্য/রাসায়নিক/জৈব চিহ্ন শনাক্ত করা যায় কি না।');
    final accused = _extractFormField(body, 'হেফাজতে থাকা ব্যক্তি', fallback: '____________________________');
    final fslOffice = _extractFormField(body, 'এফএসএল কার্যালয়', fallback: 'দপ্তর প্রধান ও সহকারী পরিচালক\nআঞ্চলিক ফরেনসিক বিজ্ঞানাগার\nশংকরপুর, দুর্গাপুর\nপশ্চিম বর্ধমান, ৭১৩২১২');
    final court = _extractFormField(body, 'আদালত', fallback: 'বিজ্ঞ সিজেএম/ম্যাজিস্ট্রেট, ${officer.district}');

    final widgets = <pw.Widget>[];
    widgets.addAll([
      pw.Text('পশ্চিমবঙ্গ ফর্ম নং–৫২০৩', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 8),
      pw.Center(child: pw.Text('পশ্চিমবঙ্গ পুলিশ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 12),
      pw.Text('মামলা নং: ${caseFile.psCaseNo}  তারিখ ${caseFile.caseDate}', style: const pw.TextStyle(fontSize: 10.5)),
      pw.Text('PS:- ${_shortPsName(officer.policeStation)}', style: const pw.TextStyle(fontSize: 10.5)),
      pw.Text('আইনের ধারা: ${caseFile.sections}        জেলা–${officer.district}', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 10),
      pw.Center(child: pw.Text('১। অপরাধের প্রকৃতি', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 4),
      ..._splitLongText(natureCrime, chunkSize: 850),
      pw.SizedBox(height: 16),
      _submittedOfficerBlock(officer),
      pw.NewPage(),
      pw.Center(child: pw.Text('২। পরীক্ষার জন্য প্রেরিত আলামতের তালিকা', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Table(border: pw.TableBorder.all(width: .5), columnWidths: const {0: pw.FlexColumnWidth(.8), 1: pw.FlexColumnWidth(2.6), 2: pw.FlexColumnWidth(2.3), 3: pw.FlexColumnWidth(1.7), 4: pw.FlexColumnWidth(1.7)}, children: [
        pw.TableRow(children: [_cell('লেবেল নং', bold: true), _cell('আলামতের বিবরণ', bold: true), _cell('কীভাবে, কখন ও কার দ্বারা পাওয়া/জব্দ', bold: true), _cell('আলামতের মালিকানা', bold: true), _cell('মন্তব্য', bold: true)]),
        pw.TableRow(children: [_cell('আলামত–"ক"'), _cell(exhibit), _cell(found), _cell(court), _cell('পরীক্ষার পরে রাষ্ট্রের অনুকূলে বাজেয়াপ্ত/ফেরতযোগ্য')]),
      ]),
      pw.SizedBox(height: 14),
      pw.Center(child: pw.Text('৩। প্রয়োজনীয় পরীক্ষার প্রকৃতি', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 4),
      ..._splitLongText(exam, chunkSize: 800),
      pw.NewPage(),
      pw.Center(child: pw.Text('৪। হেফাজতে থাকা ব্যক্তিদের বিবরণ', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      _twoColRow('পূর্ণ নাম/বিবরণ', accused),
      _twoColRow('জামিনে নাকি হেফাজতে', '____________________________'),
      _twoColRow('আদালত', court),
      pw.SizedBox(height: 16),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('তদন্তকারী অফিসারের স্বাক্ষর ও পদবি\nতারিখ: ____________', style: const pw.TextStyle(fontSize: 10.5))),
      pw.SizedBox(height: 18),
      pw.Text('মেমো নং ____________        তারিখ ____________ ২০____', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 8),
      pw.Text('প্রেরিত\n$fslOffice', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 12),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('সিল', style: const pw.TextStyle(fontSize: 10.5)), pw.Text(court, style: const pw.TextStyle(fontSize: 10.5))]),
      pw.NewPage(),
      pw.Text('প্রত্যয়ন করা যাচ্ছে যে, আঞ্চলিক ফরেনসিক বিজ্ঞানাগারের দপ্তর প্রধান ও সহকারী পরিচালক মামলার সূত্রে প্রেরিত আলামত পরীক্ষা করার এবং প্রয়োজন হলে উক্ত পরীক্ষার জন্য আলামত খোলা, অংশবিশেষ পৃথক করা বা অপসারণ করার ক্ষমতাপ্রাপ্ত।', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
      pw.SizedBox(height: 18),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('তারিখ: ____________\nস্থান: ___________', style: const pw.TextStyle(fontSize: 10.5)), pw.Text('স্বাক্ষর: ____________________\nসিজেএম/ম্যাজিস্ট্রেট', style: const pw.TextStyle(fontSize: 10.5))]),
      pw.SizedBox(height: 22),
      pw.Center(child: pw.Text('আলামত চালান', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Text('প্রতি\n$fslOffice\n\nমারফত $court\n\nরেফারেন্স:- $ref', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 8),
      pw.Text('মহাশয়,\nউপরোক্ত মামলার তদন্তের স্বার্থে পরীক্ষা ও মতামতের জন্য নিম্নলিখিত আলামত/আলামতসমূহ প্রেরণ করা হলো। অনুগ্রহ করে প্রাপ্তিস্বীকার করবেন।', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
      pw.SizedBox(height: 8),
      pw.Text('১) $exhibit', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 16),
      _submittedOfficerBlock(officer),
      pw.NewPage(),
      pw.Center(child: pw.Text('লেবেল', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Text('প্রতি\n$fslOffice\n\nমারফত $court\n\nরেফারেন্স:- $ref\n\nবস্তুর বিবরণ:\n$exhibit\n\nলেবেলযুক্ত ও প্রস্তুত করেছেন -', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 16),
      _submittedOfficerBlock(officer),
      pw.SizedBox(height: 24),
      pw.Center(child: pw.Text('লেবেল — প্রতিলিপি', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Text('প্রতি\n$fslOffice\n\nমারফত $court\n\nরেফারেন্স:- $ref\n\nবস্তুর বিবরণ:\n$exhibit\n\nলেবেলযুক্ত ও প্রস্তুত করেছেন -', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 16),
      _submittedOfficerBlock(officer),
    ]);
    return widgets;
  }

  List<pw.Widget> _notice35Pdf(OfficerProfile officer, CaseFile caseFile, String body) => [
        pw.Center(child: pw.Text('পুলিশের নিকট হাজির হওয়ার নোটিশ', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text('[বিএনএসএস-এর ৩৫(৩) ধারা অনুযায়ী]', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('ক্রমিক\nনং.............', style: const pw.TextStyle(fontSize: 10.5)),
          pw.Text('সংযোজনী–ক', style: const pw.TextStyle(fontSize: 11)),
        ]),
        pw.SizedBox(height: 12),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(_shortPsName(officer.policeStation), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 10),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11.2), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 28),
        _submittedOfficerBlock(officer),
      ];

  List<pw.Widget> _notice94Pdf(OfficerProfile officer, CaseFile caseFile, String body) => [
        pw.Center(child: pw.Text('বিএনএসএস, ২০২৩-এর ৯৪ ধারার নোটিশ', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 18),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11.5), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 30),
        _rightOfficerBlock(officer),
      ];

  List<pw.Widget> _forwardingPdf(OfficerProfile officer, CaseFile caseFile, String body) => [
        pw.Text('মাননীয় ${officer.courtName}-এর আদালতে', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text('জিআরও, কালনা আদালত মারফত', style: const pw.TextStyle(fontSize: 11))),
        pw.SizedBox(height: 22),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11.3), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 24),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(child: pw.Text('সংযুক্তি:\n১। মূল এফআইআর।\n২। গ্রেপ্তার মেমো।\n৩। পরিদর্শন মেমো।\n৪। চিকিৎসার স্লিপ।\n৫। গ্রেপ্তার সংক্রান্ত সংবাদ।', style: const pw.TextStyle(fontSize: 10.8))),
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
          pw.Text('নিবেদক,', style: const pw.TextStyle(fontSize: 11)),
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
    final isEnglish = form.languageCode == 'en';
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 36, 42, 36),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            isEnglish
                ? 'Page ${context.pageNumber}/${context.pagesCount}'
                : 'পৃষ্ঠা ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          _centerBold(form.title),
          pw.SizedBox(height: 16),
          pw.Text(
            form.body,
            style: const pw.TextStyle(fontSize: 11.5),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 26),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${officer.rank} ${officer.name}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(officer.policeStation),
                pw.Text(
                  isEnglish
                      ? 'District: ${officer.district}'
                      : 'জেলা: ${officer.district}',
                ),
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
          _centerBold('সূচিসহ ঘটনাস্থলের খসড়া নকশা'),
          pw.SizedBox(height: 6),
          pw.Text('মামলার রেফারেন্স: ${officer.policeStation} থানা মামলা নং ${caseFile.psCaseNo}, তারিখ ${caseFile.caseDate}, ধারা ${caseFile.sections}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('তারিখ: ${sketch.date}', style: const pw.TextStyle(fontSize: 10)),
          if (sketch.poDescription.trim().isNotEmpty) pw.Text('ঘটনাস্থল: ${sketch.poDescription}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),
          pw.Container(
            width: canvasW,
            height: canvasH,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
            child: pw.Stack(
              children: [
                pw.Positioned(top: 8, right: 10, child: pw.Text('উ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
                ...sketch.objects.map((o) => pw.Positioned(
                      left: (o.x.clamp(0.0, 0.95)) * canvasW,
                      top: (o.y.clamp(0.0, 0.95)) * canvasH,
                      child: _pdfSketchObject(o, canvasW, canvasH),
                    )),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('সূচি', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _sketchIndexTable(sketch),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text('উত্তর: ${sketch.north}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(child: pw.Text('দক্ষিণ: ${sketch.south}', style: const pw.TextStyle(fontSize: 10))),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text('পূর্ব: ${sketch.east}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(child: pw.Text('পশ্চিম: ${sketch.west}', style: const pw.TextStyle(fontSize: 10))),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('প্রস্তুতকারী', style: const pw.TextStyle(fontSize: 10)),
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
        ? [const SketchMapObject(id: '', type: SketchObjectType.house, marker: '-', label: 'কোনো বস্তু যোগ করা হয়নি', direction: '', indexDescription: '', x: 0, y: 0, width: 0, height: 0, rotationDeg: 0)]
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
          _cell('চিহ্ন', bold: true),
          _cell('দিক', bold: true),
          _cell('ধরন', bold: true),
          _cell('বিবরণ', bold: true),
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

extension UdInquestPdfService on PdfService {
  Future<Uint8List> buildUdInquestPdf({
    required OfficerProfile officer,
    required UdCase ud,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    pw.TextStyle normal() => const pw.TextStyle(fontSize: 10.2);
    pw.TextStyle bold() => pw.TextStyle(fontSize: 10.2, fontWeight: pw.FontWeight.bold);
    pw.Widget line(String label, String value, {double height = 18}) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: normal()),
            pw.Expanded(child: pw.Container(
              height: height,
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: .35, color: PdfColors.grey600))),
              child: pw.Text(value, style: normal()),
            )),
          ]),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(50, 44, 46, 36),
        build: (context) => [
          pw.Center(child: pw.Text('সুরতহাল ফর্ম', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 16),
          pw.Center(child: pw.Text('বিএনএসএস-এর ১৯৪/১৯৬ ধারা', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 22),
          line('১। জেলা: ', ud.district),
          line('   থানা: ', ud.policeStation),
          line('   তারিখ ও সময়: ', ud.dateTime),
          line('২। এফআইআর/ইউডি নং: ', ud.udNo),
          line('   জিডিই নং: ', ud.gdeNo),
          line('৩(ক)। থানা থেকে দূরত্ব: ', ud.distanceFromPs.isEmpty ? '' : '${ud.distanceFromPs} কিমি'),
          line('   (খ) থানা থেকে দিক: ', ud.directionFromPs),
          line('   (গ) মৃতদেহ পাওয়ার স্থান: ', ud.placeFound, height: 22),
          line('      দ্রাঘিমাংশ: ', ud.longitude),
          line('      অক্ষাংশ: ', ud.latitude),
          line('   (ঘ) মৃতদেহ পাওয়া/সন্ধান পাওয়ার তারিখ: ', ud.deadBodyFoundDate),
          line('      সময়: ', ud.deadBodyFoundTime),
          line('৪। তথ্যদাতার নাম: ', ud.informantName),
          line('      বয়স: ', ud.informantAge),
          line('      লিঙ্গ: ', ud.informantSex),
          line('      ঠিকানা: ', ud.informantAddress, height: 24),
          line('৫। মৃতদেহ শনাক্তকারীর নাম: ', ud.identifiedByName),
          line('      বয়স: ', ud.identifiedByAge),
          line('      লিঙ্গ: ', ud.identifiedBySex),
          line('      সম্পর্ক (যদি থাকে): ', ud.identifiedByRelation),
          line('      ঠিকানা: ', ud.identifiedByAddress, height: 24),
          line('৬। মৃত ব্যক্তির নাম: ', ud.deceasedName),
          line('      লিঙ্গ: পুরুষ/মহিলা: ', ud.deceasedSex),
          line('      আনুমানিক বয়স: ', ud.deceasedAge),
          line('      ঠিকানা: ', ud.deceasedAddress, height: 24),
          line('৭। পোস্টমর্টেম স্টেইনিংসহ মৃতদেহের অবস্থান: ', ud.bodyPosition, height: 42),
          line('৮। মৃতদেহের বিবরণ—দেহের গঠন: ', ud.build),
          line('   উচ্চতা: ', ud.height),
          line('   রিগর মর্টিস: ', ud.rigorMortis),
          line('   গায়ের রং: ', ud.complexion),
          line('   বিকৃতি (যদি থাকে): ', ud.deformities),
          line('   ধর্ম/জাতি/সম্প্রদায়: ', ud.religionRaceCommunity),
          line('৯। শনাক্তকরণ চিহ্ন—দাঁত: ', ud.teeth),
          line('   চোখ: ', ud.eyes),
          line('   ত্বকের বিশেষ চিহ্ন: ', ud.laceDerma),
          line('   তিল: ', ud.mole),
          line('   উল্কি: ', ud.tattoo),
          line('   পোশাক/পরিধেয় বস্ত্র: ', ud.dress, height: 28),
          line('   অন্যান্য বৈশিষ্ট্য (যদি থাকে): ', ud.otherFeatures, height: 24),
          pw.Text('১০। মৃতদেহে পাওয়া বাহ্যিক আঘাতের বিবরণ (যদি থাকে)। প্রয়োজনে পৃথক কাগজ ব্যবহার করুন।', style: normal()),
          line('(ক) মাথা: ', ud.injuryHead),
          line('(খ) মুখ: ', ud.injuryFace),
          line('(গ) ঘাড়: ', ud.injuryNeck),
          line('(ঘ) বুক: ', ud.injuryChest),
          line('(ঙ) পেট: ', ud.injuryStomach),
          line('(চ) কাঁধ: ', ud.injuryShoulder),
          line('(ছ) ডান হাত: ', ud.injuryRightHand),
          line('(জ) বাঁ হাত: ', ud.injuryLeftHand),
          line('(ঝ) ডান পা: ', ud.injuryRightLeg),
          line('(ঞ) বাঁ পা: ', ud.injuryLeftLeg),
          line('(ট) গোপনাঙ্গ: ', ud.injuryPrivateParts),
          line('(ঠ) পিঠ: ', ud.injuryBack),
          line('(ড) অন্যান্য আঘাত: ', ud.injuryOther),
          pw.SizedBox(height: 20),
          pw.Text('১১। নির্গমন/স্রাবের ধরন:', style: normal()),
          line('(ক) নাসারন্ধ্র: ', ud.nostrils),
          line('(খ) কান/চোখ: ', ud.earsEyes),
          line('(গ) মুখ: ', ud.mouth),
          line('(ঘ) পুরুষাঙ্গ/যোনি: ', ud.penisVagina),
          line('(ঙ) মলদ্বার: ', ud.anus),
          pw.SizedBox(height: 14),
          line('১২। ব্যবহৃত অস্ত্রের প্রকৃতি ও আঘাত সৃষ্টির সম্ভাব্য পদ্ধতি সম্পর্কে মতামত: ', ud.weaponOpinion, height: 36),
          line('১৩। ফাঁসি/শ্বাসরোধের ক্ষেত্রে গলার দাগ, দড়ি ও গিঁটের বিবরণ: ', ud.ligatureDescription, height: 36),
          line('১৪। মৃত ব্যক্তির হাত বা দেহের কোনো অংশে পাওয়া ঘাস, খড়, চুল ইত্যাদি বহিরাগত পদার্থের বিবরণ: ', ud.foreignMaterial, height: 36),
          line('১৫। ঘটনাস্থলের বিবরণ: ', ud.poDescription, height: 32),
          line('১৬। ঘটনাস্থলে পাওয়া অপরাধের অস্ত্র, অলংকার ও অন্যান্য সামগ্রীর বিবরণ: ', ud.articlesAtPo, height: 32),
          line('১৭। মৃত্যুর সম্ভাব্য কারণ সম্পর্কে মতামত: ', ud.probableCauseOfDeath, height: 26),
          line('১৮। মন্তব্য (মৃতদেহের অবস্থা ও অপরাধ সম্পর্কিত অন্যান্য প্রাসঙ্গিক তথ্য): ', ud.remarks, height: 38),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            pw.Expanded(child: line('১৯। সাক্ষী (১)-এর নাম/ঠিকানা: ', ud.witness1NameAddress, height: 22)),
            pw.SizedBox(width: 16),
            pw.Expanded(child: line('স্বাক্ষর: ', '', height: 22)),
          ]),
          pw.Row(children: [
            pw.Expanded(child: line('(২) ', ud.witness2NameAddress, height: 22)),
            pw.SizedBox(width: 16),
            pw.Expanded(child: line('(২) ', '', height: 22)),
          ]),
          pw.SizedBox(height: 14),
          pw.Text('সংক্ষিপ্ত ঘটনা (প্রয়োজনে পৃথক কাগজ সংযুক্ত করুন)', style: normal()),
          pw.Container(
            height: 70,
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: .35, color: PdfColors.grey600))),
            child: pw.Text(ud.briefFacts, style: normal()),
          ),
          pw.SizedBox(height: 40),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('তদন্তকারী অফিসারের স্বাক্ষর', style: normal()),
              pw.SizedBox(height: 18),
              pw.Text('নাম: ${officer.name}', style: normal()),
              pw.Text('পদবি: ${officer.rank}', style: normal()),
            ]),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
