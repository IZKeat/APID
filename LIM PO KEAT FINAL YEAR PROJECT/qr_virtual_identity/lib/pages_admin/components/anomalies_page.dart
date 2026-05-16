// lib/pages_admin/components/anomalies_page.dart
import 'package:flutter/material.dart';
import 'package:apid/services/admin_service.dart';
import 'package:intl/intl.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';
import 'package:apid/pages_admin/widgets/jelly_card.dart';
import 'package:apid/services/user_cache_service.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

/// 🚨 Anomalies Page
/// Security alerts with shake animations and Jelly styling
class AnomaliesPage extends StatefulWidget {
  const AnomaliesPage({super.key});

  @override
  State<AnomaliesPage> createState() => _AnomaliesPageState();
}

class _AnomaliesPageState extends State<AnomaliesPage> {
  // No local state needed for data, StreamBuilder handles it.
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: JellyTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: JellyTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _resolveAnomaly(String anomalyId) async {
    try {
      await AdminService.resolveAnomaly(anomalyId, 'Resolved by admin via dashboard');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anomaly resolved successfully'),
            backgroundColor: JellyTheme.success,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve: $e'),
            backgroundColor: JellyTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Security Anomalies',
                style: JellyTheme.headlineMedium,
              ),
              Row(
                children: [
                   IconButton(
                    icon: Icon(
                      Icons.calendar_today_rounded,
                      color: _selectedDateRange != null ? JellyTheme.primary : JellyTheme.textSecondary,
                    ),
                    onPressed: _pickDateRange,
                    tooltip: 'Filter by Date',
                    style: IconButton.styleFrom(
                      backgroundColor: _selectedDateRange != null 
                          ? JellyTheme.primary.withOpacity(0.1) 
                          : Colors.transparent,
                    ),
                  ),
                  if (_selectedDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: JellyTheme.textSecondary),
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                      },
                      tooltip: 'Clear Filter',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 🔍 Search Bar
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: JellyTheme.jellyShadow,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: JellyTheme.textSecondary),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search anomalies (Email, Type, IP)...',
                      hintStyle: GoogleFonts.inter(
                        color: JellyTheme.textSecondary.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.inter(
                      color: JellyTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: JellyTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 🚨 Anomalies List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AdminService.getAnomaliesStream(
                startDate: _selectedDateRange?.start,
                endDate: _selectedDateRange?.end,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: JellyTheme.error),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', style: JellyTheme.bodyMedium),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final anomalies = snapshot.data ?? [];

                // 🚀 Prefetch emails
                final uids = anomalies.map((a) => a['uid'] as String? ?? '').where((uid) => uid.isNotEmpty).toList();
                UserCacheService().prefetch(uids);

                // 🔍 Local Filtering
                final filteredAnomalies = anomalies.where((anomaly) {
                  if (_searchQuery.isEmpty) return true;
                  
                  final uid = anomaly['uid'] as String? ?? '';
                  final email = UserCacheService().getEmailSync(uid)?.toLowerCase() ?? '';
                  final type = (anomaly['type'] ?? '').toString().toLowerCase();
                  final ip = (anomaly['ip'] ?? '').toString().toLowerCase();
                  final detail = (anomaly['detail'] ?? '').toString().toLowerCase();

                  return email.contains(_searchQuery) ||
                         type.contains(_searchQuery) ||
                         ip.contains(_searchQuery) ||
                         detail.contains(_searchQuery);
                }).toList();

                if (filteredAnomalies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 64, color: JellyTheme.success),
                        const SizedBox(height: 16),
                        const Text(
                          'All Clear!',
                          style: JellyTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('No security anomalies detected.', style: JellyTheme.bodyMedium.copyWith(color: JellyTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredAnomalies.length,
                  itemBuilder: (context, index) {
                    final anomaly = filteredAnomalies[index];
                    return _AnomalyCard(
                      key: ValueKey(anomaly['id'] ?? index),
                      anomaly: anomaly,
                      onResolve: () => _resolveAnomaly(anomaly['id'] ?? 'unknown'),
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
}

class _AnomalyCard extends StatefulWidget {
  final Map<String, dynamic> anomaly;
  final VoidCallback onResolve;

  const _AnomalyCard({super.key, required this.anomaly, required this.onResolve});

  @override
  State<_AnomalyCard> createState() => _AnomalyCardState();
}

class _AnomalyCardState extends State<_AnomalyCard> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _startShake() {
    _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final anomaly = widget.anomaly;
    final timestamp = anomaly['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(anomaly['timestamp'])
        : null;
    final timeStr = timestamp != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp)
        : '-';

    final type = anomaly['type'] ?? 'Unknown Anomaly';
    final isCritical = type.contains('Critical') || 
                       type.contains('Multi-Device') || 
                       type.contains('High Frequency') || 
                       type.contains('Blacklisted');
    
    final themeColor = isCritical ? JellyTheme.error : JellyTheme.jellyOrange;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        if (isCritical) _startShake();
      },
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final offset = 10 * (0.5 - (0.5 - _shakeController.value).abs()) * 2;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: Dismissible(
          key: widget.key!,
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: JellyTheme.success,
              borderRadius: JellyTheme.cardRadius,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'RESOLVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.check_rounded, color: Colors.white),
              ],
            ),
          ),
          onDismissed: (_) => widget.onResolve(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: JellyCard(
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // ⚠️ Warning Stripe
                    Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // ℹ️ Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCritical ? Icons.gpp_bad_rounded : Icons.warning_amber_rounded,
                        color: themeColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 📝 Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                type,
                                style: JellyTheme.titleMedium.copyWith(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_isHovering)
                                const Text(
                                  'Swipe to resolve',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: JellyTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            anomaly['detail'] ?? 'No details provided',
                            style: JellyTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: [
                              _buildMeta(Icons.access_time_rounded, timeStr),
                              if (anomaly['uid'] != null)
                                FutureBuilder<String>(
                                  future: UserCacheService().getEmail(anomaly['uid']),
                                  builder: (context, snapshot) {
                                    final email = snapshot.data ?? anomaly['uid'];
                                    return _buildMeta(Icons.person_outline_rounded, email);
                                  },
                                ),
                              if (anomaly['ip'] != null)
                                _buildMeta(Icons.wifi_rounded, 'IP: ${anomaly['ip']}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: JellyTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: JellyTheme.labelSmall.copyWith(color: JellyTheme.textSecondary),
        ),
      ],
    );
  }
}
