// lib/pages_user/widgets/adaptive_card.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 🎴 Adaptive Card Widget
/// Reusable rounded card component for metrics, actions, and data display
class AdaptiveCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  const AdaptiveCard({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.color,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppTheme.primaryColor;

    return Card(
      elevation: AppTheme.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: EdgeInsets.all(
            compact ? AppTheme.spacingMD : AppTheme.spacingLG,
          ),
          child: _buildContent(cardColor),
        ),
      ),
    );
  }

  Widget _buildContent(Color cardColor) {
    if (compact) {
      // Compact layout for metric cards
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: cardColor, size: 32),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            value ?? '',
            style: AppTheme.heading2.copyWith(color: cardColor),
          ),
        ],
      );
    }

    // Standard layout
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(icon, color: cardColor, size: 28),
          ),
          const SizedBox(width: AppTheme.spacingMD),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTheme.heading3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  subtitle!,
                  style: AppTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (value != null) ...[
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  value!,
                  style: AppTheme.heading2.copyWith(color: cardColor),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// 🎯 Metric Card - Compact variant for dashboard metrics
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? color;

  const MetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveCard(
      icon: icon,
      title: title,
      value: value,
      color: color ?? AppTheme.primaryColor,
      compact: true,
    );
  }
}
