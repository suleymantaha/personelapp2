import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/temgundrap/data/temgundrap_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

class TemgundrapScreen extends StatefulWidget {
  const TemgundrapScreen({super.key});

  @override
  State<TemgundrapScreen> createState() => _TemgundrapScreenState();
}

class _TemgundrapScreenState extends State<TemgundrapScreen> {
  final _repository = TemgundrapRepository();
  late Future<List<TemgundrapDocument>> _documents;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _documents = _repository.getAll();

  Future<void> _openForm([TemgundrapDocument? document]) async {
    final changed = await context.push<bool>(
      '/temgundrap/form',
      extra: document,
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _delete(TemgundrapDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çizelgeyi sil'),
        content: const Text('Bu TEMGÜNDRAP çizelgesi kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SİL'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.delete(document.id);
    if (mounted) setState(_reload);
  }

  Future<void> _showDocumentActions(TemgundrapDocument document) async {
    final action = await showModernActionSheet<String>(
      context,
      title: 'Çizelge İşlemleri',
      subtitle: DateFormat('dd MMMM yyyy', 'tr_TR').format(document.date),
      icon: Icons.description_outlined,
      options: const [
        ModernActionOption(
          value: 'edit',
          title: 'Düzenle',
          subtitle: 'Çizelge bilgilerini güncelle',
          icon: Icons.edit_outlined,
        ),
        ModernActionOption(
          value: 'delete',
          title: 'Sil',
          subtitle: 'Bu çizelgeyi kalıcı olarak kaldır',
          icon: Icons.delete_outline,
          isDestructive: true,
        ),
      ],
    );
    if (!mounted) return;
    if (action == 'edit') await _openForm(document);
    if (action == 'delete') await _delete(document);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TEMGÜNDRAP')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Çizelge'),
      ),
      body: ResponsiveCenter(
        child: FutureBuilder<List<TemgundrapDocument>>(
          future: _documents,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Kayıtlar yüklenemedi: ${snapshot.error}'),
              );
            }
            final documents = snapshot.data ?? const [];
            if (documents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: 72,
                      color: context.accentOrOlive,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz TEMGÜNDRAP çizelgesi yok.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text('İlk operasyon takip çizelgesini oluşturun.'),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final document = documents[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.accentOrOlive.withValues(
                        alpha: .12,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: context.accentOrOlive,
                      ),
                    ),
                    title: Text(
                      DateFormat('dd MMMM yyyy', 'tr_TR').format(document.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${document.operations.length} operasyon • ${document.isDraft ? 'Taslak' : 'Tamamlandı'}',
                    ),
                    onTap: () =>
                        context.push('/temgundrap/preview', extra: document),
                    trailing: IconButton(
                      key: Key('temgundrap-actions-${document.id}'),
                      tooltip: 'Çizelge işlemleri',
                      onPressed: () => _showDocumentActions(document),
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
