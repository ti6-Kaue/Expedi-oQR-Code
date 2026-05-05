// Modelo de uma leitura salva.
// Observacao: usado tanto para salvar localmente quanto para enviar para a API.
import 'parsed_gs1_code.dart';

class SavedScan {
  const SavedScan({
    required this.value,
    required this.format,
    required this.savedAt,
  });

  factory SavedScan.fromJson(Map<String, Object?> json) {
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

  ParsedGs1Code? get parsedCode => ParsedGs1Code.tryParse(value);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'value': value,
      'format': format,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  Map<String, Object?> toApiJson() {
    final parsed = parsedCode;

    return <String, Object?>{
      'value': value,
      'format': format,
      if (parsed != null) ...parsed.toJsonFields(),
    };
  }
}
