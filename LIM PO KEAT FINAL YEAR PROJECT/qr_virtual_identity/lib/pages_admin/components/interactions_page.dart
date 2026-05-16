// lib/pages_admin/components/interactions_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apid/pages_admin/utils/admin_theme.dart';

/// 📜 Interactions History Page
/// Interaction history with type filters
class InteractionsPage extends StatefulWidget {
  const InteractionsPage({super.key});

  @override
  State<InteractionsPage> createState() => _InteractionsPageState();
}

class _InteractionsPageState extends State<InteractionsPage> {
  String _selectedType = 'all';
  final List<String> _types = const [
    'all',
    'purchase',
    'refund',
    'borrow',
    'return',
    'entry',
    'exit',
    'attendance',
    'booking',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(16.0),
          color: AdminTheme.backgroundWhite,
          child: Row(
            children: [
              const Text(
                'Filter by type:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedType,
                onChanged: (value) =>
                    setState(() => _selectedType = value ?? 'all'),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          type == 'all'
                              ? Icons.filter_list
                              : AdminTheme.getInteractionTypeIcon(type),
                          size: 18,
                          color: type == 'all'
                              ? AdminTheme.textSecondary
                              : AdminTheme.getInteractionTypeColor(type),
                        ),
                        const SizedBox(width: 8),
                        Text(type.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Interactions list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedType == 'all'
                ? FirebaseFirestore.instance
                      .collection('interactions')
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                : FirebaseFirestore.instance
                      .collection('interactions')
                      .where('type', isEqualTo: _selectedType)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No interactions found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _InteractionCard(data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InteractionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InteractionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final String type = (data['type'] ?? 'unknown').toString();
    final String userEmail = (data['user_email'] ?? 'Unknown').toString();
    final String scanPointName = (data['scan_point_name'] ?? 'Unknown')
        .toString();
    final dynamic timestamp = data['timestamp'];
    final String status = (data['status'] ?? 'unknown').toString();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Type icon
            CircleAvatar(
              backgroundColor: AdminTheme.getInteractionTypeColor(
                type,
              ).withOpacity(0.15),
              radius: 24,
              child: Icon(
                AdminTheme.getInteractionTypeIcon(type),
                color: AdminTheme.getInteractionTypeColor(type),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scanPointName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  if (data['amount'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'RM ${((data['amount'] ?? 0) as num).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: type == 'refund' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Status + timestamp
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AdminTheme.statusBadge(status, fontSize: 10),
                const SizedBox(height: 6),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
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
