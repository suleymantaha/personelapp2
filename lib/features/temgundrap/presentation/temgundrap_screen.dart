import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
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

  Future<void> _refresh() async {
    setState(_reload);
    await _documents;
  }

  Future<void> _openForm([TemgundrapDocument? document]) async {
    final changed =
        await context.push<bool>('/temgundrap/form', extra: document);
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
              child: const Text('VAZGEÇ')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SİL')),
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
            icon: Icons.edit_outlined),
        ModernActionOption(
            value: 'delete',
            title: 'Sil',
            subtitle: 'Bu çizelgeyi kalıcı olarak kaldır',
            icon: Icons.delete_outline,
            isDestructive: true),
      ],
    );
    if (!mounted) return;
    if (action == 'edit') await _openForm(document);
    if (action == 'delete') await _delete(document);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('TEMGÜNDRAP')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openForm,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni Çizelge'),
        ),
        body: FutureBuilder<List<TemgundrapDocument>>(
          future: _documents,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.cloud_off_outlined,
                title: 'Kayıtlar yüklenemedi',
                message: '${snapshot.error}',
                action: FilledButton.icon(
                    onPressed: () => setState(_reload),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('TEKRAR DENE')),
              );
            }
            final documents = snapshot.data ?? const [];
            if (documents.isEmpty) {
              return _MessageState(
                icon: Icons.table_chart_outlined,
                title: 'Henüz TEMGÜNDRAP çizelgesi yok',
                message: 'İlk operasyon takip çizelgesini oluşturun.',
                action: FilledButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('YENİ ÇİZELGE')),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth < 600 ? 16.0 : 28.0;
                final contentWidth =
                    (constraints.maxWidth - padding * 2).clamp(0.0, 1180.0);
                final columns = contentWidth >= 960
                    ? 3
                    : contentWidth >= 620
                        ? 2
                        : 1;
                final compact = constraints.maxWidth < 600;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(padding, 20, padding, 18),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 1180),
                                  child: _OverviewHeader(
                                      documents: documents, compact: compact))),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(padding, 0, padding, 104),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  mainAxisExtent: compact ? 148 : 178),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _DocumentCard(
                              document: documents[index],
                              compact: compact,
                              onOpen: () => context.push('/temgundrap/preview',
                                  extra: documents[index]),
                              onActions: () =>
                                  _showDocumentActions(documents[index]),
                            ),
                            childCount: documents.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({required this.documents, required this.compact});
  final List<TemgundrapDocument> documents;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final operations =
        documents.fold<int>(0, (sum, item) => sum + item.operations.length);
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          context.accentOrOlive.withValues(alpha: .18),
          Theme.of(context).colorScheme.surfaceContainerLow
        ]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.accentOrOlive.withValues(alpha: .22)),
      ),
      child: Wrap(
        spacing: compact ? 12 : 18,
        runSpacing: compact ? 12 : 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CircleAvatar(
              radius: compact ? 22 : 27,
              backgroundColor: context.accentOrOlive,
              child: const Icon(Icons.map_outlined, color: Colors.white)),
          ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: 210, maxWidth: compact ? 290 : 550),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Operasyon takip çizelgeleri',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 18 : null)),
                  const SizedBox(height: 4),
                  Text(
                      'Güncel ve geçmiş TEMGÜNDRAP kayıtlarını tek noktadan yönetin.',
                      style: TextStyle(color: context.textSecondary)),
                ]),
          ),
          _SummaryPill(
              icon: Icons.description_outlined,
              value: '${documents.length}',
              label: 'Çizelge'),
          _SummaryPill(
              icon: Icons.shield_outlined,
              value: '$operations',
              label: 'Operasyon'),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 19, color: context.accentOrOlive),
          const SizedBox(width: 7),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: context.textSecondary)),
        ]),
      );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard(
      {required this.document,
      required this.compact,
      required this.onOpen,
      required this.onActions});
  final TemgundrapDocument document;
  final bool compact;
  final VoidCallback onOpen;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    padding: EdgeInsets.all(compact ? 8 : 10),
                    decoration: BoxDecoration(
                        color: context.accentOrOlive.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.description_outlined,
                        color: context.accentOrOlive)),
                const Spacer(),
                IconButton(
                    key: Key('temgundrap-actions-${document.id}'),
                    tooltip: 'Çizelge işlemleri',
                    onPressed: onActions,
                    icon: const Icon(Icons.more_horiz_rounded)),
              ]),
              const Spacer(),
              Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(document.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17)),
              SizedBox(height: compact ? 5 : 8),
              Row(children: [
                Icon(Icons.shield_outlined,
                    size: 18, color: context.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                    child: Text('${document.operations.length} operasyon',
                        style: TextStyle(color: context.textSecondary))),
                _StatusBadge(isDraft: document.isDraft),
              ]),
            ]),
          ),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isDraft});
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final color = isDraft ? Colors.orange.shade800 : context.accentOrOlive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(99)),
      child: Text(isDraft ? 'TASLAK' : 'TAMAMLANDI',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState(
      {required this.icon,
      required this.title,
      required this.message,
      required this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: context.accentOrOlive.withValues(alpha: .12),
                      shape: BoxShape.circle),
                  child: Icon(icon, size: 44, color: context.accentOrOlive)),
              const SizedBox(height: 18),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondary)),
              const SizedBox(height: 22),
              action,
            ]),
          ),
        ),
      );
}
