// Comunicacao HTTP com a API local da empresa.
// Observacao: a URL vem do build com --dart-define=API_BASE_URL=...
// Comunica-se com: scanner_home_page.dart, saved_scan.dart e POST /scans
// definido em api/src/routes/scans.js.
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/saved_scan.dart';

class RemoteScanService {
  // Valor incorporado ao APK pelo script gerar_apk.cmd.
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Sem URL configurada, o aplicativo trabalha somente com historico local.
  static bool get isConfigured => _apiBaseUrl.trim().isNotEmpty;

  static Future<void> save(SavedScan scan) async {
    if (!isConfigured) {
      return;
    }

    final baseUrl = _apiBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    // Envia JSON para a API e espera no maximo 12 segundos.
    final response = await http
        .post(
          Uri.parse('$baseUrl/scans'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(scan.toApiJson()),
        )
        .timeout(const Duration(seconds: 12));

    // Qualquer resposta fora de 200-299 e considerada erro.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteScanException(
        'API retornou HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }
}

class RemoteScanException implements Exception {
  // Excecao propria para a tela conseguir mostrar o erro retornado pela API.
  const RemoteScanException(this.message);

  final String message;

  @override
  String toString() => message;
}
