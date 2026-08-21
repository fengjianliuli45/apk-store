import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.showHudTexture = false,
  });

  final Widget child;
  final bool showHudTexture;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showHudTexture) ...[
            SvgPicture.asset(
              'assets/figma-home/bg_dot_grid.svg',
              fit: BoxFit.cover,
            ),
            Positioned(
              top: -138,
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.55,
                  child: SvgPicture.asset(
                    'assets/figma-home/atmosphere_top.svg',
                    width: 246,
                    height: 246,
                  ),
                ),
              ),
            ),
          ],
          // Material ancestor for TextField/Switch/ripples used by pushed
          // screens — these bodies aren't wrapped in a Scaffold of their own.
          Material(
            type: MaterialType.transparency,
            child: SafeArea(child: child),
          ),
        ],
      ),
    );
  }
}
