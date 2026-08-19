import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      // Material ancestor for TextField/Switch/ripples used by pushed
      // screens — these bodies aren't wrapped in a Scaffold of their own.
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(child: child),
      ),
    );
  }
}
