import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileDesktopPage extends StatelessWidget {
  const ProfileDesktopPage({super.key, required this.merchantData});

  final Map<String, dynamic> merchantData;

  // Accent colors (match Dashboard/Transactions)
  static const Color kPrimary = Color(0xFF6C63FF);
  static const Color kSecondary = Color(0xFFE9E7FD);

  @override
  Widget build(BuildContext context) {
    final merchantId =
        merchantData['scan_point_id'] ?? merchantData['merchant_id'] ?? '';

    // Live scan_point stream so the UI reacts to changes automatically
    final merchantDocStream = FirebaseFirestore.instance
        .collection('scan_points')
        .doc(merchantId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: merchantDocStream,
      builder: (context, snap) {
        final data = snap.data?.data() ?? merchantData;
        final shopName = data['name'] ?? data['shop_name'] ?? 'Merchant';
        final lastActive = data['last_active'] is Timestamp
            ? (data['last_active'] as Timestamp).toDate()
            : null;
        final scanCount = data['scan_count'] ?? 0;
        final interactionCount =
            data['interaction_count'] ?? data['txn_count'] ?? 0;
        final revenue = data['type'] == 'commerce'
            ? (data['revenue'] ?? 0.0).toDouble()
            : 0.0;
        final scanPointType =
            data['type']?.toString() ?? data['merchant_type']?.toString();
        final description = (data['description'] as String?)?.trim();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: kSecondary,
                            child: const Icon(
                              Icons.store_rounded,
                              color: kPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shopName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _chip('ID: $merchantId'),
                                  const SizedBox(width: 8),
                                  if (scanPointType != null &&
                                      scanPointType.isNotEmpty)
                                    _chip(scanPointType.toUpperCase()),
                                  const SizedBox(width: 8),
                                  _verifiedChip(),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Stats
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _infoTile(
                            'Total Scans',
                            '$scanCount',
                            Icons.qr_code_scanner_rounded,
                            Colors.orange,
                          ),
                          _infoTile(
                            'Total Interactions',
                            '$interactionCount',
                            Icons.receipt_long_rounded,
                            kPrimary,
                          ),
                          if (data['type'] == 'commerce')
                            _infoTile(
                              'Total Revenue',
                              'RM ${revenue.toStringAsFixed(2)}',
                              Icons.payments_rounded,
                              Colors.green,
                            ),
                          _infoTile(
                            'Last Active',
                            lastActive != null
                                ? _formatDateTime(lastActive)
                                : 'N/A',
                            Icons.access_time_rounded,
                            Colors.blueGrey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 1) Merchant Description
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    (description == null || description.isEmpty)
                        ? 'No description available for this merchant.'
                        : description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2) Recent Activity Logs
              _recentActivityCard(merchantId: merchantId),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Helpers ----
  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _verifiedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Colors.green, size: 14),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivityCard({required String merchantId}) {
    // Prefer server-side filtering when available; since our logs currently
    // store merchantId inside the detail string, we fetch recent logs and
    // filter client-side to entries mentioning this merchant.
    final logsStream = FirebaseFirestore.instance
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded, color: kPrimary),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: logsStream,
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Text('No recent activities available.');
                }

                final filtered = snap.data!.docs
                    .where(
                      (d) =>
                          (d['detail']?.toString() ?? '').contains(merchantId),
                    )
                    .take(5)
                    .toList();

                if (filtered.isEmpty) {
                  return const Text('No recent activities available.');
                }

                return Column(
                  children: [
                    for (final doc in filtered)
                      _activityRow(
                        action: doc['action']?.toString() ?? 'Activity',
                        detail: doc['detail']?.toString() ?? '',
                        timestamp: doc['timestamp'],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityRow({
    required String action,
    required String detail,
    required Object? timestamp,
  }) {
    DateTime? dt;
    if (timestamp is Timestamp) dt = timestamp.toDate();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, height: 1.3),
                children: [
                  TextSpan(
                    text: dt != null ? '${_formatDateTime(dt)} – ' : '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextSpan(
                    text: '$action: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
