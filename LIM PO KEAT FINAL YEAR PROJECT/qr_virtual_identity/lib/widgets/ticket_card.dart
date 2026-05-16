import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'jelly_card.dart';

class TicketCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onOpenQr;

  const TicketCard({
    super.key,
    required this.event,
    required this.onOpenQr,
  });

  @override
  Widget build(BuildContext context) {
    // Status Logic
    final status = (event.status ?? 'active').toLowerCase();
    final isAttended = status == 'attended';
    final isCancelled = status == 'cancelled';
    final isActive = status == 'active';

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.transparent;
    Color statusBadgeBg = Colors.grey.shade100;
    Color statusBadgeText = Colors.grey.shade600;
    IconData statusIcon = Icons.check_circle_outline;
    String statusLabel = status.toUpperCase();

    if (isActive) {
      // Fresh Mint Gradient
      backgroundColor = const Color(0xFFF0FDF4); // Light green
      borderColor = const Color(0xFFDCFCE7);
      statusBadgeBg = const Color(0xFF16A34A);
      statusBadgeText = Colors.white;
      statusIcon = Icons.check_circle;
    } else if (isAttended) {
      // Cool Blue Gradient
      backgroundColor = const Color(0xFFF0F9FF); // Light blue
      borderColor = const Color(0xFFE0F2FE);
      statusBadgeBg = const Color(0xFF0284C7);
      statusBadgeText = Colors.white;
      statusIcon = Icons.check_circle;
    } else if (isCancelled) {
      backgroundColor = const Color(0xFFFAFAFA); // Gray
      borderColor = const Color(0xFFF5F5F5);
      statusBadgeBg = Colors.grey.shade200;
      statusBadgeText = Colors.grey.shade500;
      statusIcon = Icons.cancel;
    }

    return JellyCard(
      title: '', // Custom content
      backgroundColor: backgroundColor,
      contentColor: Colors.black,
      padding: EdgeInsets.zero,
      content: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: isCancelled
                                ? Colors.grey.shade500
                                : const Color(0xFF1D192B),
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBadgeBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: statusBadgeBg.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon,
                                size: 12, color: statusBadgeText),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusBadgeText,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metadata Grid
                  _buildMetadataRow(
                    Icons.calendar_today_rounded,
                    event.formattedDate,
                    Icons.access_time_rounded,
                    '${event.startTime} - ${event.endTime}',
                  ),
                  const SizedBox(height: 10),
                  _buildLocationRow(Icons.location_on_rounded, event.location),
                  const SizedBox(height: 10),
                  _buildCategoryTag(event.category),
                ],
              ),
            ),

            // Action Footer
            if (isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Material(
                  color: const Color(0xFFC3EED0), // Mint green button
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onOpenQr,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.qr_code_rounded,
                                  size: 20, color: Color(0xFF053916)),
                              const SizedBox(width: 12),
                              const Text(
                                'Tap to sign attendance',
                                style: TextStyle(
                                  color: Color(0xFF053916),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_right_rounded,
                                size: 16, color: Color(0xFF053916)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (isAttended)
              Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: Color(0xFF053916)),
                    SizedBox(width: 8),
                    Text(
                      'CHECK-IN COMPLETED',
                      style: TextStyle(
                        color: Color(0xFF053916),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
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

  Widget _buildMetadataRow(
      IconData icon1, String text1, IconData icon2, String text2) {
    return Row(
      children: [
        Icon(icon1, size: 16, color: const Color(0xFF6750A4)),
        const SizedBox(width: 8),
        Text(
          text1,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF49454F),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('•', style: TextStyle(color: Colors.grey)),
        ),
        Icon(icon2, size: 16, color: const Color(0xFF6750A4)),
        const SizedBox(width: 8),
        Text(
          text2,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF49454F),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6750A4)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF49454F),
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTag(String category) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFD0BCFF),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          category.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6750A4),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
