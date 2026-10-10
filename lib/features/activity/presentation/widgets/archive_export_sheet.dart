import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

enum ArchiveExportType {
  excel,
  pdf,
  print,
  text,
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
    ),
  );
}

class ArchiveExportSheet extends StatefulWidget {
  const ArchiveExportSheet({
    required this.subtitle,
    this.initialTimeRange,
    super.key,
  });

  final String subtitle;
  final String? initialTimeRange;

  @override
  State<ArchiveExportSheet> createState() => _ArchiveExportSheetState();
}

class _ArchiveExportSheetState extends State<ArchiveExportSheet> {
  late final TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(text: widget.initialTimeRange ?? '');
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
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.ios_share_rounded,
                    color: context.accentOrOlive,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.archiveExportSheetTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.accentOrOlive.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.accentOrOlive.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: context.accentOrOlive,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.archiveExportSheetTimeRangeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (_timeController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _timeController.clear()),
                            child: Text(
                              context.l10n.commonClear,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.accentOrOlive,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _timeController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        hintText: context.l10n.archiveExportSheetTimeRangeHint,
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.textSecondary.withValues(alpha: 0.25),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.textSecondary.withValues(alpha: 0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.accentOrOlive),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final preset in const [
                            '06.00-08.00',
                            '08.00-10.00',
                            '20.00-08.00',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                visualDensity: VisualDensity.compact,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                label: Text(
                                  preset,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () {
                                  setState(() => _timeController.text = preset);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.archiveExportSheetTimeRangeNote,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.accentOrOlive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.table_chart_outlined,
                    color: context.accentOrOlive,
                  ),
                ),
                title: Text(
                  context.l10n.archiveExportExcelTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(context.l10n.archiveExportExcelSubtitle),
                onTap: () => _select(ArchiveExportType.excel),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.pdfButtonBg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: context.pdfButtonBg,
                  ),
                ),
                title: Text(
                  context.l10n.archiveExportPdfTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(context.l10n.archiveExportPdfSubtitle),
                onTap: () => _select(ArchiveExportType.pdf),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.print_outlined,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  context.l10n.archiveExportPrintTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(context.l10n.archiveExportPrintSubtitle),
                onTap: () => _select(ArchiveExportType.print),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.textPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.share_outlined,
                    color: context.textPrimary,
                  ),
                ),
                title: Text(
                  context.l10n.archiveExportTextTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(context.l10n.archiveExportTextSubtitle),
                onTap: () => _select(ArchiveExportType.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

