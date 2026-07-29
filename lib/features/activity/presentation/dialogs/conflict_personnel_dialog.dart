import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class ConflictPersonnelDialog extends StatelessWidget {
  const ConflictPersonnelDialog({
    required this.descriptions,
    super.key,
  });

  final List<String> descriptions;

  @override
  Widget build(BuildContext context) {
    final conflicts = descriptions.map(_ConflictInfo.parse).toList();
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Bazı personeller eklenmedi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kayıt tamamlandı. Aynı gün için başka kaydı bulunan '
                    '${conflicts.length} personel atlandı.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.cardBorderColor),
            Flexible(
              child: ListView.separated(
                key: const Key('conflict-personnel-list'),
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: conflicts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _ConflictCard(
                  conflict: conflicts[index],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: context.cardBorderColor),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ANLADIM'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.conflict});

  final _ConflictInfo conflict;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: colors.errorContainer,
              foregroundColor: colors.onErrorContainer,
              child: const Icon(Icons.person_off_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conflict.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (conflict.date != null)
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: conflict.date!,
                        ),
                      if (conflict.activity != null)
                        _InfoChip(
                          icon: Icons.assignment_outlined,
                          label: conflict.activity!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    conflict.detail,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.3,
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
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.accentOrOlive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.accentOrOlive),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.accentOrOlive,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictInfo {
  const _ConflictInfo({
    required this.name,
    required this.detail,
    this.date,
    this.activity,
  });

  final String name;
  final String detail;
  final String? date;
  final String? activity;

  static final _descriptionPattern = RegExp(
    r'^(.+?): (\d{4})-(\d{2})-(\d{2}) tarihinde mevcut kaydı nedeniyle '
    r'(.+) faaliyetine eklenmedi\.$',
  );

  factory _ConflictInfo.parse(String description) {
    final match = _descriptionPattern.firstMatch(description);
    if (match == null) {
      final separator = description.indexOf(':');
      return _ConflictInfo(
        name: separator > 0
            ? description.substring(0, separator).trim()
            : 'Çakışan kayıt',
        detail: separator > 0
            ? description.substring(separator + 1).trim()
            : description,
      );
    }

    return _ConflictInfo(
      name: match.group(1)!,
      date: '${match.group(4)}.${match.group(3)}.${match.group(2)}',
      activity: match.group(5)!,
      detail: 'Bu tarihte başka bir faaliyet kaydı bulunuyor.',
    );
  }
}
