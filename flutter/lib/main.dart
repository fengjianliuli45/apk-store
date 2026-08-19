import 'package:flutter/material.dart';

import 'screens/root_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

void main() {
  runApp(const RestPodApp());
}

class RestPodApp extends StatelessWidget {
  const RestPodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest Pod HUD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppFonts.inter,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandGreen,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.gradientTop,
      ),
      home: const RootShell(),
    );
  }
}
