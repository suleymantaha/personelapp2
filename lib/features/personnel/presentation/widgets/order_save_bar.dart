import 'package:flutter/material.dart';

class OrderSaveBar extends StatelessWidget {
  const OrderSaveBar(
      {super.key,
      required this.dirty,
      required this.saving,
      required this.onCancel,
      required this.onSave});
  final bool dirty, saving;
  final VoidCallback? onCancel, onSave;
  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (dirty)
              const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Değişiklikler kaydedilmedi',
                      style: TextStyle(fontSize: 12))),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: onCancel, child: const Text('Vazgeç'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: onSave,
                      child: Text(saving ? 'Kaydediliyor…' : 'Kaydet')))
            ]),
          ])));
}
