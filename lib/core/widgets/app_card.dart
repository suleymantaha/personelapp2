import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';

/// Standartlaştırılmış uygulama kartı bileşeni.
///
/// Kart tıklaması ([onTap]) ile sağ üst köşe veya kenar aksiyonları
/// ([trailingAction]) arasındaki dokunma olaylarını izole eder.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.trailingAction,
    this.margin,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.borderColor,
    this.backgroundColor,
    this.borderRadius,
    this.elevation = 0,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailingAction;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double elevation;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppSpacing.cardRadius);
    final effectiveBorder = borderColor ?? context.cardBorderColor;
    final effectiveBg = backgroundColor ?? context.colorScheme.surface;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.cardGap),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorder),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.35 : 0.05,
                  ),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior,
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: onTap != null || onLongPress != null
                ? InkWell(
                    borderRadius: effectiveRadius,
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: Padding(padding: padding, child: child),
                  )
                : Padding(padding: padding, child: child),
          ),
          if (trailingAction != null)
            Positioned(
              top: 4,
              right: 4,
              child: trailingAction!,
            ),
        ],
      ),
    );
  }
}

/// Standart boş durum görünümü.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    this.description,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.accentSubtleBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: context.accentOrOlive,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Standart hata ve yeniden deneme görünümü.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.title,
    required this.error,
    this.onRetry,
    this.retryText,
    super.key,
  });

  final String title;
  final String error;
  final VoidCallback? onRetry;
  final String? retryText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryText ?? context.l10n.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standart bilgilendirme/uyarı ipucu şeridi.
class AppNoticeBanner extends StatelessWidget {
  const AppNoticeBanner({
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.isWarning = false,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final bool isWarning;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? context.warningColor : context.accentOrOlive;
    final bg = isWarning
        ? context.warningColor.withValues(alpha: 0.12)
        : context.accentSubtleBg;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13.5, height: 1.35),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );
  }
}
