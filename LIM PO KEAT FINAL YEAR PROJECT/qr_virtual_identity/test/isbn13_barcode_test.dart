// test/isbn13_barcode_test.dart
// Test for exact 13-digit ISBN (EAN-13) barcode parsing

import 'package:flutter_test/flutter_test.dart';
import 'package:apid/utils/qr_parser.dart';

void main() {
  group('ISBN-13 Barcode Parsing Tests', () {
    test('Valid 13-digit ISBN should be accepted', () {
      final validISBNs = [
        '9780000000002',
        '9780131103627',
        '9780132350884',
        '9781492078005',
        '9781492071266',
      ];

      for (final isbn in validISBNs) {
        final result = QRParser.parse(isbn);
        expect(result.isValid, true, reason: 'ISBN $isbn should be valid');
        expect(
          result.type,
          QrType.item,
          reason: 'ISBN $isbn should be ITEM type',
        );
        expect(result.itemId, isbn, reason: 'ISBN $isbn should match itemId');
      }
    });

    test('Invalid length barcodes should be rejected', () {
      final invalidBarcodes = [
        '11250829', // 8 digits - TOO SHORT
        '123456789', // 9 digits - TOO SHORT
        '1234567890', // 10 digits - TOO SHORT
        '12345678901', // 11 digits - TOO SHORT
        '123456789012', // 12 digits - TOO SHORT
        '97801311036271', // 14 digits - TOO LONG
        '978013110362712', // 15 digits - TOO LONG
      ];

      for (final barcode in invalidBarcodes) {
        final result = QRParser.parse(barcode);
        expect(
          result.isValid,
          false,
          reason:
              'Barcode $barcode (${barcode.length} digits) should be REJECTED',
        );
        expect(
          result.type,
          QrType.unknown,
          reason: 'Barcode $barcode should be unknown type',
        );
        if (result.errorMessage != null) {
          expect(
            result.errorMessage!,
            contains('Invalid ISBN length'),
            reason: 'Should have clear error message about ISBN length',
          );
        }
      }
    });

    test('ITEM prefix format should still work', () {
      final itemFormats = [
        'ITEM:9780000000002',
        'ITEM:9780131103627',
        'ITEM:BOOK001', // Non-numeric also allowed with prefix
      ];

      for (final item in itemFormats) {
        final result = QRParser.parse(item);
        expect(result.isValid, true, reason: '$item should be valid');
        expect(result.type, QrType.item, reason: '$item should be ITEM type');
      }
    });

    test('Error message should be clear for wrong-length barcodes', () {
      final result = QRParser.parse('11250829');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('13 digits'));
      expect(result.errorMessage, contains('EAN-13'));
      expect(
        result.errorMessage,
        contains('8 digits'),
        reason: 'Should mention actual length scanned',
      );
    });
  });

  group('Type Detection Tests', () {
    test('detectType should recognize 13-digit ISBN', () {
      final type = QRParser.detectType('9780000000002');
      expect(type, QrType.item);
    });

    test('detectType should reject short barcodes', () {
      final type = QRParser.detectType('11250829');
      expect(type, QrType.unknown);
    });
  });
}
