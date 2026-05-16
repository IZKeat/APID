// lib/pages_admin/components/audit_logs_page.dart
import 'package:flutter/material.dart';
import 'package:apid/services/admin_service.dart';
import 'package:intl/intl.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';
import 'package:apid/pages_admin/widgets/jelly_card.dart';
import 'package:apid/services/user_cache_service.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

/// 📜 Audit Logs Page
/// Timeline view of system activities with Jelly animations
class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  int? _lastTimestamp;
  String? _error;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _scrollController.addListener(_onScroll);
  }

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

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isMoreLoading &&
        _hasMore) {
      _fetchLogs(loadMore: true);
    }
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
        _logs.clear();
        _lastTimestamp = null;
        _hasMore = true;
      });
      _fetchLogs();
    }
  }

  Future<void> _fetchLogs({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isMoreLoading = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final logs = await AdminService.getAuditLogs(
        lastTimestamp: loadMore ? _lastTimestamp : null,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _logs.addAll(logs);
          } else {
            _logs = logs;
          }

          if (logs.isNotEmpty) {
            _lastTimestamp = logs.last['timestamp'];
          }
          
          if (logs.length < 50) {
            _hasMore = false;
          }

          _isLoading = false;
          _isMoreLoading = false;
        });

        // 🚀 Prefetch emails for smoother search
        final uids = logs.map((l) => l['uid'] as String? ?? '').where((uid) => uid.isNotEmpty).toList();
        UserCacheService().prefetch(uids);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!loadMore) _error = e.toString();
          _isLoading = false;
          _isMoreLoading = false;
        });
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
              const Text(
                'System Audit Logs',
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
                          _logs.clear();
                          _lastTimestamp = null;
                          _hasMore = true;
                        });
                        _fetchLogs();
                      },
                      tooltip: 'Clear Filter',
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: JellyTheme.primary),
                    onPressed: () => _fetchLogs(),
                    tooltip: 'Refresh Logs',
                    style: IconButton.styleFrom(
                      backgroundColor: JellyTheme.primary.withOpacity(0.1),
                      hoverColor: JellyTheme.primary.withOpacity(0.2),
                    ),
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
                      hintText: 'Search logs (Email, Function, IP)...',
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


          
          // 📜 Timeline Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: JellyTheme.error),
            const SizedBox(height: 16),
            Text('Error: $_error', style: JellyTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _fetchLogs(),
              style: FilledButton.styleFrom(backgroundColor: JellyTheme.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: JellyTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No audit logs found', style: JellyTheme.titleLarge.copyWith(color: JellyTheme.textSecondary)),
          ],
        ),
      );
    }

    // 🔍 Local Filtering
    final filteredLogs = _logs.where((log) {
      if (_searchQuery.isEmpty) return true;
      
      final uid = log['uid'] as String? ?? '';
      final email = UserCacheService().getEmailSync(uid)?.toLowerCase() ?? '';
      final function = (log['function'] ?? '').toString().toLowerCase();
      final status = (log['status'] ?? '').toString().toLowerCase();
      final ip = (log['ip'] ?? '').toString().toLowerCase();
      final detail = (log['detail'] ?? log['error'] ?? '').toString().toLowerCase();

      return email.contains(_searchQuery) ||
             function.contains(_searchQuery) ||
             status.contains(_searchQuery) ||
             ip.contains(_searchQuery) ||
             detail.contains(_searchQuery);
    }).toList();

    if (filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: JellyTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No matching logs found', style: JellyTheme.titleLarge.copyWith(color: JellyTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredLogs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredLogs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final log = filteredLogs[index];
        // 🎞️ Staggered Animation
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0), // FIX: Prevent crash from easeOutBack overshoot
                child: child,
              ),
            );
          },
          child: _TimelineItem(log: log, isLast: index == filteredLogs.length - 1),
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isLast;

  const _TimelineItem({required this.log, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final timestamp = log['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(log['timestamp'])
        : null;
    final timeStr = timestamp != null
        ? DateFormat('HH:mm').format(timestamp)
        : '-';
    final dateStr = timestamp != null
        ? DateFormat('MMM dd').format(timestamp)
        : '-';
    
    final status = log['status'] ?? 'UNKNOWN';
    final function = log['function'] ?? 'Unknown Function';
    final detail = log['detail'] ?? log['error'] ?? 'No details';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'SUCCESS':
        statusColor = JellyTheme.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'ERROR':
        statusColor = JellyTheme.error;
        statusIcon = Icons.error_rounded;
        break;
      case 'STARTED':
        statusColor = JellyTheme.info;
        statusIcon = Icons.play_circle_rounded;
        break;
      default:
        statusColor = JellyTheme.textSecondary;
        statusIcon = Icons.info_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⏰ Time Column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeStr, style: JellyTheme.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                Text(dateStr, style: JellyTheme.labelSmall.copyWith(color: JellyTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 🔗 Timeline Line & Dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: JellyTheme.textSecondary.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // 📝 Card Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: JellyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          function,
                          style: JellyTheme.titleMedium.copyWith(color: statusColor),
                        ),
                        const Spacer(),
                        _buildStatusBadge(status, statusColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      style: JellyTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (log['uid'] != null)
                          FutureBuilder<String>(
                            future: UserCacheService().getEmail(log['uid']),
                            builder: (context, snapshot) {
                              final email = snapshot.data ?? log['uid'];
                              return _buildMetaTag(Icons.person_outline_rounded, email);
                            },
                          ),
                        if (log['ip'] != null)
                          _buildMetaTag(Icons.wifi_rounded, 'IP: ${log['ip']}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMetaTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: JellyTheme.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: JellyTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: JellyTheme.labelSmall.copyWith(color: JellyTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
