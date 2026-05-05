// Comunicacao com a API hospedada no Railway.
// Observacao: a URL vem do build com --dart-define=API_BASE_URL=...
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/saved_scan.dart';

class RemoteScanService {
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isConfigured => _apiBaseUrl.trim().isNotEmpty;

  static Future<void> save(SavedScan scan) async {
    if (!isConfigured) {
      return;
    }

    final baseUrl = _apiBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    final response = await http
        .post(
          Uri.parse('$baseUrl/scans'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(scan.toApiJson()),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteScanException(
        'API retornou HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }
}

class RemoteScanException implements Exception {
  const RemoteScanException(this.message);

  final String message;

  @override
  String toString() => message;
}
