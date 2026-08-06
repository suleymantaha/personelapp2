import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';

class TemgundrapPreviewScreen extends StatelessWidget {
  const TemgundrapPreviewScreen({required this.document, super.key});

  final TemgundrapDocument document;

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('dd MMMM yyyy', 'tr_TR').format(document.date).toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('TEMGÜNDRAP Önizleme')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) return _mobile(date);
          return _table(date);
        },
      ),
    );
  }

  Widget _mobile(String date) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(document.unitTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$date TARİHİNDE PLANLANAN OPERASYON TAKİP ÇİZELGESİ',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ...document.operations.asMap().entries.map((entry) {
            final item = entry.value;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key + 1}. OPERASYON',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Divider(),
                      _line('Çıkaran Birlik', item.issuingUnit),
                      _line('Operasyon Bölgesi', item.operationArea),
                      _line('Kuvveti', item.forceDescription),
                      _line('Operasyon Komutanı', item.commander.displayText),
                      _line('Mevcut', '${item.totalStrength} personel'),
                      _line('Başlama',
                          TemgundrapFormatters.militaryDateTime(item.startAt)),
                      _line('Bitiş',
                          TemgundrapFormatters.militaryDateTime(item.endAt)),
                      _line('Maksat', item.purpose),
                      _line('Açıklama', item.description),
                    ]),
              ),
            );
          }),
        ],
      );

  Widget _table(String date) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(document.unitTitle,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('$date TARİHİNDE PLANLANAN OPERASYON TAKİP ÇİZELGESİ'),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('S.NO')),
                DataColumn(label: Text('ÇIKARAN BİRLİK')),
                DataColumn(label: Text('OPERASYON BÖLGESİ')),
                DataColumn(label: Text('KUVVETİ')),
                DataColumn(label: Text('OPERASYON KOMUTANI')),
                DataColumn(label: Text('MEVCUT')),
                DataColumn(label: Text('BAŞLAMA ZAMANI')),
                DataColumn(label: Text('BİTİŞ ZAMANI')),
                DataColumn(label: Text('OPERASYON MAKSADI')),
                DataColumn(label: Text('AÇIKLAMA')),
              ],
              rows: document.operations.asMap().entries.map((entry) {
                final item = entry.value;
                return DataRow(cells: [
                  DataCell(Text('${entry.key + 1}')),
                  DataCell(SizedBox(width: 140, child: Text(item.issuingUnit))),
                  DataCell(
                      SizedBox(width: 140, child: Text(item.operationArea))),
                  DataCell(
                      SizedBox(width: 160, child: Text(item.forceDescription))),
                  DataCell(SizedBox(
                      width: 160, child: Text(item.commander.displayText))),
                  DataCell(Text('${item.totalStrength}')),
                  DataCell(Text(
                      TemgundrapFormatters.militaryDateTime(item.startAt))),
                  DataCell(
                      Text(TemgundrapFormatters.militaryDateTime(item.endAt))),
                  DataCell(Text(item.purpose)),
                  DataCell(SizedBox(width: 260, child: Text(item.description))),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: Column(children: [
              Text(document.approverRank),
              Text(document.approverName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(document.approverDuty),
            ]),
          ),
        ]),
      );

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 135,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ]),
      );
}
