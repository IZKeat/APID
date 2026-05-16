// lib/pages_admin/components/settings_page.dart
import 'package:flutter/material.dart';

/// ⚙️ Admin Settings Page
/// Configuration and system settings (placeholder)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ System Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Settings Categories
          _SettingsSection(
            title: 'General Settings',
            icon: Icons.settings,
            color: Colors.blue,
            children: [
              _SettingItem(
                title: 'System Name',
                subtitle: 'QR Virtual Identity System',
                trailing: const Icon(Icons.edit),
                onTap: () {},
              ),
              _SettingItem(
                title: 'Time Zone',
                subtitle: 'UTC+8 (Malaysia)',
                trailing: const Icon(Icons.edit),
                onTap: () {},
              ),
              _SettingItem(
                title: 'Language',
                subtitle: 'English',
                trailing: const Icon(Icons.edit),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SettingsSection(
            title: 'Security Settings',
            icon: Icons.security,
            color: Colors.red,
            children: [
              _SettingItem(
                title: 'Session Timeout',
                subtitle: '30 minutes',
                trailing: const Icon(Icons.edit),
                onTap: () {},
              ),
              _SettingItem(
                title: 'Two-Factor Authentication',
                subtitle: 'Disabled',
                trailing: Switch(value: false, onChanged: (value) {}),
                onTap: () {},
              ),
              _SettingItem(
                title: 'Password Policy',
                subtitle: 'Minimum 6 characters',
                trailing: const Icon(Icons.edit),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SettingsSection(
            title: 'Data Management',
            icon: Icons.storage,
            color: Colors.orange,
            children: [
              _SettingItem(
                title: 'Database Backup',
                subtitle: 'Last backup: Never',
                trailing: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Backup Now'),
                ),
                onTap: () {},
              ),
              _SettingItem(
                title: 'Clear Cache',
                subtitle: 'Free up storage space',
                trailing: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Clear'),
                ),
                onTap: () {},
              ),
              _SettingItem(
                title: 'Export Data',
                subtitle: 'Download all system data',
                trailing: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Export'),
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SettingsSection(
            title: 'System Information',
            icon: Icons.info,
            color: Colors.green,
            children: [
              _InfoItem(label: 'Version', value: '1.0.0'),
              _InfoItem(label: 'Build', value: '2025.11.04'),
              _InfoItem(label: 'Database', value: 'Firebase Firestore'),
              _InfoItem(label: 'Environment', value: 'Emulator (Development)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingItem({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
