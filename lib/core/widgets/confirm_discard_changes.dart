import 'package:flutter/material.dart';

Future<bool> confirmDiscardChanges(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Değişikliklerden vazgeçilsin mi?'),
            content: const Text('Kaydedilmeyen bilgiler kaybolacak.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('DÜZENLEMEYE DEVAM ET'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('VAZGEÇ VE ÇIK'),
              ),
            ],
          ),
    ) ??
    false;
