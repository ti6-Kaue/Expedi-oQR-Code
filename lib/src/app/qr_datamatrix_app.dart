// Configuracao global do frontend Flutter.
// Observacao: aqui ficam tema, cores globais, estilo dos botoes e tela inicial.
// Comunica-se com: app_colors.dart e scanner_home_page.dart.
import 'package:flutter/material.dart';

import 'app_colors.dart';
import '../features/scanner/scanner_home_page.dart';

class QrDataMatrixApp extends StatelessWidget {
  const QrDataMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Transforma as cores da marca em um esquema usado pelos componentes Material.
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.menu)
        .copyWith(
          primary: AppColors.menu,
          onPrimary: Colors.white,
          secondary: AppColors.alert,
          onSecondary: AppColors.alertText,
          error: AppColors.alert,
          onError: AppColors.alertText,
          surface: Colors.white,
          onSurface: AppColors.textPrimary,
          surfaceContainerLowest: AppColors.background,
          surfaceContainerHighest: AppColors.footerMuted,
          primaryContainer: AppColors.footer,
          onPrimaryContainer: AppColors.textPrimary,
          secondaryContainer: AppColors.searchSubmenu,
          onSecondaryContainer: Colors.white,
          outlineVariant: AppColors.footerMuted,
        );

    // MaterialApp configura o titulo, tema e a primeira tela do aplicativo.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leitor QR Code',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(centerTitle: false),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      // ScannerHomePage sera exibida assim que o app terminar de iniciar.
      home: const ScannerHomePage(),
    );
  }
}
