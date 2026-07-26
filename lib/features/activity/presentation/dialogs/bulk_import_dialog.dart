import 'package:flutter/material.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/parsed_activity_block.dart';
import '../../domain/parser/bulk_text_parser.dart';
import '../../domain/parser/personnel_fuzzy_matcher.dart';
import '../../data/activity_repository.dart';

class BulkImportDialog extends StatefulWidget {
  final AppDatabase database;
  final ActivityRepository activityRepository;

  const BulkImportDialog({
    super.key,
    required this.database,
    required this.activityRepository,
  });

  @override
  State<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<BulkImportDialog> {
  final TextEditingController _textController = TextEditingController();
  List<ParsedActivityBlock> _parsedBlocks = [];
  List<PersonelTableData> _allPersonnel = [];
  bool _isParsing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPersonnel();
  }

  Future<void> _loadPersonnel() async {
    final list = await widget.database.select(widget.database.personelTable).get();
    setState(() {
      _allPersonnel = list;
    });
  }

  Future<void> _processText() async {
    final rawText = _textController.text;
    if (rawText.trim().isEmpty) return;

    setState(() {
      _isParsing = true;
    });

    try {
      final initialBlocks = BulkTextParser.parse(rawText);
      final fuzzyMatcher = PersonnelFuzzyMatcher(widget.database);
      final matchedBlocks = await fuzzyMatcher.matchBlocks(initialBlocks);

      setState(() {
        _parsedBlocks = matchedBlocks;
      });
    } finally {
      setState(() {
        _isParsing = false;
      });
    }
  }

  Future<void> _saveAllToFaaliyet() async {
    if (_parsedBlocks.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      int successCount = 0;

      for (final block in _parsedBlocks) {
        final title = '${block.parsedTimName} - ${block.parsedActivityType}${block.parsedTimeRange != null ? " (${block.parsedTimeRange})" : ""}';
        
        final payload = block.personnelList
            .where((p) => p.matchedPersonnelId != null)
            .map((p) => {
                  'personelId': p.matchedPersonnelId!,
                  'gorevVeyaIzin': 'GÖREVLİ',
                  'aciklama': block.parsedTimeRange ?? block.parsedActivityType,
                })
            .toList();

        if (payload.isNotEmpty) {
          await widget.activityRepository.createActivityWithAssignments(
            faaliyetAdi: title,
            tarih: block.parsedDate,
            olusturanKullanici: 'Admin (Toplu Aktarım)',
            personnelAssignments: payload,
          );
        }
        successCount++;
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount adet faaliyet ve personelleri başarıyla eklendi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.paste_rounded, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Metinden Toplu Faaliyet Ayrıştırma ve Önizleme',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Raw Text Input
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. Ham Metni Yapıştırın (WhatsApp/Telegram Listesi):',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: 'Metni buraya yapıştırın...\nÖrn:\n6/B Gülüşkür isim listesi\n25.07.2026\n1-J.Asb.Üçvş. Erdem BUYAR...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _isParsing ? null : _processText,
                            icon: _isParsing
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.analytics_outlined),
                            label: const Text('Metni Ayrıştır ve Önizle', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 16),

                  // Right Side: Parsed Preview Blocks
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '2. Tespit Edilen Faaliyet Kartları (${_parsedBlocks.length}):',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            if (_parsedBlocks.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => setState(() => _parsedBlocks.clear()),
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text('Temizle'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _parsedBlocks.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.rule_folder_outlined, size: 64, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Sol tarafa metni yapıştırıp "Ayrıştır ve Önizle" butonuna basın.',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _parsedBlocks.length,
                                  itemBuilder: (context, blockIdx) {
                                    final block = _parsedBlocks[blockIdx];
                                    return _buildPreviewCard(block, blockIdx);
                                  },
                                ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: (_parsedBlocks.isEmpty || _isSaving) ? null : _saveAllToFaaliyet,
                            icon: _isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              'Tümünü Faaliyet Raporuna Aktar (${_parsedBlocks.length} Kart)',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ParsedActivityBlock block, int blockIdx) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    block.parsedTimName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  block.parsedActivityType,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Chip(
                  label: Text(block.parsedDate, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (block.parsedTimeRange != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Vardiya: ${block.parsedTimeRange}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
            const Divider(height: 16),

            // Personnel Items
            ...block.personnelList.asMap().entries.map((entry) {
              final pIdx = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${item.rawIndex}.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Text(
                        '${item.rawRank} ${item.rawName}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
                    Expanded(
                      flex: 5,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: item.matchedPersonnelId,
                          isDense: true,
                          isExpanded: true,
                          hint: Text(
                            '⚠️ Eşleşmedi (${item.rawName})',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('-- Personel Seçin --', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                            ..._allPersonnel.map((p) => DropdownMenuItem<int?>(
                                  value: p.id,
                                  child: Text(
                                    '${p.rutbe} ${p.adSoyad}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                )),
                          ],
                          onChanged: (selectedId) {
                            if (selectedId != null) {
                              final p = _allPersonnel.firstWhere((element) => element.id == selectedId);
                              setState(() {
                                final updatedList = List<ParsedPersonnelItem>.from(block.personnelList);
                                updatedList[pIdx] = item.copyWith(
                                  matchedPersonnelId: p.id,
                                  matchedAdSoyad: p.adSoyad,
                                  matchedRutbe: p.rutbe,
                                  matchedTimId: p.timId,
                                  matchConfidence: 1.0,
                                );
                                _parsedBlocks[blockIdx] = block.copyWith(personnelList: updatedList);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      item.isMatched ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: item.isMatched ? Colors.green : Colors.amber.shade800,
                      size: 18,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
