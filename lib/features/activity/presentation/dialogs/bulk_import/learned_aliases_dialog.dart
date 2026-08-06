import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';

class LearnedAliasesDialog extends StatefulWidget {
  const LearnedAliasesDialog({
    required this.database,
    super.key,
  });

  final AppDatabase database;

  static Future<void> show(BuildContext context, AppDatabase database) {
    return showDialog<void>(
      context: context,
      builder: (_) => LearnedAliasesDialog(database: database),
    );
  }

  @override
  State<LearnedAliasesDialog> createState() => _LearnedAliasesDialogState();
}

class _LearnedAliasesDialogState extends State<LearnedAliasesDialog> {
  final TextEditingController _searchController = TextEditingController();
  late BulkImportLearningService _learningService;
  List<LearnedAliasItem> _allAliases = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _learningService = BulkImportLearningService(widget.database);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _learningService.getAliasList();
    if (mounted) {
      setState(() {
        _allAliases = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAlias(LearnedAliasItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eşleşmeyi Sil'),
        content: Text(
          '\'${item.gorunenTakmaAd}\' ➔ \'${item.personelRutbe ?? ''} ${item.personelAdSoyad}\' '
          'öğrenilmiş takma ad eşleşmesi silinsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('SİL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _learningService.deleteAlias(item.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\'${item.gorunenTakmaAd}\' hafızadan silindi.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allAliases.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = BulkImportLearningService.normalizeName(_searchQuery);
      final rawNorm =
          BulkImportLearningService.normalizeName(item.gorunenTakmaAd);
      final targetNorm =
          BulkImportLearningService.normalizeName(item.personelAdSoyad);
      return rawNorm.contains(q) || targetNorm.contains(q);
    }).toList();
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;
    final radius = isMobile ? 0.0 : 20.0;

    return Dialog(
      insetPadding: isMobile ? EdgeInsets.zero : null,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? size.width : 650,
          maxHeight: isMobile ? size.height : size.height * 0.85,
        ),
        child: SizedBox(
          width: isMobile ? size.width : null,
          height: isMobile ? size.height : null,
          child: SafeArea(
            top: isMobile,
            bottom: isMobile,
            child: Column(
              children: [
                // Üst Başlık Barı (Header Bar)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 12 : 16,
                  ),
                  color: context.accentOrOlive,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sistem Hafızası',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_allAliases.length} Öğrenilmiş İsim Takma Adı',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
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

                // Arama Çubuğu (Search Bar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: isMobile
                          ? 'Yazım veya personel adı ara'
                          : 'Metindeki yazım veya personel adıyla ara...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Liste İçi İçerik (List / Loading / Empty State)
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _searchQuery.isNotEmpty
                                          ? Icons.search_off_rounded
                                          : Icons.auto_awesome_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Aramanıza uygun takma ad bulunamadı.'
                                          : 'Henüz öğrenilmiş bir takma ad bulunmuyor.\n'
                                              'Toplu aktarımlarda onayladığınız eşleşmeler otomatik hafızaya alınır.',
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
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final targetName =
                                    '${item.personelRutbe ?? ''} ${item.personelAdSoyad}'
                                        .trim();

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.cardBorderColor,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: context.accentOrOlive
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.text_snippet_outlined,
                                          size: 18,
                                          color: context.accentOrOlive,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Metindeki ad',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              item.gorunenTakmaAd,
                                              maxLines: 2,
                                              overflow: TextOverflow.fade,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Eşleştiği personel',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              targetName,
                                              maxLines: 2,
                                              overflow: TextOverflow.fade,
                                              style: TextStyle(
                                                color: Colors.grey.shade800,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Takma adı hafızadan sil',
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red.shade400,
                                          size: 20,
                                        ),
                                        onPressed: () => _deleteAlias(item),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

                // Alt Kapat Butonu (Footer)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('KAPAT'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Learned Aliases Dialog Preview')
Widget learnedAliasesDialogPreview() {
  return const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('LearnedAliasesDialog Preview Placeholder'),
      ),
    ),
  );
}
