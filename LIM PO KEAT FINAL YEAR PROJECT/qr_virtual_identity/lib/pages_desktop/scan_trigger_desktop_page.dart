import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanTriggerDesktopPage extends StatelessWidget {
  const ScanTriggerDesktopPage({
    super.key,
    this.onTrigger,
    this.onStopTrigger,
    required this.isTriggered,
    this.onTriggerLibraryBorrow,
    this.onTriggerLibraryReturn,
    this.onTriggerAccess,
    this.accessControlTitle = 'Access Control',
    this.accessControlButtonLabel = 'Access Control Mode',
    this.hideGenericTrigger = false,
    this.isProcessing = false,
  });

  final VoidCallback? onTrigger;
  final VoidCallback? onStopTrigger;
  final VoidCallback? onTriggerLibraryBorrow;
  final VoidCallback? onTriggerLibraryReturn;
  final VoidCallback? onTriggerAccess;
  final bool isTriggered;
  final bool isProcessing;
  final String accessControlTitle;
  final String accessControlButtonLabel;
  final bool hideGenericTrigger;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Mobile QR Scanner',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Trigger your mobile device to open the QR scanner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Current user indicator
              if (user?.email != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Logged in as: ${user!.email}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
                if (isTriggered)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isProcessing ? Colors.blue.shade50 : Colors.green.shade50,
                    border: Border.all(
                      color: isProcessing ? Colors.blue.shade200 : Colors.green.shade200,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (isProcessing)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      else
                        Icon(Icons.smartphone, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isProcessing
                                  ? '⏳ Processing Scan...'
                                  : '📱 Mobile scanner is ACTIVE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isProcessing
                                    ? Colors.blue.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                            Text(
                              isProcessing
                                  ? 'Please wait while the mobile device processes the code.'
                                  : 'Check your mobile device to scan QR codes',
                              style: TextStyle(
                                fontSize: 12,
                                color: isProcessing
                                    ? Colors.blue.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isProcessing)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              // Generic trigger (optional)
              if ((!hideGenericTrigger || isTriggered) &&
                  (onTrigger != null || onStopTrigger != null))
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isTriggered ? onStopTrigger : onTrigger,
                    icon: Icon(
                      isTriggered
                          ? Icons.stop_circle_outlined
                          : Icons.qr_code_scanner,
                      size: 24,
                    ),
                    label: Text(
                      isTriggered
                          ? 'Stop Mobile Scanner'
                          : 'Trigger Mobile Scanner',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTriggered
                          ? Colors.red.shade600
                          : const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor:
                          (isTriggered
                                  ? Colors.red.shade600
                                  : const Color(0xFF6C63FF))
                              .withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              // Library Mode Trigger Buttons
              if ((onTriggerLibraryBorrow != null ||
                      onTriggerLibraryReturn != null) &&
                  !isTriggered) ...[
                const SizedBox(height: 24),
                const Text(
                  'Library Operations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 12),
                // Borrow Mode Button
                if (onTriggerLibraryBorrow != null)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onTriggerLibraryBorrow,
                      icon: const Icon(Icons.bookmark_add_rounded, size: 24),
                      label: const Text(
                        'Borrow Mode (Student + Book)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF4CAF50,
                        ), // Green for library
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (onTriggerLibraryBorrow != null &&
                    onTriggerLibraryReturn != null)
                  const SizedBox(height: 12),
                // Return Mode Button
                if (onTriggerLibraryReturn != null)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onTriggerLibraryReturn,
                      icon: const Icon(Icons.bookmark_remove_rounded, size: 24),
                      label: const Text(
                        'Return Mode (Book Only)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF2196F3,
                        ), // Blue for return
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF2196F3).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
              // Access Control Button
              if (onTriggerAccess != null && !isTriggered) ...[
                const SizedBox(height: 24),
                Text(
                  accessControlTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: hideGenericTrigger && isTriggered
                        ? onStopTrigger
                        : onTriggerAccess,
                    icon: Icon(
                      hideGenericTrigger && isTriggered
                          ? Icons.stop_circle_outlined
                          : Icons.security_rounded,
                      size: 24,
                    ),
                    label: Text(
                      hideGenericTrigger && isTriggered
                          ? 'Stop Access Mode'
                          : accessControlButtonLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFFF6B35,
                      ), // Orange for access
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFFFF6B35).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // How to use instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFF57C00),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'How to Use',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStep('1', 'Open your mobile app (Android/iOS)'),
                    const SizedBox(height: 8),
                    _buildStep('2', 'Login with the SAME merchant account'),
                    const SizedBox(height: 8),
                    _buildStep('3', 'Mobile will show QR Scanner page'),
                    const SizedBox(height: 8),
                    _buildStep('4', 'Click "Trigger" button above'),
                    const SizedBox(height: 8),
                    _buildStep('5', 'Scanner activates automatically! 📱'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E7FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF6C63FF),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ensure both devices are logged in to the same merchant account and have internet connection',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ); // Center
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
