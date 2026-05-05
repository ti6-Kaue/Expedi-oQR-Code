// Modelo de uma leitura salva.
// Observacao: usado tanto para salvar localmente quanto para enviar para a API.
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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'value': value,
      'format': format,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  Map<String, Object?> toApiJson() {
    return <String, Object?>{'value': value, 'format': format};
  }
}
