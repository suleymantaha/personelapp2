import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

class TemgundrapStrengthEditor extends StatelessWidget {
  const TemgundrapStrengthEditor(
      {required this.value, required this.onChanged, super.key});
  final TemgundrapStrength value;
  final ValueChanged<TemgundrapStrength> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = [
      value.officer,
      value.nco,
      value.specialistGendarmerie,
      value.specialistSergeant
    ];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mevcut',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth >= 700
                      ? (constraints.maxWidth - 36) / 4
                      : (constraints.maxWidth - 12) / 2;
                  return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children:
                          List.generate(temgundrapRankLabels.length, (index) {
                        return SizedBox(
                            width: width,
                            child: TextFormField(
                              key: Key(
                                  'strength-${temgundrapRankLabels[index]}'),
                              initialValue: '${values[index]}',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: InputDecoration(
                                  labelText: temgundrapRankLabels[index]),
                              onChanged: (text) {
                                final updated = [...values]..[index] =
                                    int.tryParse(text) ?? 0;
                                onChanged(TemgundrapStrength(
                                    officer: updated[0],
                                    nco: updated[1],
                                    specialistGendarmerie: updated[2],
                                    specialistSergeant: updated[3]));
                              },
                            ));
                      }));
                }),
                const SizedBox(height: 12),
                Text('TOPLAM: ${value.total}',
                    key: const Key('strength-total'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )));
  }
}
