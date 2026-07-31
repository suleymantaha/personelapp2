import 'package:flutter/material.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class EditActivityBlockDialog extends StatefulWidget {
  const EditActivityBlockDialog({
    required this.block,
    super.key,
  });

  final ParsedActivityBlock block;

  static Future<ParsedActivityBlock?> show(
    BuildContext context,
    ParsedActivityBlock block,
  ) {
    return showModalBottomSheet<ParsedActivityBlock>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => EditActivityBlockDialog(block: block),
    );
  }

  @override
  State<EditActivityBlockDialog> createState() =>
      _EditActivityBlockDialogState();
}

class _EditActivityBlockDialogState extends State<EditActivityBlockDialog> {
  late final TextEditingController _activityController;
  late final TextEditingController _timeController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _activityController =
        TextEditingController(text: widget.block.parsedActivityType);
    _timeController =
        TextEditingController(text: widget.block.parsedTimeRange);
    _selectedDate =
        DateTime.tryParse(widget.block.parsedDate) ?? DateTime.now();
  }

  @override
  void dispose() {
    _activityController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Faaliyet kartını düzenle',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const Key('bulk-edit-activity'),
            controller: _activityController,
            decoration: const InputDecoration(
              labelText: 'Görev / faaliyet adı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('bulk-edit-time'),
            controller: _timeController,
            decoration: const InputDecoration(
              labelText: 'Saat aralığı (isteğe bağlı)',
              hintText: '08:00 - 19:30',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text(
              '${_selectedDate.day.toString().padLeft(2, '0')}.'
              '${_selectedDate.month.toString().padLeft(2, '0')}.'
              '${_selectedDate.year}',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('bulk-edit-save'),
            onPressed: () {
              final activity = _activityController.text.trim();
              if (activity.isEmpty) return;
              final time = _timeController.text.trim();
              Navigator.pop(
                context,
                ParsedActivityBlock(
                  rawTitle: widget.block.rawTitle,
                  parsedTimName: widget.block.parsedTimName,
                  parsedActivityType: activity,
                  parsedDate:
                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  parsedTimeRange: time.isEmpty ? null : time,
                  personnelList: widget.block.personnelList,
                ),
              );
            },
            child: const Text('DEĞİŞİKLİKLERİ UYGULA'),
          ),
        ],
      ),
    );
  }
}
