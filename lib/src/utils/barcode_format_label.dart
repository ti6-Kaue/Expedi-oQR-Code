// Funcoes auxiliares para exibir formato do codigo e data salva.
// Observacao: deixe aqui apenas helpers pequenos usados pela tela.
import 'package:mobile_scanner/mobile_scanner.dart';

String barcodeFormatLabel(BarcodeFormat format) {
  return switch (format) {
    BarcodeFormat.qrCode => 'QR Code',
    BarcodeFormat.dataMatrix => 'Data Matrix',
    BarcodeFormat.unknown => 'Desconhecido',
    _ => format.name,
  };
}

String formatSavedAt(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
