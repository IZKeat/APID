import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:apid/theme/app_theme.dart';

class DemoModePanel extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final ScrollController scrollController;
  final VoidCallback onClearLogs;

  const DemoModePanel({
    super.key,
    required this.logs,
    required this.scrollController,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      color: AppTheme.backgroundDark, // Use AppTheme dark background
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSurfaceDark,
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: AppTheme.successColor),
                const SizedBox(width: 12),
                Text(
                  'Live Debug Console',
                  style: AppTheme.heading3Dark.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  onPressed: onClearLogs,
                  tooltip: 'Clear Logs',
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'Waiting for scans...',
                      style: AppTheme.bodyMediumDark.copyWith(
                        color: Colors.white.withOpacity(0.3),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogEntry(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final bool isError = log['result'] == 'error';
    final bool isSuccess = log['result'] == 'success';
    final Color statusColor = isError
        ? AppTheme.errorColor
        : isSuccess
            ? AppTheme.successColor
            : AppTheme.infoColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Line: Timestamp | Mode | Result
          Row(
            children: [
              Text(
                _formatTime(log['timestamp']),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (log['mode'] ?? 'UNKNOWN').toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (log['latencyMs'] != null)
                Text(
                  '${log['latencyMs']}ms',
                  style: const TextStyle(
                    color: AppTheme.warningColor,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            log['message'] ?? '',
            style: AppTheme.bodyMediumDark,
          ),

          // QR Payload (Masked)
          if (log['rawQr'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Payload: ${log['rawQr']}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],

          // Backend Response (Expandable)
          if (log['backendResponse'] != null) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text(
                      'Backend Response',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                      ),
                    ),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    dense: true,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          const JsonEncoder.withIndent('  ').convert(log['backendResponse']),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '--:--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
