import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';

class RosterPreviewSigners extends StatelessWidget {
  const RosterPreviewSigners({
    super.key,
    required this.signers,
    required this.busy,
    required this.ready,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
  });

  final List<RosterSigner> signers;
  final bool busy;
  final bool ready;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(int index) onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: const Key('roster-preview-signers-toggle'),
              onTap: onToggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.rosterPreviewSignersTitle,
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in signers.asMap().entries) ...[
                      if (entry.key > 0)
                        Container(
                          width: 1,
                          height: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.value.title, style: text.labelMedium),
                            TextButton.icon(
                              key: Key('edit-roster-signer-${entry.key}'),
                              onPressed: busy || !ready
                                  ? null
                                  : () => onEdit(entry.key),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: Text(context.l10n.commonEdit),
                            ),
                            Text(entry.value.name, style: text.bodyMedium),
                            Text(entry.value.rank, style: text.bodySmall),
                            Text(entry.value.role, style: text.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
