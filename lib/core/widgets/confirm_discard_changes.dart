import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';

Future<bool> confirmDiscardChanges(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(dialogContext.l10n.confirmDiscardTitle),
            content: Text(dialogContext.l10n.confirmDiscardContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(dialogContext.l10n.confirmDiscardContinue),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(dialogContext.l10n.confirmDiscardExit),
              ),
            ],
          ),
    ) ??
    false;
