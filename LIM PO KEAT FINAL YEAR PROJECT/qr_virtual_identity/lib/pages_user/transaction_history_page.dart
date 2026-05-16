// lib/pages_user/transaction_history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_card.dart';

/// Full Transaction History Page
/// Complete transaction list with filtering and pie chart analytics
class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Animation controllers
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  // Data
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  Map<String, double> _categoryData = {};

  // Filter state
  DateTimeRange? _dateRange;
  String? _selectedCategory;
  String _statusFilter = 'All';
  bool _isAnalyticsExpanded = true; // Default expanded
  bool _isFiltersExpanded = false; // Filters start collapsed

  // Statistics
  double _totalSpending = 0.0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    // Start expanded
    _expandController.value = 1.0;

    // Set default date range to current month
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );

    _loadTransactions();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Fixed Header
            SliverToBoxAdapter(child: _buildHeader()),
            // Fixed Filters
            SliverToBoxAdapter(child: _buildFilters()),
            // Fixed Statistics (with proper spacing)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildStatistics(),
                  const SizedBox(height: 8), // Add spacing before list
                ],
              ),
            ),
            // Scrollable Transactions List
            _buildScrollableTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.backgroundLight,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                color: AppTheme.textPrimary,
              ),
              const Expanded(
                child: Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Complete transaction records with analytics',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current filter display (when collapsed)
          if (!_isFiltersExpanded)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isFiltersExpanded = !_isFiltersExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getFilterSummaryText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      _isFiltersExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

          // Date range and status filter (when expanded)
          if (_isFiltersExpanded) ...[
            // Filter header with collapse button
            Row(
              children: [
                Text(
                  'Filter Options',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isFiltersExpanded = false;
                    });
                  },
                  icon: Icon(Icons.expand_less, color: AppTheme.primaryColor),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _showDateRangePicker,
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(
                      _getDateRangeText(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    items: ['All', 'Success', 'Pending', 'Failed']
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _statusFilter = value;
                        });
                        _filterTransactions();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],

          // Clear all filters button
          if (_hasActiveFilters())
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getActiveFiltersCount(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Collapsible header
          InkWell(
            onTap: _toggleAnalyticsExpansion,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spending Analytics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (!_isAnalyticsExpanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            'RM ${_totalSpending.toStringAsFixed(2)} • $_transactionCount transactions',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isAnalyticsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: _isAnalyticsExpanded ? _buildAnalyticsContent() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Divider
          Container(
            height: 1,
            color: AppTheme.backgroundLight,
            margin: const EdgeInsets.only(bottom: 16),
          ),

          // Statistics summary cards with more space
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Spending',
                  'RM ${_totalSpending.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Transactions',
                  _transactionCount.toString(),
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Categories',
                  _categoryData.length.toString(),
                  Icons.category,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Centered Pie Chart
          if (_categoryData.isNotEmpty) _buildCenteredPieChart(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCenteredPieChart() {
    final pieColors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.errorColor,
      AppTheme.infoColor,
      AppTheme.warningColor,
    ];

    return Container(
      padding: const EdgeInsets.all(16), // Add padding around the whole chart
      child: Column(
        children: [
          // Pie Chart - Centered with fixed container
          Container(
            height: 220, // Slightly increased height
            margin: const EdgeInsets.symmetric(
              vertical: 16,
            ), // Add vertical margin
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 55,
                        sections: _categoryData.entries.map((entry) {
                          final index = _categoryData.keys.toList().indexOf(
                            entry.key,
                          );
                          final percentage =
                              (_categoryData[entry.key]! / _totalSpending) *
                              100;
                          final color = pieColors[index % pieColors.length];
                          final isSelected = _selectedCategory == entry.key;

                          return PieChartSectionData(
                            color: isSelected ? color : color.withOpacity(0.8),
                            value: entry.value,
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: isSelected ? 90 : 85,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                if (event is FlTapUpEvent &&
                                    pieTouchResponse?.touchedSection != null) {
                                  final touchedIndex = pieTouchResponse!
                                      .touchedSection!
                                      .touchedSectionIndex;
                                  final category = _categoryData.keys
                                      .toList()[touchedIndex];
                                  _onCategoryTap(category);
                                }
                              },
                        ),
                      ),
                    ),

                    // Center text
                    Positioned.fill(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getShortDateRange(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_categoryData.length} categories',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Double the spacing between pie chart and legend
          const SizedBox(height: 40), // Doubled from 20px to 40px
          // Legend below pie chart with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildPieChartLegend(pieColors),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartLegend(List<Color> pieColors) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: _categoryData.entries.map((entry) {
        final index = _categoryData.keys.toList().indexOf(entry.key);
        final color = pieColors[index % pieColors.length];
        final isSelected = _selectedCategory == entry.key;
        final percentage = (_categoryData[entry.key]! / _totalSpending) * 100;

        return GestureDetector(
          onTap: () => _onCategoryTap(entry.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: color, width: 1.5) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getShortCategoryName(entry.key),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? color : AppTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    Text(
                      'RM${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? color : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableTransactionsList() {
    if (_filteredTransactions.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textHint),
              const SizedBox(height: 16),
              Text(
                _selectedCategory != null
                    ? 'No transactions for $_selectedCategory'
                    : 'No transactions found',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              if (_selectedCategory != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _clearCategoryFilter,
                  child: const Text('Clear Filter'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final transaction = _filteredTransactions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TransactionCard(
              transaction: transaction,
              onTap: () => _showTransactionDetails(transaction),
            ),
          );
        }, childCount: _filteredTransactions.length),
      ),
    );
  }

  // ========== Data Loading and Management ==========
  Future<void> _loadTransactions() async {
    final user = _auth.currentUser;
    if (user?.email == null) return;

    try {
      final query = _db
          .collection('interactions')
          .where('user_email', isEqualTo: user!.email)
          .orderBy('timestamp', descending: true);

      final snapshot = await query.get();

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _allTransactions = transactions;
      });

      _filterTransactions();
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  void _filterTransactions() {
    List<Map<String, dynamic>> filtered = _allTransactions;

    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((transaction) {
        final timestamp = transaction['timestamp'];
        if (timestamp == null) return false;

        DateTime dateTime;
        if (timestamp is Timestamp) {
          dateTime = timestamp.toDate();
        } else if (timestamp is DateTime) {
          dateTime = timestamp;
        } else {
          return false;
        }

        return dateTime.isAfter(_dateRange!.start) &&
            dateTime.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by status
    if (_statusFilter != 'All') {
      filtered = filtered
          .where(
            (t) =>
                (t['status'] as String?)?.toLowerCase() ==
                _statusFilter.toLowerCase(),
          )
          .toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered
          .where((t) => t['scan_point_name'] == _selectedCategory)
          .toList();
    }

    setState(() {
      _filteredTransactions = filtered;
    });

    _calculateStatistics(filtered);
  }

  void _calculateStatistics(List<Map<String, dynamic>> transactions) {
    final purchaseTransactions = transactions
        .where(
          (t) =>
              ['purchase', 'refund'].contains(t['type']) &&
              t['status'] == 'success',
        )
        .toList();

    _totalSpending = purchaseTransactions.fold<double>(0.0, (sum, transaction) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final type = transaction['type'] as String? ?? '';
      return sum + (type == 'purchase' ? amount : -amount);
    });

    _transactionCount = purchaseTransactions.length;

    // Calculate category data
    final categoryTotals = <String, double>{};
    for (final transaction in purchaseTransactions) {
      final scanPointName =
          transaction['scan_point_name'] as String? ?? 'Other';
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final type = transaction['type'] as String? ?? '';

      final adjustedAmount = type == 'purchase' ? amount : -amount;
      if (adjustedAmount > 0) {
        // Only positive spending
        categoryTotals[scanPointName] =
            (categoryTotals[scanPointName] ?? 0.0) + adjustedAmount;
      }
    }

    setState(() {
      _categoryData = categoryTotals;
    });
  }

  // ========== Event Handlers ==========
  void _toggleAnalyticsExpansion() {
    setState(() {
      _isAnalyticsExpanded = !_isAnalyticsExpanded;
    });

    if (_isAnalyticsExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _onCategoryTap(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
    });
    _filterTransactions();
  }

  void _clearCategoryFilter() {
    setState(() {
      _selectedCategory = null;
    });
    _filterTransactions();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _statusFilter = 'All';
      _dateRange = null;
    });
    _filterTransactions();
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _statusFilter != 'All' ||
        _dateRange != null;
  }

  String _getActiveFiltersCount() {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_statusFilter != 'All') count++;
    if (_dateRange != null) count++;

    if (count == 0) return '';
    return '$count active filter${count > 1 ? 's' : ''}';
  }

  void _showDateRangePicker() async {
    final DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      helpText: 'Select Date Range',
      cancelText: 'Cancel',
      confirmText: 'Apply',
      saveText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        _dateRange = newRange;
      });

      // Show confirmation snackbar with highlighted range
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Date range selected: ${DateFormat('MMM dd').format(newRange.start)} - ${DateFormat('MMM dd, yyyy').format(newRange.end)}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Clear',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _dateRange = null;
              });
              _filterTransactions();
            },
          ),
        ),
      );

      _filterTransactions();
    }
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow(
                        'Transaction ID',
                        transaction['interaction_id'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Type',
                        (transaction['type'] as String? ?? '').toUpperCase(),
                      ),
                      _buildDetailRow(
                        'Status',
                        (transaction['status'] as String? ?? '').toUpperCase(),
                      ),
                      _buildDetailRow(
                        'Location',
                        transaction['scan_point_name'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Description',
                        transaction['remarks'] ?? 'N/A',
                      ),
                      if (transaction['amount'] != null)
                        _buildDetailRow(
                          'Amount',
                          'RM ${(transaction['amount'] as num).toStringAsFixed(2)}',
                        ),
                      if (transaction['payment_method'] != null)
                        _buildDetailRow(
                          'Payment Method',
                          transaction['payment_method'],
                        ),
                      if (transaction['timestamp'] != null)
                        _buildDetailRow(
                          'Date & Time',
                          _formatTimestamp(transaction['timestamp']),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== Helper Methods ==========
  String _getFilterSummaryText() {
    List<String> filters = [];

    // Add date range if set
    if (_dateRange != null) {
      filters.add(_getShortDateRange());
    } else {
      filters.add('All time');
    }

    // Add status filter if not 'All'
    if (_statusFilter != 'All') {
      filters.add(_statusFilter);
    }

    // Add category if selected
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filters.add(_getShortCategoryName(_selectedCategory!));
    }

    return filters.join(' • ');
  }

  String _getDateRangeText() {
    if (_dateRange == null) return 'All time';

    final start = DateFormat('MMM dd').format(_dateRange!.start);
    final end = DateFormat('MMM dd, yyyy').format(_dateRange!.end);
    return '$start - $end';
  }

  String _getShortDateRange() {
    if (_dateRange == null) return 'All time';

    final start = DateFormat('MMM dd').format(_dateRange!.start);
    final end = DateFormat('MMM dd').format(_dateRange!.end);
    return '$start - $end';
  }

  String _getShortCategoryName(String fullName) {
    final Map<String, String> shortNames = {
      'Smokey Café': 'Café',
      'Campus Mart': 'Mart',
      'Library Counter': 'Library',
      'Lab A Room Booking': 'Lab',
      'Lecture Hall B Attendance': 'Lecture',
      'Main Gate Access': 'Access',
    };

    return shortNames[fullName] ??
        (fullName.length > 10 ? fullName.substring(0, 10) : fullName);
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'N/A';
    }

    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }
}
