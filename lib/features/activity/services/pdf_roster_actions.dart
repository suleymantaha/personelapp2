part of 'pdf_roster_exporter.dart';

Future<void> pdfShareRoster({
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
  PdfRosterStyle style = PdfRosterStyle.verticalBlock,
}) async {
  final pdf = await pdfGenerateRoster(
    faaliyetAdi: faaliyetAdi,
    tarih: tarih,
    rows: rows,
    style: style,
  );

  final dir = await getTemporaryDirectory();
  final sanitizedTitle = faaliyetAdi.replaceAll(RegExp(r'[^\w\.-]'), '_');
  final exportId = DateTime.now().millisecondsSinceEpoch;
  final file = File(
    '${dir.path}/${sanitizedTitle}_Listesi_${tarih}_$exportId.pdf',
  );
  await file.writeAsBytes(await pdf.save());

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      text: '$faaliyetAdi - Resmi İsim Listesi PDF Dökümanı',
    ),
  );
}

Future<void> pdfPrintRoster({
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
  PdfRosterStyle style = PdfRosterStyle.verticalBlock,
}) async {
  final pdf = await pdfGenerateRoster(
    faaliyetAdi: faaliyetAdi,
    tarih: tarih,
    rows: rows,
    style: style,
  );
  final bytes = await pdf.save();
  await Printing.layoutPdf(
    name: '$faaliyetAdi - $tarih',
    onLayout: (_) async => bytes,
  );
}

/// Displays a modal bottom sheet to select from 3 PDF styles and exports/shares the PDF
Future<void> pdfShowStylePickerAndShare(
  BuildContext context, {
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
  bool printDirectly = false,
}) async {
  final selectedStyle = await showModalBottomSheet<PdfRosterStyle>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PDF Şablon Görünüm Stili Seçiniz',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Çıktı almak istediğiniz resmi PDF düzenini seçin:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigoAccent,
                  child: Icon(
                    Icons.dashboard_customize,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Stil 1: Dikey Blok Mimarisi (VIP Format)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: const Text(
                  'Birlik ve özel görev alanlarını kesintisiz blok görünümünde gösterir.',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () => Navigator.pop(ctx, PdfRosterStyle.verticalBlock),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(
                    Icons.table_rows,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Stil 2: Akıllı Sayfa Kırılımı Formatı',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: const Text(
                  'Klasik 5 sütunlu tablo. Her satır tam çizgili ve sayfa geçişlerine dayanıklıdır.',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () => Navigator.pop(ctx, PdfRosterStyle.smartPageChunk),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.view_day, color: Colors.white, size: 20),
                ),
                title: const Text(
                  'Stil 3: Askeri Şerit Başlık Formatı',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: const Text(
                  'Her Birlik/Tim grubunun ilk satırını gri bantla vurgular.',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () => Navigator.pop(ctx, PdfRosterStyle.headerBand),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (selectedStyle != null && context.mounted) {
    if (printDirectly) {
      await pdfPrintRoster(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
        style: selectedStyle,
      );
    } else {
      await pdfShareRoster(
        faaliyetAdi: faaliyetAdi,
        tarih: tarih,
        rows: rows,
        style: selectedStyle,
      );
    }
  }
}

Future<void> pdfShowStylePickerAndPrint(
  BuildContext context, {
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
}) {
  return pdfShowStylePickerAndShare(
    context,
    faaliyetAdi: faaliyetAdi,
    tarih: tarih,
    rows: rows,
    printDirectly: true,
  );
}
