import 'package:flutter/material.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';

class DashboardActionItem {
  const DashboardActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DashboardActionTone tone;
  final VoidCallback onTap;
}
