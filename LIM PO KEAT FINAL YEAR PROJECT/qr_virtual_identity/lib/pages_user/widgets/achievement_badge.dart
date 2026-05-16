// lib/pages_user/widgets/achievement_badge.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 🏆 Achievement Badge Widget
/// Displays unlocked achievements with tier-based styling
class AchievementBadge extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String tier;
  final bool unlocked;
  final DateTime? unlockedAt;
  final IconData? icon;

  const AchievementBadge({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.unlocked,
    this.unlockedAt,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = AppTheme.getAchievementColor(tier);
    final opacity = unlocked ? 1.0 : 0.3;

    return Card(
      elevation: unlocked ? AppTheme.elevationMedium : AppTheme.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: unlocked
            ? BorderSide(color: tierColor.withOpacity(0.3), width: 2)
            : BorderSide.none,
      ),
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Row(
            children: [
              // Badge icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: unlocked
                      ? LinearGradient(
                          colors: [tierColor.withOpacity(0.8), tierColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: unlocked ? null : AppTheme.textHint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? _getDefaultIcon(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              // Badge details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTheme.heading3.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildTierChip(tier, tierColor),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      description,
                      style: AppTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (unlocked && unlockedAt != null) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'Unlocked: ${_formatDate(unlockedAt!)}',
                        style: AppTheme.caption.copyWith(
                          color: tierColor,
                          fontWeight: FontWeight.w500,
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

  Widget _buildTierChip(String tier, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSM,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        tier.toUpperCase(),
        style: AppTheme.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getDefaultIcon() {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return Icons.emoji_events_outlined;
      case 'silver':
        return Icons.emoji_events;
      case 'gold':
        return Icons.stars;
      case 'platinum':
      case 'purple':
        return Icons.workspace_premium;
      default:
        return Icons.badge_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
