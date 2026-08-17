import 'package:flutter/material.dart';

import '../features/home/home_page.dart';
import 'app_colors.dart';

class LayoutBaseApp extends StatelessWidget {
  const LayoutBaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.menu)
        .copyWith(
          primary: AppColors.menu,
          onPrimary: Colors.white,
          secondary: AppColors.alert,
          onSecondary: AppColors.alertText,
          surface: Colors.white,
          onSurface: AppColors.textPrimary,
          surfaceContainerLowest: AppColors.background,
          surfaceContainerHighest: AppColors.footerMuted,
          outlineVariant: AppColors.footerMuted,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Layout Base',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
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
      home: const HomePage(),
    );
  }
}
