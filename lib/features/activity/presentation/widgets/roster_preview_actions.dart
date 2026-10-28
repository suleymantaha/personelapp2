import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';

class RosterPreviewActions extends StatelessWidget {
  const RosterPreviewActions({
    super.key,
    required this.hasRulePreview,
    required this.ruleRowsEmpty,
    required this.busy,
    required this.signaturesReady,
    required this.onRulePreview,
    required this.onRuleExport,
    required this.onRankExport,
  });

  final bool hasRulePreview;
  final bool ruleRowsEmpty;
  final bool busy;
  final bool signaturesReady;
  final VoidCallback onRulePreview;
  final VoidCallback onRuleExport;
  final VoidCallback onRankExport;

  @override
  Widget build(BuildContext context) {
    final canUseRule =
        !busy && (!hasRulePreview || (signaturesReady && !ruleRowsEmpty));
    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              key: const Key('roster-preview-footer'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: hasRulePreview
                      ? const Key('roster-rule-export')
                      : const Key('roster-matrix-rule-preview'),
                  onPressed: canUseRule
                      ? hasRulePreview
                          ? onRuleExport
                          : onRulePreview
                      : null,
                  icon: Icon(hasRulePreview
                      ? Icons.ios_share_outlined
                      : Icons.visibility_outlined),
                  label: Text(busy
                      ? context.l10n.rosterOutputPreparing
                      : hasRulePreview
                          ? context.l10n.rosterRuleExportAction
                          : context.l10n.rosterRulePreviewAction),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('roster-export-rank'),
                  onPressed: busy || !signaturesReady ? null : onRankExport,
                  icon: const Icon(Icons.sort_outlined),
                  label: Text(context.l10n.rosterOutputGetRankOrderedOutput),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
