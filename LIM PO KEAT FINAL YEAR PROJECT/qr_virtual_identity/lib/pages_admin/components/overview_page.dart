// lib/pages_admin/components/overview_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apid/pages_admin/utils/admin_theme.dart';

/// 📊 Admin Overview Page
/// Displays statistics cards, charts, and summaries
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Text('📊 System Overview', style: AdminTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Real-time analytics and system statistics',
            style: AdminTheme.bodyMedium.copyWith(
              color: AdminTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // ✨ BONUS: Summary Bar
          const _SummaryBar(),
          const SizedBox(height: 24),

          // ScanPoint Type Distribution
          const Text(
            '🎯 ScanPoint Distribution',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const _ScanPointTypesRow(),
          const SizedBox(height: 32),

          // Recent Interactions
          const Text(
            '🕐 Recent Interactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const _RecentInteractionsWidget(),
        ],
      ),
    );
  }
}

/// ✨ BONUS: Summary Bar Widget
class _SummaryBar extends StatelessWidget {
  const _SummaryBar();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchSummaryData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data ?? {};
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1200
                ? 4
                : constraints.maxWidth > 800
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _SummaryCard(
                  icon: Icons.attach_money,
                  title: 'Total Revenue',
                  value:
                      'RM ${(data['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
                  color: AdminTheme.successColor,
                ),
                _SummaryCard(
                  icon: Icons.people,
                  title: 'Total Users',
                  value: '${data['totalUsers'] ?? 0}',
                  color: AdminTheme.infoColor,
                ),
                _SummaryCard(
                  icon: Icons.receipt_long,
                  title: 'Total Interactions',
                  value: '${data['totalInteractions'] ?? 0}',
                  color: AdminTheme.primaryColor,
                ),
                _SummaryCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Active ScanPoints',
                  value: '${data['activeScanPoints'] ?? 0}',
                  color: AdminTheme.accentColor,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchSummaryData() async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('users').get(),
      db.collection('interactions').get(),
      db.collection('scan_points').where('active', isEqualTo: true).get(),
      db.collection('scan_points').where('type', isEqualTo: 'commerce').get(),
    ]);

    double totalRevenue = 0.0;
    for (final doc in results[3].docs) {
      totalRevenue += ((doc.data()['revenue'] ?? 0.0) as num).toDouble();
    }

    return {
      'totalRevenue': totalRevenue,
      'totalUsers': results[0].docs.length,
      'totalInteractions': results[1].docs.length,
      'activeScanPoints': results[2].docs.length,
    };
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          radius: 24,
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: AdminTheme.bodyMedium.copyWith(
            color: AdminTheme.textSecondary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AdminTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanPointTypesRow extends StatelessWidget {
  const _ScanPointTypesRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('scan_points').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No scan points found')),
            ),
          );
        }

        final typeCounts = <String, int>{
          'commerce': 0,
          'library': 0,
          'access': 0,
          'booking': 0,
        };
        for (final doc in snapshot.data!.docs) {
          final type = (doc.data() as Map<String, dynamic>)['type'] as String?;
          if (type != null && typeCounts.containsKey(type)) {
            typeCounts[type] = typeCounts[type]! + 1;
          }
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              crossAxisCount: constraints.maxWidth > 1000 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _TypeCard(
                  type: 'Commerce',
                  count: typeCounts['commerce']!,
                  icon: Icons.store,
                  color: AdminTheme.commerceColor,
                ),
                _TypeCard(
                  type: 'Library',
                  count: typeCounts['library']!,
                  icon: Icons.local_library,
                  color: AdminTheme.libraryColor,
                ),
                _TypeCard(
                  type: 'Access',
                  count: typeCounts['access']!,
                  icon: Icons.meeting_room,
                  color: AdminTheme.accessColor,
                ),
                _TypeCard(
                  type: 'Booking',
                  count: typeCounts['booking']!,
                  icon: Icons.event_seat,
                  color: AdminTheme.bookingTypeColor,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String type;
  final int count;
  final IconData icon;
  final Color color;

  const _TypeCard({
    required this.type,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type,
              style: AdminTheme.bodySmall.copyWith(
                color: AdminTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent Interactions Widget
class _RecentInteractionsWidget extends StatelessWidget {
  const _RecentInteractionsWidget();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('interactions')
            .orderBy('timestamp', descending: true)
            .limit(15)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No interactions yet')),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final type = data['type'] as String?;
              final userEmail = data['user_email'] ?? 'Unknown';
              final scanPointName = data['scan_point_name'] ?? 'Unknown';
              final status = data['status'] ?? 'unknown';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AdminTheme.getInteractionTypeColor(
                    type,
                  ).withOpacity(0.15),
                  child: Icon(
                    AdminTheme.getInteractionTypeIcon(type),
                    color: AdminTheme.getInteractionTypeColor(type),
                    size: 20,
                  ),
                ),
                title: Text(
                  '$userEmail - ${type?.toUpperCase() ?? 'UNKNOWN'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  scanPointName,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AdminTheme.statusBadge(status, fontSize: 10),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(data['timestamp']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AdminTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = (timestamp as Timestamp).toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }
}
