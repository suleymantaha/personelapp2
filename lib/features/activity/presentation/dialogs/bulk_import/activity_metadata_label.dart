import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class ActivityMetadataLabel extends StatelessWidget {
  const ActivityMetadataLabel({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: context.textMuted),
          ),
        ),
      ],
    );
  }
}
