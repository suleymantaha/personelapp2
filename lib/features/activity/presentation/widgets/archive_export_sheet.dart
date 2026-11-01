import 'archive_export_time_options.dart';
import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

enum ArchiveExportType {
  excel,
  image,
  pdf,
  print,
  text,
  temgundrap,
}

class ArchiveExportResult {
  const ArchiveExportResult({
    required this.type,
    this.timeRange,
  });

  final ArchiveExportType type;
  final String? timeRange;
}

Future<ArchiveExportResult?> showArchiveExportSheet(
  BuildContext context, {
  required String subtitle,
  String? initialTimeRange,
  bool showTemgundrap = true,
}) {
  return showModalBottomSheet<ArchiveExportResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => ArchiveExportSheet(
      subtitle: subtitle,
      initialTimeRange: initialTimeRange,
      showTemgundrap: showTemgundrap,
    ),
  );
}

class ArchiveExportSheet extends StatefulWidget {
  const ArchiveExportSheet({
    required this.subtitle,
    this.initialTimeRange,
    this.showTemgundrap = true,
    super.key,
  });

  final String subtitle;
  final String? initialTimeRange;
  final bool showTemgundrap;

  @override
  State<ArchiveExportSheet> createState() => _ArchiveExportSheetState();
}

class _ArchiveExportSheetState extends State<ArchiveExportSheet> {
  late final TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _timeController =
        TextEditingController(text: widget.initialTimeRange ?? '');
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _select(ArchiveExportType type) {
    final raw = _timeController.text.trim();
    Navigator.pop(
      context,
      ArchiveExportResult(
        type: type,
        timeRange: raw.isEmpty ? null : raw,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Çıktı Al', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(widget.subtitle))),
                ArchiveExportTimeOptions(controller: _timeController),
                const SizedBox(height: 8),
                _option(ArchiveExportType.excel, Icons.table_chart_outlined,
                    context.l10n.archiveExportExcelTitle, '.xlsx'),
                _option(ArchiveExportType.image, Icons.image_outlined,
                    context.l10n.rosterImageAction, 'Tek PNG'),
                _option(
                    ArchiveExportType.pdf,
                    Icons.picture_as_pdf_outlined,
                    context.l10n.archiveExportPdfTitle,
                    'Belge düzenini seç ve paylaş'),
                _option(
                    ArchiveExportType.print,
                    Icons.print_outlined,
                    context.l10n.archiveExportPrintTitle,
                    'Belge düzenini seç ve yazdır'),
                _option(
                    ArchiveExportType.text,
                    Icons.share_outlined,
                    context.l10n.archiveExportTextTitle,
                    'Mesajlaşma uygulamaları için'),
                if (widget.showTemgundrap) ...[
                  const Divider(),
                  _option(
                      ArchiveExportType.temgundrap,
                      Icons.assignment_outlined,
                      context.l10n.activityArchiveExportToTemgundrap,
                      'Ayrı rapor akışında düzenlenebilir taslak oluştur'),
                ],
              ]),
        ),
      );

  Widget _option(ArchiveExportType type, IconData icon, String title,
          String subtitle) =>
      Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            key: Key('export-option-${type.name}'),
            leading: Icon(icon, color: context.accentOrOlive),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _select(type),
          ));
}
