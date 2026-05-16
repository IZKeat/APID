// lib/utils/qr_parser.dart

import 'dart:convert';
import 'ticket_parser.dart';

/// 🔍 QR Code Types Enumeration
/// Defines all supported QR code formats in the system
enum QrType {
  /// TICKET:event_id:user_id:timestamp - Event check-in tickets
  ticket,

  /// USER:<user_id> - Student/user identity for payments or identification
  user,

  /// SCANPOINT:<scan_point_id> or MERCHANT:<scan_point_id> - Merchant counters/gates/library desks
  scanPoint,

  /// ITEM:<item_id> - Books, resources, or physical items for borrowing/usage
  item,

  /// Unknown or invalid format
  unknown,
}

/// 📋 QR Code Parse Result Data Class
/// Contains parsed QR code data with type-specific fields
class QrParseResult {
  /// The detected QR code type
  final QrType type;

  /// Original raw QR string
  final String raw;

  /// Parsed ticket data (only for TICKET type)
  final TicketParser? ticket;

  /// User ID (only for USER type)
  final String? userId;

  /// User email (only for USER type with JSON format)
  final String? email;

  /// User name (only for USER type with JSON format)
  final String? name;

  /// User role (only for USER type with JSON format)
  final String? role;

  /// Timestamp (for dynamic QR codes)
  final int? timestamp;

  /// Nonce (for anti-replay security)
  final String? nonce;

  /// HMAC Signature (for anti-forgery security)
  final String? sig;

  /// Scan point ID (only for SCANPOINT/MERCHANT type)
  final String? scanPointId;

  /// Item ID (only for ITEM type)
  final String? itemId;

  /// Error message if parsing failed
  final String? errorMessage;

  const QrParseResult._({
    required this.type,
    required this.raw,
    this.ticket,
    this.userId,
    this.email,
    this.name,
    this.role,
    this.timestamp,
    this.nonce,
    this.sig,
    this.scanPointId,
    this.itemId,
    this.errorMessage,
  });

  /// Factory constructor for successful ticket parsing
  factory QrParseResult.ticket(String raw, TicketParser ticket) {
    return QrParseResult._(type: QrType.ticket, raw: raw, ticket: ticket);
  }

  /// Factory constructor for successful user parsing
  factory QrParseResult.user(
    String raw,
    String userId, {
    String? email,
    String? name,
    String? role,
    int? timestamp,
    String? nonce,
    String? sig,
  }) {
    return QrParseResult._(
      type: QrType.user,
      raw: raw,
      userId: userId,
      email: email,
      name: name,
      role: role,
      timestamp: timestamp,
      nonce: nonce,
      sig: sig,
    );
  }

  /// Factory constructor for successful scan point parsing
  factory QrParseResult.scanPoint(String raw, String scanPointId) {
    return QrParseResult._(
      type: QrType.scanPoint,
      raw: raw,
      scanPointId: scanPointId,
    );
  }

  /// Factory constructor for successful item parsing
  factory QrParseResult.item(String raw, String itemId) {
    return QrParseResult._(type: QrType.item, raw: raw, itemId: itemId);
  }

  /// Factory constructor for parsing errors
  factory QrParseResult.error(String raw, String errorMessage) {
    return QrParseResult._(
      type: QrType.unknown,
      raw: raw,
      errorMessage: errorMessage,
    );
  }

  /// Check if the QR code was successfully parsed
  bool get isValid => type != QrType.unknown && errorMessage == null;

