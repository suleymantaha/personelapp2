import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_excel_exporter.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_pdf_exporter.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

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
      body: TurkishFlagWatermarkBackground(
        child: LayoutBuilder(
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
              if (document.approverName.isNotEmpty ||
                  document.approverRank.isNotEmpty ||
                  document.approverDuty.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : 16,
                    12,
                    wide ? 32 : 16,
                    32,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _ApproverCard(document: document),
                  ),
                ),
            ],
          );
        },
      ),
    ),
    );
  }
}

class _ApproverCard extends StatelessWidget {
  const _ApproverCard({required this.document});
  final TemgundrapDocument document;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '(İMZALI)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              if (document.approverName.isNotEmpty)
                Text(
                  document.approverName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              if (document.approverRank.isNotEmpty)
                Text(
                  document.approverRank,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                  ),
                ),
              if (document.approverDuty.isNotEmpty)
                Text(
                  document.approverDuty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      );
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
  Widget build(BuildContext context) {
    Widget action({
      required Key key,
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) =>
        Expanded(
          child: SizedBox(
            height: 68,
            child: FilledButton(
              key: key,
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );

    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          action(
            key: const Key('preview-excel'),
            onPressed: onExcel,
            icon: Icons.table_view_outlined,
            label: 'Excel',
          ),
          const SizedBox(width: 8),
          action(
            key: const Key('preview-share'),
            onPressed: onShare,
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDF Paylaş',
          ),
          const SizedBox(width: 8),
          action(
            key: const Key('preview-print'),
            onPressed: onPrint,
            icon: Icons.print_outlined,
            label: 'Yazdır',
          ),
        ],
      ),
    ));
  }
}
