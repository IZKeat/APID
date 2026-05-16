import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/user_notification_service.dart';
import '../widgets/jelly_card.dart';

class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({super.key});

  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['All', 'Access', 'Library', 'Event', 'Commerce'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D192B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Inbox',
          style: TextStyle(
            color: Color(0xFF1D192B),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search notifications...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6750A4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),

          // 🏷️ Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFE8DEF8),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF1D192B) : const Color(0xFF49454F),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : Colors.grey.shade200,
                      ),
                    ),
                    showCheckmark: false,
                  ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                );
              }).toList(),
            ),
          ),

          // 📜 Notification List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: UserNotificationService.getInboxStream(
                filterTypes: _selectedCategory == 'All' 
                    ? null 
                    : UserNotificationService.getCategoryTypes(_selectedCategory),
                limit: 50, // Increase limit for better search results
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // 🔍 Client-side Filtering
                final docs = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final title = _getTitle(data['type']).toLowerCase();
                  final subtitle = (data['scan_point_name'] ?? '').toString().toLowerCase();
                  final description = (data['description'] ?? '').toString().toLowerCase();
                  
                  return title.contains(_searchQuery) || 
                         subtitle.contains(_searchQuery) || 
                         description.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return _buildEmptyState(message: 'No matching results found');
                }

                final groupedDocs = _groupDocsByDate(docs);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedDocs.length,
                  itemBuilder: (context, index) {
                    final group = groupedDocs[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Text(
                            group.dateLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ).animate().fadeIn(delay: (index * 50).ms),

                        // List Items
                        ...group.items.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildNotificationItem(context, data);
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String message = 'No Notifications'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFE8DEF8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined, size: 48, color: Color(0xFF6750A4)),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D192B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF49454F),
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'unknown';
    final title = _getTitle(type);
    final subtitle = data['scan_point_name'] ?? 'Unknown Location';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeStr = DateFormat('h:mm a').format(timestamp);
    final amount = data['amount'];

    IconData icon;
    Color color;
    Color iconColor;

    switch (type) {
      case 'payment':
      case 'purchase':
        icon = Icons.shopping_bag_outlined;
        color = const Color(0xFFFFD8E4); // Pink
        iconColor = const Color(0xFF31111D);
        break;
      case 'access_granted':
        icon = Icons.door_front_door_outlined;
        color = const Color(0xFFDCFCE7); // Green
        iconColor = const Color(0xFF14532D);
        break;
      case 'access_denied':
        icon = Icons.no_meeting_room_outlined;
        color = const Color(0xFFFFDAD6); // Red
        iconColor = const Color(0xFF410002);
        break;
      case 'book_borrowed':
      case 'book_returned':
        icon = Icons.menu_book_outlined;
        color = const Color(0xFFD1E4FF); // Blue
        iconColor = const Color(0xFF0C4A6E);
        break;
      case 'event_checkin':
      case 'event_joined':
        icon = Icons.event_available_outlined;
        color = const Color(0xFFEADDFF); // Purple
        iconColor = const Color(0xFF21005D);
        break;
      default:
        icon = Icons.notifications_outlined;
        color = const Color(0xFFF2F0F4);
        iconColor = const Color(0xFF1D192B);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: JellyCard(
        backgroundColor: Colors.white,
        contentColor: const Color(0xFF1D192B),
        onTap: () => _showReceiptDialog(context, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (amount != null)
                    Text(
                      '- RM $amount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.red, // Expense
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideX(begin: 0.2, end: 0, curve: Curves.easeOutBack, duration: 400.ms);
  }

  String _getTitle(String type) {
    switch (type) {
      case 'payment': 
      case 'purchase':
        return 'Payment';
      case 'access_granted': return 'Access Granted';
      case 'access_denied': return 'Access Denied';
      case 'book_borrowed': return 'Book Borrowed';
      case 'book_returned': return 'Book Returned';
      case 'event_checkin': return 'Event Check-in';
      case 'event_joined': return 'Event Joined';
      default: return 'Notification';
    }
  }

  List<_DateGroup> _groupDocsByDate(List<QueryDocumentSnapshot> docs) {
    final groups = <String, List<QueryDocumentSnapshot>>{};
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final dateKey = _getDateKey(timestamp);
      
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(doc);
    }

    return groups.entries.map((e) => _DateGroup(e.key, e.value)).toList();
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'TODAY';
    if (checkDate == yesterday) return 'YESTERDAY';
    return DateFormat('MMM d, yyyy').format(date).toUpperCase();
  }

  void _showReceiptDialog(BuildContext context, Map<String, dynamic> data) {
    // Reusing the receipt dialog logic, simplified for this view
    final amount = data['amount'];
    final merchant = data['scan_point_name'] ?? 'Merchant';
    final items = data['items'] as List<dynamic>? ?? [];
    final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => Center(
        child: JellyCard(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF6750A4), size: 48),
                const SizedBox(height: 16),
                Text(
                  amount != null ? 'RM $amount' : 'Details',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(merchant, style: const TextStyle(color: Colors.grey)),
                const Divider(height: 32),
                if (items.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        children: items.map((item) {
                          final i = item as Map<String, dynamic>;
                          final price = (i['price'] as num?) ?? 0;
                          final quantity = (i['quantity'] as num?) ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${quantity}x ${i['name'] ?? 'Item'}'),
                                Text('RM ${(price * quantity).toStringAsFixed(2)}'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(DateFormat('MMM d, yyyy h:mm a').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6750A4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateGroup {
  final String dateLabel;
  final List<QueryDocumentSnapshot> items;

  _DateGroup(this.dateLabel, this.items);
}
