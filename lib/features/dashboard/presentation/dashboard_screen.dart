import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? true;
    final pendingAsync = ref.watch(pendingAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jandarma Görev Kontrol Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(userSessionProvider.notifier).state = null;
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Card(
              color: AppColors.lightOlive,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.militaryOlive,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hoş Geldiniz, ${session?.username ?? 'Kullanıcı'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Rol: ${isAdmin ? "Birlik Yöneticisi (Admin)" : "Tim Komutanı"}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pending Approvals Warning Banner (Admin Only)
            if (isAdmin)
              pendingAsync.when(
                data: (pendingList) {
                  if (pendingList.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      color: Colors.red.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.red.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded,
                            color: AppColors.rejectedRed, size: 32),
                        title: Text(
                          '${pendingList.length} Görevlendirmede Çakışma / Rapor Var!',
                          style: const TextStyle(
                            color: AppColors.rejectedRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Onaylamak veya reddetmek için dokunun.',
                          style: TextStyle(color: Colors.black87),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: AppColors.rejectedRed),
                        onTap: () => context.push('/pending-approvals'),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, st) => const SizedBox.shrink(),
              ),

            const Text(
              'İşlemler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Navigation Grid Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _MenuCard(
                  icon: Icons.edit_calendar,
                  title: 'Faaliyet Çizelgesi',
                  subtitle: 'Günlük görev gir',
                  color: AppColors.militaryOlive,
                  onTap: () => context.push('/activity-form'),
                ),
                _MenuCard(
                  icon: Icons.grid_on,
                  title: 'Aylık Matris',
                  subtitle: 'Excel / Dağıtım',
                  color: AppColors.accentKhaki,
                  onTap: () => context.push('/monthly-matrix'),
                ),
                _MenuCard(
                  icon: Icons.people_alt,
                  title: 'Personel & Tim',
                  subtitle: isAdmin ? 'Kayıt ve Yetki' : 'Kadro Durumu',
                  color: Colors.blueGrey.shade700,
                  onTap: () => context.push('/personnel-management'),
                ),
                if (isAdmin)
                  _MenuCard(
                    icon: Icons.assignment_turned_in,
                    title: 'Bekleyen Onaylar',
                    subtitle: 'Çakışma denetimi',
                    color: AppColors.pendingYellow,
                    onTap: () => context.push('/pending-approvals'),
                  ),
                _MenuCard(
                  icon: Icons.inventory_2,
                  title: 'Faaliyet Arşivi',
                  subtitle: 'Arama ve İnceleme',
                  color: Colors.brown.shade700,
                  onTap: () => context.push('/activity-archive'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
