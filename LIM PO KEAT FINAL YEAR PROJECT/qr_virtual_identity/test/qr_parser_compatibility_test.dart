// Test file for QR Parser compatibility with new JSON format
// Run this file to verify that the parser correctly handles both old and new QR formats

import 'dart:convert';
import 'package:apid/utils/qr_parser.dart';

void main() {
  print('🧪 Testing QR Parser Compatibility\n');

  // Test 1: New JSON format from Profile Page
  print('📋 Test 1: New JSON User QR Format');
  final jsonQr = jsonEncode({
    'uid': 'abc123xyz789',
    'email': 'student@apu.edu.my',
    'name': 'John Doe',
    'role': 'user',
    'ts': 1700227200000,
  });

  final result1 = QRParser.parse(jsonQr);
  print('   Input: $jsonQr');
  print('   Type: ${result1.type}');
  print('   Valid: ${result1.isValid}');
  print('   User ID: ${result1.userId}');
  print('   Email: ${result1.email}');
  print('   Name: ${result1.name}');
  print('   Role: ${result1.role}');
  print('   Timestamp: ${result1.timestamp}');
  assert(result1.isValid, 'JSON QR should be valid');
  assert(result1.type == QrType.user, 'JSON QR should be type USER');
  assert(result1.userId == 'abc123xyz789', 'User ID should match');
  assert(result1.email == 'student@apu.edu.my', 'Email should match');
  assert(result1.name == 'John Doe', 'Name should match');
  assert(result1.role == 'user', 'Role should match');
  assert(result1.timestamp == 1700227200000, 'Timestamp should match');
  print('   ✅ PASSED\n');

  // Test 2: Old USER format
  print('📋 Test 2: Old USER:<user_id> Format');
  final oldUserQr = 'USER:abc123xyz789';
  final result2 = QRParser.parse(oldUserQr);
  print('   Input: $oldUserQr');
  print('   Type: ${result2.type}');
  print('   Valid: ${result2.isValid}');
  print('   User ID: ${result2.userId}');
  print('   Email: ${result2.email}');
  print('   Name: ${result2.name}');
  assert(result2.isValid, 'Old USER QR should be valid');
  assert(result2.type == QrType.user, 'Old USER QR should be type USER');
  assert(result2.userId == 'abc123xyz789', 'User ID should match');
  assert(result2.email == null, 'Email should be null for old format');
  assert(result2.name == null, 'Name should be null for old format');
  print('   ✅ PASSED\n');

  // Test 3: ITEM format
  print('📋 Test 3: ITEM:<item_id> Format');
  final itemQr = 'ITEM:BOOK001';
  final result3 = QRParser.parse(itemQr);
  print('   Input: $itemQr');
  print('   Type: ${result3.type}');
  print('   Valid: ${result3.isValid}');
  print('   Item ID: ${result3.itemId}');
  assert(result3.isValid, 'ITEM QR should be valid');
  assert(result3.type == QrType.item, 'Should be type ITEM');
  assert(result3.itemId == 'BOOK001', 'Item ID should match');
  print('   ✅ PASSED\n');

  // Test 4: TICKET format
  print('📋 Test 4: TICKET:event_id:user_id:timestamp Format');
  final ticketQr = 'TICKET:EVT001:user123:1700227200000';
  final result4 = QRParser.parse(ticketQr);
  print('   Input: $ticketQr');
  print('   Type: ${result4.type}');
  print('   Valid: ${result4.isValid}');
  if (result4.ticket != null) {
    print('   Event ID: ${result4.ticket!.eventId}');
    print('   User ID: ${result4.ticket!.userId}');
  }
  assert(result4.type == QrType.ticket, 'Should be type TICKET');
  print('   ✅ PASSED\n');

  // Test 5: Invalid JSON (missing uid)
  print('📋 Test 5: Invalid JSON Format (Missing uid)');
  final invalidJson = jsonEncode({'email': 'test@example.com'});
  final result5 = QRParser.parse(invalidJson);
  print('   Input: $invalidJson');
  print('   Type: ${result5.type}');
  print('   Valid: ${result5.isValid}');
  print('   Error: ${result5.errorMessage}');
  assert(!result5.isValid, 'Invalid JSON should not be valid');
  assert(result5.type == QrType.unknown, 'Should be type UNKNOWN');
  print('   ✅ PASSED\n');

  // Test 6: Invalid format (no colon)
  print('📋 Test 6: Invalid Format (No Separator)');
  final invalidQr = 'INVALID_QR_CODE';
  final result6 = QRParser.parse(invalidQr);
  print('   Input: $invalidQr');
  print('   Type: ${result6.type}');
  print('   Valid: ${result6.isValid}');
  print('   Error: ${result6.errorMessage}');
  assert(!result6.isValid, 'Invalid QR should not be valid');
  assert(result6.type == QrType.unknown, 'Should be type UNKNOWN');
  print('   ✅ PASSED\n');

  // Test 7: Type detection for JSON
  print('📋 Test 7: Quick Type Detection for JSON');
  final detectedType = QRParser.detectType(jsonQr);
  print('   Input: (JSON user QR)');
  print('   Detected Type: $detectedType');
  assert(detectedType == QrType.user, 'Should detect as USER type');
  print('   ✅ PASSED\n');

  // Test 8: Format validation
  print('📋 Test 8: Format Validation');
  final isValid1 = QRParser.isValidFormat(jsonQr);
  final isValid2 = QRParser.isValidFormat('USER:abc123');
  final isValid3 = QRParser.isValidFormat('INVALID');
  print('   JSON QR valid: $isValid1');
  print('   USER QR valid: $isValid2');
  print('   Invalid QR valid: $isValid3');
  assert(isValid1, 'JSON QR should be valid format');
  assert(isValid2, 'USER QR should be valid format');
  assert(!isValid3, 'Invalid QR should not be valid format');
  print('   ✅ PASSED\n');

  print('🎉 All tests passed! QR parser is working correctly.\n');
  print('📊 Summary:');
  print('   ✅ JSON user QR format supported');
  print('   ✅ Old USER:<user_id> format supported');
  print('   ✅ ITEM format supported');
  print('   ✅ TICKET format supported');
  print('   ✅ Invalid formats properly rejected');
  print('   ✅ Type detection working');
  print('   ✅ Format validation working');
}
