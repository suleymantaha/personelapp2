import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_excel_exporter.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_pdf_exporter.dart';

class TemgundrapPreviewScreen extends StatelessWidget {
  const TemgundrapPreviewScreen({
    required this.document,
    this.onPrint,
    this.onShare,
    this.onExcel,
    super.key,
  });

  final TemgundrapDocument document;
  final Future<void> Function()? onPrint;
  final Future<void> Function()? onShare;
  final Future<void> Function()? onExcel;

  Future<void> _print() =>
      onPrint?.call() ?? TemgundrapPdfExporter.printDocument(document);
  Future<void> _share() =>
      onShare?.call() ?? TemgundrapPdfExporter.shareDocument(document);
  Future<void> _shareExcel() =>
      onExcel?.call() ?? TemgundrapExcelExporter.share(document);

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMMM yyyy', 'tr_TR').format(document.date);
    return Scaffold(
      appBar: AppBar(
        title: const Text('TEMGÜNDRAP Önizleme'),
        actions: [
          IconButton(
            key: const Key('preview-print-icon'),
            tooltip: 'Yazdır',
            onPressed: _print,
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            key: const Key('preview-share-icon'),
            tooltip: 'PDF paylaş',
            onPressed: _share,
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      bottomNavigationBar: _OutputBar(
        onPrint: _print,
        onShare: _share,
        onExcel: _shareExcel,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 16,
                  20,
                  wide ? 32 : 16,
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: _DocumentHeader(document: document, date: date),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 16,
                  0,
                  wide ? 32 : 16,
                  28,
                ),
                sliver: wide
                    ? SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.18,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _OperationCard(
                            index: index,
                            operation: document.operations[index],
                          ),
                          childCount: document.operations.length,
                        ),
                      )
                    : SliverList.separated(
                        itemCount: document.operations.length,
                        itemBuilder: (context, index) => _OperationCard(
                          index: index,
                          operation: document.operations[index],
                        ),
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({required this.document, required this.date});
  final TemgundrapDocument document;
  final String date;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.accentOrOlive.withValues(alpha: .16),
              context.colorScheme.surfaceContainerLow,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: context.accentOrOlive.withValues(alpha: .25)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.accentOrOlive,
              child:
                  const Icon(Icons.description_outlined, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.unitTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$date • ${document.operations.length} operasyon',
                    style: TextStyle(color: context.textSecondary),
                  ),
                ],
              ),
            ),
            Chip(label: Text(document.isDraft ? 'TASLAK' : 'TAMAMLANDI')),
          ],
        ),
      );
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.index, required this.operation});
  final int index;
  final TemgundrapOperation operation;
  @override
  Widget build(BuildContext context) => Card(
        key: Key('preview-operation-$index'),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        context.accentOrOlive.withValues(alpha: .12),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: context.accentOrOlive,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      operation.operationArea,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.groups_2_outlined, size: 17),
                    label: Text('${operation.totalStrength}'),
                  ),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.account_balance_outlined,
                label: 'Çıkaran birlik',
                value: operation.issuingUnit,
              ),
              _InfoRow(
                icon: Icons.shield_outlined,
                label: 'Komutan',
                value: operation.commander.displayText,
              ),
              _InfoRow(
                icon: Icons.route_outlined,
                label: 'Kuvvet',
                value: operation.forceDescription,
              ),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Zaman',
                value:
                    '${TemgundrapFormatters.militaryDateTime(operation.startAt)}\n${TemgundrapFormatters.militaryDateTime(operation.endAt)}',
              ),
              _InfoRow(
                icon: Icons.flag_outlined,
                label: 'Maksat',
                value: operation.purpose,
              ),
              if (operation.description.isNotEmpty)
                _InfoRow(
                  icon: Icons.notes_outlined,
                  label: 'Açıklama',
                  value: operation.description,
                ),
            ],
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: context.accentOrOlive),
            const SizedBox(width: 10),
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

class _OutputBar extends StatelessWidget {
  const _OutputBar({
    required this.onPrint,
    required this.onShare,
    required this.onExcel,
  });
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final VoidCallback onExcel;
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('preview-excel'),
                  onPressed: onExcel,
                  icon: const Icon(Icons.table_view_outlined),
                  label: const Text('EXCEL'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('preview-share'),
                  onPressed: onShare,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const FittedBox(child: Text('PDF PAYLAŞ')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('preview-print'),
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('YAZDIR'),
                ),
              ),
            ],
          ),
        ),
      );
}
