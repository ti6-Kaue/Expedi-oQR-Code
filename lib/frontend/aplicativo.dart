import 'package:flutter/material.dart';

import 'cores_do_aplicativo.dart';
import 'telas/pagina_inicial.dart';

class Aplicativo extends StatelessWidget {
  const Aplicativo({super.key});

  @override
  Widget build(BuildContext context) {
    final esquemaDeCores =
        ColorScheme.fromSeed(seedColor: CoresDoAplicativo.menu).copyWith(
          primary: CoresDoAplicativo.menu,
          onPrimary: Colors.white,
          secondary: CoresDoAplicativo.alert,
          onSecondary: CoresDoAplicativo.alertText,
          surface: Colors.white,
          onSurface: CoresDoAplicativo.textPrimary,
          outlineVariant: CoresDoAplicativo.footerMuted,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Layout Base',
      theme: ThemeData(
        colorScheme: esquemaDeCores,
        scaffoldBackgroundColor: CoresDoAplicativo.background,
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
      home: const PaginaInicial(),
    );
  }
}
