// lib/pages_admin/components/users_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';
import 'package:apid/pages_admin/widgets/jelly_card.dart';
import 'package:apid/services/user_service.dart';
import 'package:apid/services/admin_service.dart';
import 'package:apid/pages_admin/components/permission_dialog.dart';
import 'dart:async';

/// 👥 Users Management Page
/// User management grid with server-side search and pagination
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<DocumentSnapshot> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _fetchUsers(loadMore: true);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.toLowerCase();
        _users.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _fetchUsers();
    });
  }

  Future<void> _fetchUsers({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await AdminService.getUsers(
        limit: 20,
        startAfter: loadMore ? _lastDocument : null,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final newUsers = result['users'] as List<DocumentSnapshot>;
      final lastDoc = result['lastDoc'] as DocumentSnapshot?;
      final hasMore = result['hasMore'] as bool;

      if (mounted) {
        setState(() {
          if (loadMore) {
            _users.addAll(newUsers);
          } else {
            _users = newUsers;
          }
          _lastDocument = lastDoc;
          _hasMore = hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _updateUserStatus(String uid, String newStatus) async {
    try {
      final result = await AdminService.updateUserStatus(
        uid: uid,
        newStatus: newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User status updated to $newStatus. ${result['updatedScanPoints']} scan points updated.',
            ),
            backgroundColor: JellyTheme.secondary,
          ),
        );

        // Optional: refresh current page data to reflect status badge change.
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: JellyTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showPermissionDialog(String uid, String role) async {
    try {
      final permissions = await UserService.getUserPermissions(uid);

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => PermissionDialog(
          uid: uid,
          role: role,
          currentPermissions: permissions,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading permissions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔍 Search Bar (Glassmorphism)
        Container(
          padding: const EdgeInsets.only(bottom: 24),
          child: TextField(
            controller: _searchController,
            style: JellyTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search by email...',
              hintStyle: JellyTheme.labelSmall.copyWith(fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: JellyTheme.primary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: const BorderSide(color: JellyTheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // 👥 Users Grid
        Expanded(
          child: _users.isEmpty && !_isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_rounded, size: 64, color: JellyTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No users found', style: JellyTheme.titleLarge.copyWith(color: JellyTheme.textSecondary)),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 1400 ? 4 : width > 1000 ? 3 : width > 700 ? 2 : 1;

                    return GridView.builder(
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.85, // Taller for cards
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _users.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _users.length) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final doc = _users[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _UserCard(
                          data: data,
                          onStatusChanged: (status) => _updateUserStatus(doc.id, status),
                          onPermissionsPressed: () => _showPermissionDialog(doc.id, data['role'] ?? 'student'),
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

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String) onStatusChanged;
  final VoidCallback onPermissionsPressed;

  const _UserCard({
    required this.data,
    required this.onStatusChanged,
    required this.onPermissionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = data['first_name'] ?? '';
    final lastName = data['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = data['email'] ?? 'N/A';
    final role = data['role'] ?? 'student';
    final status = data['qr_status'] ?? 'active';
    final walletBalance = ((data['wallet_balance'] ?? 0.0) as num).toDouble();

    return JellyCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 👤 Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: JellyTheme.primary.withOpacity(0.1),
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: JellyTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 📝 Name & Email
          Text(
            fullName.isEmpty ? 'Unknown User' : fullName,
            style: JellyTheme.titleLarge.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: JellyTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // 🏷️ Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: JellyTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: JellyTheme.primary.withOpacity(0.2)),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: JellyTheme.primary,
                letterSpacing: 1,
              ),
            ),
          ),
          const Spacer(),

          // 💰 Stats (Wallet Balance)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'RM ${walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ⚙️ Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Status Toggle
              PopupMenuButton<String>(
                tooltip: 'Change Status',
                initialValue: status,
                onSelected: onStatusChanged,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'active',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Active'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'banned',
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Banned'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: status == 'active' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status == 'active' ? Icons.check_circle_rounded : Icons.block_rounded,
                        size: 16,
                        color: status == 'active' ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status == 'active' ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Permissions
              IconButton(
                icon: const Icon(Icons.vpn_key_rounded, color: JellyTheme.textSecondary),
                tooltip: 'Permissions',
                onPressed: onPermissionsPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