  /// Check if the QR code has expired (valid for 60 seconds)
  /// Returns false if no timestamp is present (legacy support)
  bool get isExpired {
    if (timestamp == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    // 60 seconds = 60000 milliseconds
    return now - timestamp! > 60000;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('QrParseResult(');
    buffer.write('type: $type, ');
    buffer.write(
      'raw: "${raw.length > 50 ? '${raw.substring(0, 50)}...' : raw}", ',
    );
    buffer.write('isValid: $isValid');

    switch (type) {
      case QrType.ticket:
        buffer.write(', ticket: $ticket');
        break;
      case QrType.user:
        buffer.write(', userId: $userId');
        if (email != null) buffer.write(', email: $email');
        if (name != null) buffer.write(', name: $name');
        if (role != null) buffer.write(', role: $role');
        if (timestamp != null) buffer.write(', ts: $timestamp');
        if (nonce != null) buffer.write(', nonce: $nonce');
        if (sig != null) buffer.write(', sig: ${sig!.substring(0, 8)}...');
        break;
      case QrType.scanPoint:
        buffer.write(', scanPointId: $scanPointId');
        break;
      case QrType.item:
        buffer.write(', itemId: $itemId');
        break;
      case QrType.unknown:
        buffer.write(', error: $errorMessage');
        break;
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QrParseResult &&
        other.type == type &&
        other.raw == raw &&
        other.ticket == ticket &&
        other.userId == userId &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        other.timestamp == timestamp &&
        other.nonce == nonce &&
        other.sig == sig &&
        other.scanPointId == scanPointId &&
        other.itemId == itemId &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
          type,
          raw,
          ticket,
          userId,
          email,
          name,
          role,
          timestamp,
          nonce,
          sig,
        ) ^
        Object.hash(scanPointId, itemId, errorMessage);
  }
}

/// 🎯 Universal QR Code Parser
/// Handles all supported QR code formats in the QR Virtual Identity system
class QRParser {
  /// Parse any QR code string into structured data
  ///
  /// Supports the following formats:
  /// - TICKET:event_id:user_id:timestamp (handled by existing TicketParser)
  /// - USER:<user_id> (for student/user identification)
  /// - JSON format: {"uid": "...", "email": "...", "name": "...", "role": "...", "ts": ...}
  /// - SCANPOINT:<scan_point_id> or MERCHANT:<scan_point_id> (for merchant terminals)
  /// - ITEM:<item_id> (for library books or physical resources)
  ///
  /// Returns QrParseResult with type-specific data or error information
  static QrParseResult parse(String qrData) {
    try {
      // Normalize input - trim whitespace
      final cleanData = qrData.trim();

      if (cleanData.isEmpty) {
        return QrParseResult.error(qrData, 'Empty QR code data');
      }

      // 0. Check for JSON format first (new dynamic user QR from profile page)
      // Format: {"uid": "...", "email": "...", "name": "...", "role": "...", "ts": ...}
      if (cleanData.startsWith('{') && cleanData.endsWith('}')) {
        try {
          final jsonData = jsonDecode(cleanData) as Map<String, dynamic>;

          // Check if this is a user QR (has uid field)
          if (jsonData.containsKey('uid')) {
            final uid = jsonData['uid'] as String?;
            if (uid == null || uid.isEmpty) {
              return QrParseResult.error(
                qrData,
                'Invalid JSON user QR: missing or empty uid',
              );
            }

            return QrParseResult.user(
              qrData,
              uid,
              email: jsonData['email'] as String?,
              name: jsonData['name'] as String?,
              role: jsonData['role'] as String?,
              timestamp: jsonData['ts'] as int?,
              nonce: jsonData['nonce'] as String?,
              sig: jsonData['sig'] as String?,
            );
          }

          // Unknown JSON format
          return QrParseResult.error(
            qrData,
            'Unknown JSON QR format (missing uid field)',
          );
        } catch (e) {
          // Not valid JSON or parsing error - continue to other format checks
          print('⚠️ [QRParser] JSON parse failed, trying other formats: $e');
        }
      }

      // 1. Check for TICKET format (highest priority - existing system)
      // Format: TICKET:event_id:user_id:timestamp
      if (cleanData.toUpperCase().startsWith('TICKET:')) {
        try {
          final ticket = TicketParser.fromQrData(cleanData);
          if (ticket != null) {
            return QrParseResult.ticket(qrData, ticket);
          } else {
            return QrParseResult.error(
              qrData,
              'Invalid TICKET format or expired ticket',
            );
          }
        } catch (e) {
          return QrParseResult.error(
            qrData,
            'TICKET parsing error: ${e.toString()}',
          );
        }
      }

      // 2. Check for raw ISBN/barcode format (pure numbers without prefix)
      // This MUST be checked BEFORE splitting by colon
      // Format: 9780131103627 (MUST be exactly 13 digits for EAN-13 ISBN)
      if (RegExp(r'^[0-9]+$').hasMatch(cleanData)) {
        // Check if it's EXACTLY 13-digit EAN-13 barcode (standard ISBN format)
        if (RegExp(r'^[0-9]{13}$').hasMatch(cleanData)) {
          print('📚 [QRParser] Detected raw ISBN-13 barcode: $cleanData');
          return QrParseResult.item(qrData, cleanData);
        }
        // Reject barcodes that are too short or too long
        return QrParseResult.error(
          qrData,
          'Invalid ISBN length. Expected exactly 13 digits (EAN-13), got ${cleanData.length} digits',
        );
      }

      // 3. Split by colon for other formats
      final parts = cleanData.split(':');
      if (parts.length < 2) {
        return QrParseResult.error(
          qrData,
          'Invalid QR format - expected TICKET:, USER:, ITEM:, SCANPOINT:, MERCHANT:, or ISBN-13 barcode',
        );
      }

      final prefix = parts[0].trim().toUpperCase();
      final identifier = parts[1].trim();

      // Validate that identifier is not empty
      if (identifier.isEmpty) {
        return QrParseResult.error(qrData, 'Empty identifier after prefix');
      }

      // 4. Check for USER format
      // Format: USER:<user_id>
      if (prefix == 'USER') {
        // Basic validation for user ID (non-empty, reasonable length)
        if (identifier.length < 3 || identifier.length > 50) {
          return QrParseResult.error(
            qrData,
            'Invalid user ID length (must be 3-50 characters)',
          );
        }
        return QrParseResult.user(qrData, identifier);
      }

      // 5. Check for SCANPOINT or MERCHANT format (both map to scanPoint type)
      // Format: SCANPOINT:<scan_point_id> or MERCHANT:<scan_point_id>
      if (prefix == 'SCANPOINT' || prefix == 'MERCHANT') {
        // Basic validation for scan point ID
        if (identifier.length < 3 || identifier.length > 50) {
          return QrParseResult.error(
            qrData,
            'Invalid scan point ID length (must be 3-50 characters)',
          );
        }
        return QrParseResult.scanPoint(qrData, identifier);
      }

      // 6. Check for ITEM format
      // Format: ITEM:<item_id>
      if (prefix == 'ITEM') {
        // Basic validation for item ID
        if (identifier.isEmpty || identifier.length > 100) {
          return QrParseResult.error(
            qrData,
            'Invalid item ID length (must be 1-100 characters)',
          );
        }
        return QrParseResult.item(qrData, identifier);
      }

      // 7. Unknown format
      return QrParseResult.error(
        qrData,
        'Unsupported QR format. Expected: TICKET, USER, SCANPOINT, MERCHANT, ITEM prefix, or ISBN-13 barcode',
      );
    } catch (e) {
      // Catch any unexpected errors and return error result
      return QrParseResult.error(
        qrData,
        'Unexpected parsing error: ${e.toString()}',
      );
    }
  }

