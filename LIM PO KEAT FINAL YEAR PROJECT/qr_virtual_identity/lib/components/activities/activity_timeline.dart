import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ActivityTimeline extends StatefulWidget {
  final String selectedFilter;
  final DateTimeRange? dateRange;

  const ActivityTimeline({
    super.key,
    required this.selectedFilter,
    this.dateRange,
  });

  @override
  State<ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends State<ActivityTimeline>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to view activity records'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getActivitiesStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Loading failed: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Empty state handled by parent
        }

        final activities = _filterActivities(snapshot.data!.docs);

        if (activities.isEmpty) {
          return _buildNoDataState();
        }

        return _buildTimelineList(activities);
      },
    );
  }

  Stream<QuerySnapshot> _getActivitiesStream(String userId) {
    Query query = FirebaseFirestore.instance
        .collection('interactions')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'success')
        .orderBy('timestamp', descending: true);

    // Apply date range filter if provided
    if (widget.dateRange != null) {
      query = query
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(widget.dateRange!.start),
          )
          .where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(widget.dateRange!.end),
          );
    }

    return query.limit(50).snapshots();
  }

  List<QueryDocumentSnapshot> _filterActivities(
    List<QueryDocumentSnapshot> activities,
  ) {
    if (widget.selectedFilter == 'all') {
      return activities;
    }

    return activities.where((activity) {
      final data = activity.data() as Map<String, dynamic>;
      final type = data['type'] as String?;

      // Get scan point type for filtering
      switch (widget.selectedFilter) {
        case 'library':
          return type == 'borrow' || type == 'return';
        case 'commerce':
          return type == 'purchase' || type == 'refund';
        case 'access':
          return type == 'entry' || type == 'exit' || type == 'attendance';
        case 'booking':
          return type == 'booking';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildTimelineList(List<QueryDocumentSnapshot> activities) {
    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return SizedBox(
          height: 300, // Fixed height to prevent overflow
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index].data() as Map<String, dynamic>;
              final timestamp = activity['timestamp'] as Timestamp?;

              return AnimatedBuilder(
                animation: _listAnimationController,
                builder: (context, child) {
                  final delay = index * 0.1;
                  final animation = Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _listAnimationController,
                      curve: Interval(
                        delay.clamp(0.0, 1.0),
                        (delay + 0.3).clamp(0.0, 1.0),
                        curve: Curves.easeOutBack,
                      ),
                    ),
                  );

                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - animation.value)),
                    child: Opacity(
                      opacity: animation.value,
                      child: _buildActivityCard(activity, timestamp, index),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(
    Map<String, dynamic> activity,
    Timestamp? timestamp,
    int index,
  ) {
    final type = activity['type'] as String? ?? 'unknown';
    final scanPointName = activity['scan_point_name'] as String? ?? 'Unknown Location';
    final amount = activity['amount'] as num?;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showActivityDetails(activity);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getActivityColor(type),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getActivityColor(type).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getActivityIcon(type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (index < 49) // Don't show line for last item
                  Container(
                    width: 2,
                    height: 30,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Activity content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getActivityTitle(type, activity),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            _formatTime(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            scanPointName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Amount (for commerce activities)
                    if (amount != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: type == 'refund'
                              ? Colors.red[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${type == 'refund' ? '-' : ''}RM ${amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: type == 'refund'
                                ? Colors.red[700]
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ],

                    // Additional details based on type
                    if (_getAdditionalInfo(activity).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _getAdditionalInfo(activity),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No matching activity records',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try changing filter criteria',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'borrow':
      case 'return':
        return const Color(0xFF1565C0); // Stronger blue
      case 'purchase':
      case 'refund':
        return const Color(0xFF2E7D32); // Stronger green
      case 'entry':
      case 'exit':
      case 'attendance':
        return const Color(0xFFE65100); // Stronger orange
      case 'booking':
        return const Color(0xFF7B1FA2); // Stronger purple
      default:
        return const Color(0xFF424242); // Stronger grey
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'borrow':
        return Icons.book;
      case 'return':
        return Icons.book_online;
      case 'purchase':
        return Icons.shopping_cart;
      case 'refund':
        return Icons.receipt_long;
      case 'entry':
        return Icons.login;
      case 'exit':
        return Icons.logout;
      case 'attendance':
        return Icons.how_to_reg;
      case 'booking':
        return Icons.event_note;
      default:
        return Icons.history;
    }
  }

  String _getActivityTitle(String type, Map<String, dynamic> activity) {
    final remarks = activity['remarks'] as String? ?? '';

    switch (type) {
      case 'borrow':
        return remarks.isNotEmpty ? remarks : 'Borrow Book';
      case 'return':
        return remarks.isNotEmpty ? remarks : 'Return Book';
      case 'purchase':
        return remarks.isNotEmpty ? remarks : 'Purchase Item';
      case 'refund':
        return remarks.isNotEmpty ? remarks : 'Request Refund';
      case 'entry':
        return 'Campus Entry';
      case 'exit':
        return 'Campus Exit';
      case 'attendance':
        return remarks.isNotEmpty ? remarks : 'Attendance Record';
      case 'booking':
        return remarks.isNotEmpty ? remarks : 'Service Booking';
      default:
        return remarks.isNotEmpty ? remarks : 'Unknown Activity';
    }
  }

  String _getAdditionalInfo(Map<String, dynamic> activity) {
    final type = activity['type'] as String?;

    switch (type) {
      case 'borrow':
      case 'return':
        final bookTitle = activity['book_title'] as String?;
        final bookId = activity['book_id'] as String?;
        if (bookTitle != null) return bookTitle;
        if (bookId != null) return 'Book ID: $bookId';
        break;
      case 'purchase':
      case 'refund':
        final paymentMethod = activity['payment_method'] as String?;
        final receiptId = activity['receipt_id'] as String?;
        if (paymentMethod != null) return 'Payment: $paymentMethod';
        if (receiptId != null) return 'Receipt: $receiptId';
        break;
      case 'attendance':
        final className = activity['class_name'] as String?;
        if (className != null) return className;
        break;
      case 'booking':
        final resourceName = activity['resource_name'] as String?;
        if (resourceName != null) return resourceName;
        break;
    }
    return '';
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Activity Details',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Activity details
            ..._buildDetailRows(activity),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A), // Stronger purple
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailRows(Map<String, dynamic> activity) {
    final List<Widget> rows = [];

    activity.forEach((key, value) {
      if (value != null && _shouldShowField(key)) {
        rows.add(
          _buildDetailRow(_getFieldLabel(key), _formatFieldValue(key, value)),
        );
      }
    });

    return rows;
  }

  bool _shouldShowField(String key) {
    return ![
      'user_id',
      'interaction_id',
      'created_at',
      'user_email',
    ].contains(key);
  }

  String _getFieldLabel(String key) {
    switch (key) {
      case 'type':
        return 'Activity Type';
      case 'status':
        return 'Status';
      case 'remarks':
        return 'Remarks';
      case 'scan_point_name':
        return 'Location';
      case 'amount':
        return 'Amount';
      case 'payment_method':
        return 'Payment Method';
      case 'book_title':
        return 'Book Title';
      case 'book_id':
        return 'Book ID';
      case 'timestamp':
        return 'Time';
      default:
        return key;
    }
  }

  String _formatFieldValue(String key, dynamic value) {
    switch (key) {
      case 'amount':
        return 'RM ${(value as num).toStringAsFixed(2)}';
      case 'timestamp':
        if (value is Timestamp) {
          return DateFormat('yyyy-MM-dd HH:mm:ss').format(value.toDate());
        }
        return value.toString();
      default:
        return value.toString();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
