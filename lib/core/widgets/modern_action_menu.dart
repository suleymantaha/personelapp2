import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class ModernActionOption<T> {
  const ModernActionOption({
    required this.value,
    required this.title,
    required this.icon,
    this.subtitle,
    this.isDestructive = false,
  });

  final T value;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isDestructive;
}

class ModernMenuHeader<T> extends PopupMenuEntry<T> {
  const ModernMenuHeader({
    required this.title,
    required this.icon,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  double get height => subtitle == null ? 56 : 68;

  @override
  bool represents(T? value) => false;

  @override
  State<ModernMenuHeader<T>> createState() => _ModernMenuHeaderState<T>();
}

class _ModernMenuHeaderState<T> extends State<ModernMenuHeader<T>> {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Row(
          children: [
            _ActionIcon(icon: widget.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernPopupMenuItem<T> extends PopupMenuItem<T> {
  ModernPopupMenuItem({required ModernActionOption<T> option, super.key})
    : super(
        value: option.value,
        height: option.subtitle == null ? 56 : 66,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ModernActionTile(option: option),
      );
}

class ModernActionTile<T> extends StatelessWidget {
  const ModernActionTile({required this.option, super.key, this.onTap});

  final ModernActionOption<T> option;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = option.isDestructive
        ? context.rejectedColor
        : context.textPrimary;
    final iconColor = option.isDestructive
        ? context.rejectedColor
        : context.accentOrOlive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              _ActionIcon(
                icon: option.icon,
                color: iconColor,
                destructive: option.isDestructive,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: option.isDestructive
                              ? context.rejectedColor.withValues(alpha: 0.8)
                              : context.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showModernActionSheet<T>(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<ModernActionOption<T>> options,
  String? subtitle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ModernActionSheet<T>(
      title: title,
      subtitle: subtitle,
      icon: icon,
      options: options,
    ),
  );
}

class ModernActionSheet<T> extends StatelessWidget {
  const ModernActionSheet({
    required this.title,
    required this.icon,
    required this.options,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final List<ModernActionOption<T>> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _ActionIcon(icon: icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...options.map(
              (option) => ModernActionTile<T>(
                option: option,
                onTap: () => Navigator.pop(context, option.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, this.color, this.destructive = false});

  final IconData icon;
  final Color? color;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.accentOrOlive;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: destructive
            ? context.rejectedBgColor
            : resolvedColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: resolvedColor, size: 20),
    );
  }
}

ButtonStyle modernPopupStyle(BuildContext context) =>
    IconButton.styleFrom(minimumSize: const Size(44, 44));

ShapeBorder modernPopupShape(BuildContext context) => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
  side: BorderSide(color: context.cardBorderColor),
);

BorderRadius get modernDropdownBorderRadius => BorderRadius.circular(16);

double modernDropdownMenuMaxHeight(BuildContext context) {
  final availableHeight = MediaQuery.sizeOf(context).height * 0.52;
  return availableHeight.clamp(240.0, 420.0);
}

Color modernDropdownColor(BuildContext context) =>
    context.colorScheme.surfaceContainerHigh;