  /// Quick type detection without full parsing
  /// Useful for routing decisions before expensive parsing operations
  static QrType detectType(String qrData) {
    try {
      final cleanData = qrData.trim();
      final upperData = cleanData.toUpperCase();

      // Check for JSON format (new dynamic user QR)
      if (cleanData.startsWith('{') && cleanData.endsWith('}')) {
        try {
          final jsonData = jsonDecode(cleanData) as Map<String, dynamic>;
          if (jsonData.containsKey('uid')) {
            return QrType.user;
          }
        } catch (e) {
          // Not valid JSON, continue checking other formats
        }
      }

      // Check for raw ISBN-13 barcode (pure 13-digit number)
      if (RegExp(r'^[0-9]{13}$').hasMatch(cleanData)) {
        return QrType.item;
      }

      if (upperData.startsWith('TICKET:')) return QrType.ticket;
      if (upperData.startsWith('USER:')) return QrType.user;
      if (upperData.startsWith('SCANPOINT:') ||
          upperData.startsWith('MERCHANT:')) {
        return QrType.scanPoint;
      }
      if (upperData.startsWith('ITEM:')) return QrType.item;

      return QrType.unknown;
    } catch (e) {
      return QrType.unknown;
    }
  }

  /// Validate QR format without parsing (for quick validation)
  static bool isValidFormat(String qrData) {
    return detectType(qrData) != QrType.unknown;
  }
}
