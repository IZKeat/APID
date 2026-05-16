import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyStatsCard extends StatefulWidget {
  final String selectedFilter;

  const DailyStatsCard({super.key, required this.selectedFilter});

  @override
  State<DailyStatsCard> createState() => _DailyStatsCardState();
}

class _DailyStatsCardState extends State<DailyStatsCard>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _counterAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _counterAnimation;

  Map<String, dynamic> _todayStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchTodayStats();
  }

  void _initAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _counterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    );
    _counterAnimation = CurvedAnimation(
      parent: _counterAnimationController,
      curve: Curves.elasticOut,
    );

    _cardAnimationController.forward();
  }

  Future<void> _fetchTodayStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Query interactions for today
      final query = FirebaseFirestore.instance
          .collection('interactions')
          .where('user_id', isEqualTo: user.uid)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd))
          .where('status', isEqualTo: 'success');

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _todayStats = _calculateStats(snapshot.docs);
          _isLoading = false;
        });
        _counterAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs) {
    int totalActivities = docs.length;
    double totalAmount = 0.0;
    Map<String, int> scanPointCounts = {};
    Map<String, int> typeCounts = {};
    String mostFrequentScanPoint = '';
    int maxCount = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Calculate total amount for commerce interactions
      if (data['amount'] != null) {
        totalAmount += (data['amount'] as num).toDouble();
      }

      // Count scan points
      final scanPointName = data['scan_point_name'] as String? ?? 'Unknown';
      scanPointCounts[scanPointName] =
          (scanPointCounts[scanPointName] ?? 0) + 1;

      // Count interaction types
      final type = data['type'] as String? ?? 'unknown';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;

      // Find most frequent scan point
      if (scanPointCounts[scanPointName]! > maxCount) {
        maxCount = scanPointCounts[scanPointName]!;
        mostFrequentScanPoint = scanPointName;
      }
    }

    return {
      'totalActivities': totalActivities,
      'totalAmount': totalAmount,
      'mostFrequentScanPoint': mostFrequentScanPoint,
      'typeCounts': typeCounts,
      'purchaseCount': typeCounts['purchase'] ?? 0,
      'borrowCount': typeCounts['borrow'] ?? 0,
      'accessCount': (typeCounts['entry'] ?? 0) + (typeCounts['exit'] ?? 0),
      'bookingCount': typeCounts['booking'] ?? 0,
    };
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _counterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 8,
              shadowColor: const Color(0xFF512DA8).withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      const Color(0xFF512DA8).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _isLoading ? _buildLoadingState() : _buildStatsContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF6A1B9A),
              ), // Stronger purple
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsContent() {
    final totalActivities = _todayStats['totalActivities'] ?? 0;
    final totalAmount = _todayStats['totalAmount'] ?? 0.0;
    final mostFrequent = _todayStats['mostFrequentScanPoint'] ?? 'No Data';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF6A1B9A,
                ).withOpacity(0.15), // Stronger purple with better contrast
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.insights,
                color: Color(0xFF6A1B9A), // Stronger purple
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A), // Stronger purple
                  ),
                ),
                Text(
                  DateTime.now().toString().substring(0, 10),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Activities',
                totalActivities,
                Icons.trending_up,
                const Color(0xFF2E7D32), // Stronger green
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Amount Spent',
                totalAmount,
                Icons.account_balance_wallet,
                const Color(0xFFE65100), // Stronger orange
                isAmount: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Most frequent location
        if (mostFrequent != 'No Data')
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(
                0xFF6A1B9A,
              ).withOpacity(0.08), // Better contrast
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF6A1B9A), // Stronger purple
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Most Frequent Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        mostFrequent,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A1B9A), // Stronger purple
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    dynamic value,
    IconData icon,
    Color color, {
    bool isAmount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              AnimatedBuilder(
                animation: _counterAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _counterAnimation.value,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: value.toDouble()),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, animValue, child) {
                        return Text(
                          isAmount
                              ? 'RM ${animValue.toStringAsFixed(2)}'
                              : animValue.toInt().toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
