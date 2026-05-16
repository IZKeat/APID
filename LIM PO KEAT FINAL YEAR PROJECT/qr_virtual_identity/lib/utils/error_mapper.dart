// lib/utils/error_mapper.dart

/// Maps backend error codes to user-friendly messages
String mapBackendError(dynamic error) {
  final String message = error.toString();
  
  // Extract error code if it's a FirebaseFunctionsException
  // (The string format is usually "[code] message" or just "message")
  
  if (message.contains('SIG_MISSING')) {
    return 'Security Error: Missing signature. Please update your app.';
  }
  if (message.contains('SIG_INVALID')) {
    return 'Security Error: Invalid signature. QR code may be forged.';
  }
  if (message.contains('QR_EXPIRED')) {
    return 'QR Code Expired. Please regenerate.';
  }
  if (message.contains('NONCE_REUSED')) {
    return 'QR Code already used. Please regenerate.';
  }
  if (message.contains('BLACKLISTED')) {
    return 'Access Denied: User is blacklisted.';
  }
  if (message.contains('INSUFFICIENT_BALANCE')) {
    return 'Payment Failed: Insufficient balance.';
  }
  if (message.contains('USER_NOT_FOUND')) {
    return 'User not found.';
  }
  if (message.contains('PERMISSION_DENIED')) {
    return 'Access Denied: You do not have permission.';
  }
  if (message.contains('resource-exhausted') || message.contains('limit exceeded')) {
    return 'Rate Limit Exceeded: Please wait a moment before scanning again.';
  }
  if (message.contains('ANOMALY_DETECTED')) {
    return 'Security Alert: Unusual activity detected. Please contact admin.';
  }
  
  // Default fallback
  return 'Scan failed: ${message.replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
}
