import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:qr_datamatrix_reader/main.dart';

void main() {
  test('SavedScan serializes stored readings', () {
    final scan = SavedScan(
      value: 'ABC-123',
      format: 'Data Matrix',
      savedAt: DateTime.utc(2026, 5, 4, 12, 30),
    );

    final restored = SavedScan.fromJson(
      jsonDecode(jsonEncode(scan.toJson())) as Map<String, Object?>,
    );

    expect(restored.value, 'ABC-123');
    expect(restored.format, 'Data Matrix');
    expect(restored.savedAt, DateTime.utc(2026, 5, 4, 12, 30));
  });

  test('formats supported barcode labels', () {
    expect(barcodeFormatLabel(BarcodeFormat.qrCode), 'QR Code');
    expect(barcodeFormatLabel(BarcodeFormat.dataMatrix), 'Data Matrix');
  });
}
