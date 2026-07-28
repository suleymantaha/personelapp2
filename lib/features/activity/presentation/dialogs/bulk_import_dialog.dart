import 'dart:async';
import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_activity_import_preparer.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/features/activity/presentation/widgets/personnel_picker_sheet.dart';

class BulkImportDialog extends StatefulWidget {
  const BulkImportDialog({
    required this.database,
    required this.activityRepository,
    super.key,
  });
  final AppDatabase database;
  final ActivityRepository activityRepository;

  @override
  State<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<BulkImportDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  List<ParsedActivityBlock> _parsedBlocks = [];
  List<PersonelTableData> _allPersonnel = [];
  List<TimTableData> _allSquads = [];
  bool _isParsing = false;
  bool _isSaving = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_loadPersonnel());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonnel() async {
    final list =
        await widget.database.select(widget.database.personelTable).get();
    final squads = await widget.database.select(widget.database.timTable).get();
    if (!mounted) return;
    setState(() {
      _allPersonnel = list;
      _allSquads = squads;
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
        if (_parsedBlocks.isNotEmpty) {
          _tabController.animateTo(
            1,
          ); // Auto switch to Preview tab on mobile/desktop
        }
      });
    } finally {
      setState(() {
        _isParsing = false;
      });
    }
  }

  Future<void> _saveAllToFaaliyet() async {
    if (_parsedBlocks.isEmpty) return;

    final preparation = BulkActivityImportPreparer.prepare(_parsedBlocks);
    if (preparation.duplicates.isNotEmpty) {
      await _showDuplicatePersonnelDialog(preparation.duplicates);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.activityRepository.createActivitiesWithAssignments(
        preparation.requests,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_parsedBlocks.length} blok → ${preparation.requests.length} '
              'günlük faaliyet '
              'başarıyla eklendi.',
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _showDuplicatePersonnelDialog(
    List<BulkImportDuplicate> duplicates,
  ) {
    final squadNames = {for (final squad in _allSquads) squad.id: squad.timAdi};
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tekrarlanan Personel Var'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aynı personel aynı tarihte birden fazla görevde bulunuyor. '
                  'Aktarmadan önce önizlemedeki tekrarları düzeltin.',
                ),
                const SizedBox(height: 12),
                for (final duplicate in duplicates)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: Text(duplicate.personnelName),
                    subtitle: Text(
                      '${duplicate.date} • '
                      '${squadNames[duplicate.teamId] ?? 'Timsiz'}\n'
                      '${duplicate.assignments.join(' / ')}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ÖNİZLEMEYE DÖN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < 768;
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isKeyboardVisible ? 8 : (isMobile ? 24 : 32),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
          child: SizedBox(
            width: isMobile ? screenWidth : screenWidth * 0.85,
            height: double.infinity,
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  // Dialog Header Banner
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: isKeyboardVisible ? 10 : 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.accentOrOlive,
                          context.accentOrOlive.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.paste_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Metinden Toplu Aktarım',
                                style: TextStyle(
                                  fontSize: isKeyboardVisible ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isKeyboardVisible) ...[
                                const SizedBox(height: 2),
                                const Text(
                                  'WhatsApp / Telegram nöbet listelerini yapıştırıp akıllı ayrıştırın',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // TabBar for Mobile or Split Layout for Desktop/Tablet
                  if (isMobile)
                    TabBar(
                      controller: _tabController,
                      labelColor: context.accentOrOlive,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: context.accentOrOlive,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                          icon: isKeyboardVisible
                              ? null
                              : const Icon(Icons.text_fields),
                          text: '1. Metin Yapıştır',
                        ),
                        Tab(
                          icon: isKeyboardVisible
                              ? null
                              : Badge(
                                  isLabelVisible: _parsedBlocks.isNotEmpty,
                                  label: Text(_parsedBlocks.length.toString()),
                                  child: const Icon(Icons.preview_rounded),
                                ),
                          text: '2. Kart Önizleme',
                        ),
                      ],
                    ),

                  // Main Body Content
                  Expanded(
                    child: isMobile
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              _buildInputSection(
                                isMobile: true,
                                isKeyboardVisible: isKeyboardVisible,
                              ),
                              _buildPreviewSection(isMobile: true),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _buildInputSection(
                                    isMobile: false,
                                    isKeyboardVisible: isKeyboardVisible,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                const VerticalDivider(width: 1),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 6,
                                  child: _buildPreviewSection(isMobile: false),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection({
    required bool isMobile,
    required bool isKeyboardVisible,
  }) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? (isKeyboardVisible ? 12 : 16) : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: context.accentOrOlive,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ham Metni Yapıştırın:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          if (!isKeyboardVisible) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: context.accentOrOlive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tarih, görev türü ve personel listesini içeren mesajı '
                'olduğu gibi yapıştırabilirsiniz.',
                style: TextStyle(
                  color: context.accentOrOlive,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
          SizedBox(height: isKeyboardVisible ? 8 : 10),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 13, height: 1.4),
              cursorColor: context.accentOrOlive,
              scrollPadding: const EdgeInsets.only(bottom: 80),
              decoration: InputDecoration(
                hintText: 'Mesaj metnini buraya yapıştırın…',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.cardBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.cardBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: context.accentOrOlive,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isParsing ? null : _processText,
              icon: _isParsing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                'Metni Ayrıştır ve Kartları Oluştur',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentOrOlive,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.style_rounded,
                    color: context.accentOrOlive,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Faaliyet Kartları (${_parsedBlocks.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (_parsedBlocks.isNotEmpty)
                IconButton(
                  onPressed: () => setState(() => _parsedBlocks.clear()),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  tooltip: 'Tümünü Temizle',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _parsedBlocks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  context.accentOrOlive.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.fact_check_outlined,
                              size: 48,
                              color: context.accentOrOlive,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz Kart Oluşturulmadı',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Soldaki kutuya mesajı yapıştırıp "Metni Ayrıştır" butonuna basın.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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
              onPressed: (_parsedBlocks.isEmpty || _isSaving)
                  ? null
                  : _saveAllToFaaliyet,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                '${_parsedBlocks.length} blok → '
                '${_parsedBlocks.map((block) => block.parsedDate).toSet().length} '
                'günlük faaliyet',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.approvedColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ParsedActivityBlock block, int blockIdx) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.cardBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentOrOlive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    block.parsedTimName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.accentOrOlive,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    block.parsedActivityType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final initial =
                        DateTime.tryParse(block.parsedDate) ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      final formatted =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      setState(() {
                        _parsedBlocks[blockIdx] = block.copyWith(
                          parsedDate: formatted,
                        );
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          block.parsedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (block.parsedTimeRange != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vardiya: ${block.parsedTimeRange}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),

            // Personnel Items
            ...block.personnelList.asMap().entries.map((entry) {
              final pIdx = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.isMatched
                        ? Colors.transparent
                        : Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: context.accentOrOlive.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          '${item.rawIndex}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: context.accentOrOlive,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: Text(
                          '${item.rawRank} ${item.rawName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_right_alt_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      Expanded(
                        flex: 6,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final normalizedTim = block.parsedTimName
                                .toLowerCase()
                                .replaceAll('timi', '')
                                .replaceAll(' ', '');
                            final preferredTimId = _allSquads
                                .where(
                                  (squad) => squad.timAdi
                                      .toLowerCase()
                                      .replaceAll('timi', '')
                                      .replaceAll(' ', '')
                                      .contains(normalizedTim),
                                )
                                .map((squad) => squad.id)
                                .firstOrNull;
                            final person = await showPersonnelPicker(
                              context: context,
                              personnel: _allPersonnel,
                              squads: _allSquads,
                              selectedPersonnelId: item.matchedPersonnelId,
                              preferredTimId:
                                  item.matchedTimId ?? preferredTimId,
                            );
                            if (person != null && mounted) {
                              setState(() {
                                final updatedList =
                                    List<ParsedPersonnelItem>.from(
                                  block.personnelList,
                                );
                                updatedList[pIdx] = item.copyWith(
                                  matchedPersonnelId: person.id,
                                  matchedAdSoyad: person.adSoyad,
                                  matchedRutbe: person.rutbe,
                                  matchedTimId: person.timId,
                                  matchConfidence: 1,
                                );
                                _parsedBlocks[blockIdx] = block.copyWith(
                                  personnelList: updatedList,
                                );
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.isMatched
                                            ? '${item.matchedRutbe} ${item.matchedAdSoyad}'
                                            : 'Personel seçin',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: item.isMatched
                                              ? null
                                              : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.search, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                _MatchStatusIndicator(item: item),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MatchStatusIndicator extends StatelessWidget {
  const _MatchStatusIndicator({required this.item});

  final ParsedPersonnelItem item;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (item.matchConfidence) {
      >= 0.9 when item.isMatched => (
          'Eşleşti',
          context.approvedColor,
          Icons.check_circle_rounded,
        ),
      > 0 when item.isMatched => (
          'Kontrol edin',
          Colors.orange.shade800,
          Icons.help_rounded,
        ),
      _ => (
          'Eşleşmedi',
          Colors.red.shade700,
          Icons.warning_amber_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
