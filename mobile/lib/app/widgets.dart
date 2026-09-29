import 'package:flutter/material.dart';

class AppPanel extends StatelessWidget {
  const AppPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class AppIconBox extends StatelessWidget {
  const AppIconBox({
    required this.icon,
    super.key,
    this.size = 42,
    this.iconSize = 21,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: foregroundColor ?? scheme.onPrimaryContainer,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Widget subtitleWidget;

    if (subtitle == null) {
      subtitleWidget = const SizedBox.shrink();
    } else {
      subtitleWidget = Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      );
    }

    final Widget trailingWidget = trailing ?? const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              subtitleWidget,
            ],
          ),
        ),
        trailingWidget,
      ],
    );
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro({required this.title, super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final Widget subtitleWidget;

    if (subtitle == null) {
      subtitleWidget = const SizedBox.shrink();
    } else {
      subtitleWidget = Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        subtitleWidget,
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconBox(
              icon: icon,
              size: 56,
              iconSize: 26,
              backgroundColor: scheme.surfaceContainer,
              foregroundColor: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    super.key,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    required this.label,
    required this.value,
    super.key,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shownValue = value.trim().isEmpty ? '-' : value;

    final Widget iconWidget;

    if (icon == null) {
      iconWidget = const SizedBox.shrink();
    } else {
      iconWidget = Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(icon, size: 19, color: scheme.onSurfaceVariant),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              shownValue,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class AppActionTile extends StatelessWidget {
  const AppActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppPanel(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        minTileHeight: 74,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: AppIconBox(
          icon: icon,
          backgroundColor: scheme.surfaceContainer,
          foregroundColor: scheme.onSurfaceVariant,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing:
            trailing ??
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
