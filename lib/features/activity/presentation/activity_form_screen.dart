import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key});

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _activityNameController =
      TextEditingController(text: 'Önleyici Kolluk Devriyesi');
  DateTime _selectedDate = DateTime.now();

  // Maps personelId to selected DutyType
  final Map<int, String> _assignments = {};

  void _submitActivity() async {
    final name = _activityNameController.text.trim();
    if (name.isEmpty) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final userSession = ref.read(userSessionProvider);

    final payload = _assignments.entries.map((e) {
      return {
        'personelId': e.key,
        'gorevVeyaIzin': e.value,
        'aciklama': null,
      };
    }).toList();

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir personel için görev seçin.')),
      );
      return;
    }

    final repo = ref.read(activityRepositoryProvider);
    await repo.createActivityWithAssignments(
      faaliyetAdi: name,
      tarih: dateStr,
      olusturanKullanici: userSession?.username ?? 'admin',
      personnelAssignments: payload,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faaliyet Çizelgesi Kaydedildi & Çakışma Denetimi Yapıldı!'),
          backgroundColor: AppColors.approvedGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final personnelAsync = ref.watch(allPersonnelProvider);
    final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faaliyet Çizelgesi Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today,
                    color: AppColors.militaryOlive),
                title: Text('Faaliyet Tarihi: $dateFormatted'),
                subtitle: const Text('Değiştirmek için dokunun'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _activityNameController,
              decoration: const InputDecoration(
                labelText: 'Faaliyet / Devriye Adı',
                prefixIcon: Icon(Icons.local_police),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Personel Görevlendirme Listesi (Kıdem Sırasına Göre)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            personnelAsync.when(
              data: (personnelList) {
                if (personnelList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Kayıtlı personel bulunamadı. Lütfen önce personel ekleyin.'),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: personnelList.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final p = personnelList[index];
                    final currentSelection =
                        _assignments[p.id] ?? DutyOrLeaveType.gorevli;

                    return ListTile(
                      title: Text(
                        '${p.rutbe} ${p.adSoyad}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Birlik: ${p.birlik}'),
                      trailing: DropdownButton<String>(
                        value: currentSelection,
                        items: const [
                          DropdownMenuItem(
                            value: DutyOrLeaveType.gorevli,
                            child: Text('GÖREVLİ'),
                          ),
                          DropdownMenuItem(
                            value: DutyOrLeaveType.nobetci,
                            child: Text('NÖBETÇİ'),
                          ),
                          DropdownMenuItem(
                            value: DutyOrLeaveType.izinli,
                            child: Text('İZİNLİ'),
                          ),
                          DropdownMenuItem(
                            value: DutyOrLeaveType.istirahatli,
                            child: Text('İSTİRAHATLİ'),
                          ),
                          DropdownMenuItem(
                            value: DutyOrLeaveType.raporlu,
                            child: Text('RAPORLU'),
                          ),
                          DropdownMenuItem(
                            value: DutyOrLeaveType.sevk,
                            child: Text('SEVK'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _assignments[p.id] = val;
                            });
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, st) => Text('Hata: $err'),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('FAALİYET ÇİZELGESİNİ KAYDET'),
                onPressed: _submitActivity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
