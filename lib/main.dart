// Entrada principal do app Flutter.
// Observacao: aqui so iniciamos o aplicativo; a tela e o tema ficam em lib/src/.
// Comunica-se com: src/app/qr_datamatrix_app.dart.
import 'package:flutter/material.dart';

import 'src/app/qr_datamatrix_app.dart';

void main() {
  // runApp entrega ao Flutter o primeiro componente da interface.
  runApp(const QrDataMatrixApp());
}
