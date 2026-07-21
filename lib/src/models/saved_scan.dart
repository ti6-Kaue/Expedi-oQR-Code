// Modelo de uma leitura salva.
// Observacao: usado tanto para salvar localmente quanto para enviar para a API.
// Comunica-se com: parsed_gs1_code.dart, local_scan_storage.dart,
// remote_scan_service.dart e scanner_home_page.dart.
import 'parsed_gs1_code.dart';

class SavedScan {
  const SavedScan({
    required this.value,
    required this.format,
    required this.savedAt,
  });

  factory SavedScan.fromJson(Map<String, Object?> json) {
    // Recria uma leitura que estava armazenada como JSON no aparelho.
    final savedAtValue = json['savedAt'] as String?;

    return SavedScan(
      value: json['value'] as String? ?? '',
      format: json['format'] as String? ?? 'Desconhecido',
      savedAt: savedAtValue == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse(savedAtValue) ??
                DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String value;
  final String format;
  final DateTime savedAt;

  // Tenta interpretar value como um codigo GS1.
  ParsedGs1Code? get parsedCode => ParsedGs1Code.tryParse(value);

  // Formato usado pelo historico local no SharedPreferences.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'value': value,
      'format': format,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  // Formato enviado no corpo JSON de POST /scans.
  Map<String, Object?> toApiJson() {
    final parsed = parsedCode;

    return <String, Object?>{
      'value': value,
      'format': format,
      if (parsed != null) ...parsed.toJsonFields(),
    };
  }
}
