import 'package:apid/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:apid/services/user_service.dart';
import 'package:apid/pages_admin/utils/admin_theme.dart';

class PermissionDialog extends StatefulWidget {
  final String uid;
  final String role;
  final Map<String, bool> currentPermissions;

  const PermissionDialog({
    super.key,
    required this.uid,
    required this.role,
    required this.currentPermissions,
  });

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  late Map<String, bool> _permissions;
  bool _isLoading = false;
  Future<List<QueryDocumentSnapshot>>? _accessPointsFuture;

  @override
  void initState() {
    super.initState();
    _permissions = Map.from(widget.currentPermissions);
    // 🕵️‍♂️ Phase 2: Fetch Dynamic Access Points
    _accessPointsFuture = AdminService.getAccessPoints();
  }

  Future<void> _savePermissions() async {
    setState(() => _isLoading = true);
    try {
      await UserService.updateUserPermissions(widget.uid, _permissions);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating permissions: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  /// 🎨 Jelly Style: Get Icon based on Scan Point Type
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'library':
        return Icons.menu_book_rounded;
      case 'access':
        return Icons.door_sliding_rounded;
      case 'lab':
      case 'facility':
        return Icons.science_rounded;
      default:
        return Icons.meeting_room_rounded;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AdminTheme.primaryColor.withOpacity(0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    String? subtitle,
  }) {
    // 🎨 Jelly UI: Rounded Switch Tile
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value 
                ? AdminTheme.primaryColor.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: value ? AdminTheme.primaryColor : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        value: value,
        activeColor: AdminTheme.primaryColor,
        onChanged: _isLoading ? null : onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AdminTheme.primaryColor,
              AdminTheme.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permissions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Managing ${widget.role.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 450,
        // Make it scrollable but constrained height
        height: 500, 
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: System Capabilities
                    _buildSectionHeader('System Capabilities'),
                    _buildSwitch(
                      title: 'Make Transactions',
                      subtitle: 'Allow payment using wallet',
                      icon: Icons.account_balance_wallet_rounded,
                      value: _permissions['make_transaction'] ?? true,
                      onChanged: (v) => setState(() => _permissions['make_transaction'] = v),
                    ),
                    _buildSwitch(
                      title: 'Join Events',
                      subtitle: 'Register for campus activities',
                      icon: Icons.event_available_rounded,
                      value: _permissions['join_event'] ?? true,
                      onChanged: (v) => setState(() => _permissions['join_event'] = v),
                    ),

                    // Section 2: Physical Access (Dynamic)
                    _buildSectionHeader('Restricted Access Points'),
                    FutureBuilder<List<QueryDocumentSnapshot>>(
                      future: _accessPointsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Failed to load access points',
                              style: TextStyle(color: Colors.red[300]),
                            ),
                          );
                        }

                        final docs = snapshot.data ?? [];
                        if (docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Text(
                              'No restricted areas found',
                              style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                            ),
                          );
                        }

                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final id = doc.id; // e.g., SP006
                            final name = data['name'] ?? 'Unknown Point';
                            final type = data['type'] ?? 'access';
                            
                            // Check permission using ID (SPxxx)
                            final isAllowed = _permissions[id] ?? false;

                            return _buildSwitch(
                              title: name,
                              subtitle: id, // Show ID as subtitle for clarity
                              icon: _getIconForType(type),
                              value: isAllowed,
                              onChanged: (v) => setState(() => _permissions[id] = v),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? _savePermissions : _savePermissions,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              ) 
            : const Text('Save Changes'),
        ),
      ],
    );
  }
}
