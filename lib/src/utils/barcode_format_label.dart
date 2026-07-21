// Funcoes auxiliares para exibir formato do codigo e data salva.
// Observacao: deixe aqui apenas helpers pequenos usados pela tela.
// Comunica-se com: scanner_home_page.dart e mobile_scanner.
import 'package:mobile_scanner/mobile_scanner.dart';

String barcodeFormatLabel(BarcodeFormat format) {
  // Converte o valor tecnico da biblioteca em um texto para o usuario.
  return switch (format) {
    BarcodeFormat.qrCode => 'QR Code',
    BarcodeFormat.dataMatrix => 'Data Matrix',
    BarcodeFormat.unknown => 'Desconhecido',
    _ => format.name,
  };
}

String formatSavedAt(DateTime value) {
  // Converte a data para o horario local e para o formato dd/mm/aaaa hh:mm.
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
