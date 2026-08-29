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
                            child: _StrengthField(
                              fieldKey: Key(
                                  'strength-${temgundrapRankLabels[index]}'),
                              label: temgundrapRankLabels[index],
                              value: values[index],
                              onChanged: (next) {
                                final updated = [...values]..[index] = next;
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

class _StrengthField extends StatefulWidget {
  const _StrengthField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_StrengthField> createState() => _StrengthFieldState();
}

class _StrengthFieldState extends State<_StrengthField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String _textFor(int value) => value == 0 ? '' : '$value';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textFor(widget.value));
    _focusNode = FocusNode()..addListener(_selectValueOnFocus);
  }

  @override
  void didUpdateWidget(covariant _StrengthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = _textFor(widget.value);
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _selectValueOnFocus() {
    if (!_focusNode.hasFocus || _controller.text.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus || _controller.text.isEmpty) return;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_selectValueOnFocus)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: widget.label, hintText: '0'),
      onChanged: (text) => widget.onChanged(int.tryParse(text) ?? 0),
    );
  }
}
