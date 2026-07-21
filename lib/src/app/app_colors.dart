// Paleta oficial do app.
// Observacao: altere cores aqui para refletir no frontend inteiro.
// Comunica-se com: qr_datamatrix_app.dart e scanner_home_page.dart.
import 'package:flutter/material.dart';

class AppColors {
  // Fundo geral das telas.
  static const background = Color(0xFFF1F4F9);
  // Cores claras usadas em bordas, rodape e elementos desabilitados.
  static const footerMuted = Color(0xFFADBAD6);
  static const footer = Color(0xFFADBAD6);
  // Cor secundaria usada em etiquetas e textos auxiliares.
  static const searchSubmenu = Color(0xFF8799C1);
  // Cor principal da marca, botoes e cabecalho.
  static const menu = Color(0xFF374C92);
  // Cor principal dos textos e fundo escuro do scanner.
  static const textPrimary = Color(0xFF101236);
  // Cor de destaque para alertas e botao de abrir a camera.
  static const alert = Color(0xFFEC6607);
  static const alertText = Color(0xFFFFFFFF);
  static const scannerDark = textPrimary;
}
