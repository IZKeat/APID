// lib/pages_admin/components/scanpoints_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';
import 'package:apid/pages_admin/widgets/jelly_card.dart';
import 'package:apid/pages_admin/utils/admin_theme.dart'; // Keeping for helpers
import 'package:apid/services/admin_service.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

/// 🎯 Scan Points Management Page
/// List/grid of scan_points with filters and live status
class ScanPointsPage extends StatefulWidget {
  const ScanPointsPage({super.key});

  @override
  State<ScanPointsPage> createState() => _ScanPointsPageState();
}

class _ScanPointsPageState extends State<ScanPointsPage> {
  String _selectedType = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<String> _types = [
    'all',
    'commerce',
    'library',
    'access',
    'booking',
  ];

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
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔍 Search Bar
        Container(
          padding: const EdgeInsets.only(bottom: 24),
          child: Container(
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
                      hintText: 'Search scan points by name...',
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
        ),

        // 🏷️ Filter Bar
        Container(
          padding: const EdgeInsets.only(bottom: 24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = type),
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut, // FIX: easeOutBack caused negative shadow blur
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? JellyTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isSelected ? JellyTheme.jellyShadow : [],
                        border: Border.all(
                          color: isSelected ? Colors.transparent : JellyTheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AdminTheme.getScanPointTypeIcon(type == 'all' ? null : type),
                            size: 18,
                            color: isSelected ? Colors.white : AdminTheme.getScanPointTypeColor(type),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : JellyTheme.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // 🎯 Scan Points Grid
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: AdminService.getScanPointsStream(
              type: _selectedType,
              searchQuery: _searchQuery,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: JellyTheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}', style: JellyTheme.bodyMedium),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 64, color: JellyTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No scan points found', style: JellyTheme.titleLarge.copyWith(color: JellyTheme.textSecondary)),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1400 ? 4 : width > 1000 ? 3 : width > 700 ? 2 : 1;

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return _ScanPointCard(data: data);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScanPointCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ScanPointCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final String type = (data['type'] ?? 'unknown').toString();
    final String name = (data['name'] ?? 'Unknown').toString();
    final String location = (data['location'] ?? 'Unknown').toString();
    final String status = (data['status'] ?? 'active').toString();
    final bool isBanned = status == 'banned';
    final int interactionCount = (data['interaction_count'] ?? 0) as int;
    final num? revenue = (data['revenue'] as num?);
    final Timestamp? lastActive = data['last_active'] as Timestamp?;

    final typeColor = AdminTheme.getScanPointTypeColor(type);

    final card = JellyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AdminTheme.getScanPointTypeIcon(type),
                  color: typeColor,
                  size: 24,
                ),
              ),
              const Spacer(),
              _HeartbeatBadge(lastActive: lastActive),
            ],
          ),
          const SizedBox(height: 16),

          // 📝 Info
          Text(
            name,
            style: JellyTheme.titleLarge.copyWith(fontSize: 18),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: JellyTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: JellyTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),

          // 📊 Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: JellyTheme.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 16, color: JellyTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '$interactionCount',
                  style: JellyTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (type == 'commerce' && revenue != null) ...[
                  const Icon(Icons.attach_money_rounded, size: 16, color: Colors.green),
                  Text(
                    revenue.toStringAsFixed(2),
                    style: JellyTheme.bodyMedium.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (isBanned) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: card,
      );
    }

    return card;
  }
}

class _HeartbeatBadge extends StatefulWidget {
  final Timestamp? lastActive;

  const _HeartbeatBadge({this.lastActive});

  @override
  State<_HeartbeatBadge> createState() => _HeartbeatBadgeState();
}

class _HeartbeatBadgeState extends State<_HeartbeatBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lastActive == null) {
      return _buildBadge(Colors.grey, 'OFFLINE', false);
    }

    final diff = DateTime.now().difference(widget.lastActive!.toDate());
    final isOnline = diff.inMinutes < 5;

    return _buildBadge(
      isOnline ? JellyTheme.secondary : JellyTheme.error,
      isOnline ? 'ONLINE' : 'OFFLINE',
      isOnline,
    );
  }

  Widget _buildBadge(Color color, String text, bool animate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animate)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
