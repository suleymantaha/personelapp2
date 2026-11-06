import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';

void main() {
  testWidgets('105 short rows and their summary fit on two portrait A4 pages',
      (tester) async {
    for (final style in PdfRosterStyle.values) {
      final pdf = await PdfRosterExporter.generateRosterPdf(
        faaliyetAdi: 'Sentetik Kadro Listesi',
        tarih: '2026-11-06',
        rows: _rows(105),
        style: style,
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      _writeArtifact(style.name, bytes);
      final pages = pdf.document.pdfPageList.pages;
      expect(pages, hasLength(2), reason: style.name);
      for (final page in pages) {
        expect(page.pageFormat.width, PdfPageFormat.a4.width);
        expect(page.pageFormat.height, PdfPageFormat.a4.height);
      }
    }
  });

  testWidgets('wrapped roster fields can require more than two A4 pages',
      (tester) async {
    final pdf = await PdfRosterExporter.generateRosterPdf(
      faaliyetAdi: 'Sentetik Kadro Listesi',
      tarih: '2026-11-06',
      rows: _rows(105, multiline: true),
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
    _writeArtifact('multiline', bytes);
    expect(pdf.document.pdfPageList.pages.length, greaterThan(2));
  });

  testWidgets('a split signed roster supports caller-provided signers',
      (tester) async {
    final pdf = await PdfRosterExporter.generateRosterPdf(
      faaliyetAdi: 'Sentetik İmzalı Liste',
      tarih: '2026-11-06',
      rows: _rows(100),
      includeSignatures: true,
      signers: const [
        RosterSigner('ÖRNEK İMZA 1', 'Sentetik İmzacı A', 'Rütbe A', 'Görev A'),
        RosterSigner('ÖRNEK İMZA 2', 'Sentetik İmzacı B', 'Rütbe B', 'Görev B'),
      ],
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
    expect(pdf.document.pdfPageList.pages, hasLength(2));
    _writeArtifact('signed', bytes);
  });

  testWidgets('a closing summary can require a third page', (tester) async {
    final pdf = await PdfRosterExporter.generateRosterPdf(
      faaliyetAdi: 'Sentetik Kadro Listesi',
      tarih: '2026-11-06',
      rows: _rows(110),
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
    expect(pdf.document.pdfPageList.pages, hasLength(3));
    _writeArtifact('balanced-tail', bytes);
  });
}

void _writeArtifact(String name, List<int> bytes) {
  if (!const bool.fromEnvironment('ROSTER_PDF_ARTIFACTS')) return;
  Directory('build/roster-a4-pdf').createSync(recursive: true);
  File('build/roster-a4-pdf/$name.pdf').writeAsBytesSync(bytes);
}

List<MilitaryRosterRow> _rows(int count, {bool multiline = false}) =>
    List.generate(
      count,
      (index) => MilitaryRosterRow(
        sNu: 0,
        birligi: '${index ~/ 35 + 1} İNCİ TİM',
        rutbe: 'J.UZM.ÇVŞ.',
        adSoyad: 'Sentetik Personel ${index + 1}',
        diger: multiline ? 'Birinci görev\nİkinci görev\nSon görev' : '',
      ),
    );
