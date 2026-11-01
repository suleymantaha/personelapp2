import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';

class ArchiveExportTimeOptions extends StatefulWidget {
  const ArchiveExportTimeOptions({super.key, required this.controller});
  final TextEditingController controller;
  @override
  State<ArchiveExportTimeOptions> createState() =>
      _ArchiveExportTimeOptionsState();
}

class _ArchiveExportTimeOptionsState extends State<ArchiveExportTimeOptions> {
  @override
  Widget build(BuildContext context) => ExpansionTile(
        key: const Key('archive-export-time-options'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        initiallyExpanded: widget.controller.text.isNotEmpty,
        leading: const Icon(Icons.schedule),
        title: Text(context.l10n.archiveExportSheetTimeRangeLabel),
        subtitle: Text(widget.controller.text.isEmpty
            ? 'Eklemek için açın'
            : widget.controller.text),
        children: [
          TextField(
              controller: widget.controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  hintText: context.l10n.archiveExportSheetTimeRangeHint,
                  border: const OutlineInputBorder())),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final preset in const [
              '06.00-08.00',
              '08.00-10.00',
              '20.00-08.00'
            ])
              ActionChip(
                  label: Text(preset),
                  onPressed: () =>
                      setState(() => widget.controller.text = preset)),
            if (widget.controller.text.isNotEmpty)
              ActionChip(
                  label: Text(context.l10n.commonClear),
                  onPressed: () => setState(widget.controller.clear)),
          ]),
          const SizedBox(height: 8),
        ],
      );
}
