// lib/pages_user/widgets/timeline_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

/// ⏱️ Timeline Item Widget
/// Displays activity events in a vertical timeline format
class TimelineItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DateTime timestamp;
  final Color color;
  final IconData icon;
  final bool isFirst;
  final bool isLast;
  final String? amount;

  const TimelineItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.timestamp,
    required this.color,
    required this.icon,
    this.isFirst = false,
    this.isLast = false,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(width: 2, height: 12, color: AppTheme.textHint),
                // Circle with icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppTheme.textHint),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTheme.heading3.copyWith(fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (amount != null)
                        Text(
                          amount!,
                          style: AppTheme.heading3.copyWith(
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                    ],
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
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(_formatTimestamp(timestamp), style: AppTheme.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday, ${DateFormat('HH:mm').format(dt)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    }
  }
}
