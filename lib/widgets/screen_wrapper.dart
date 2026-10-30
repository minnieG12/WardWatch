import 'dart:ui';
import 'package:flutter/material.dart';

class ScreenWrapper extends StatelessWidget {
  final Widget child;
  final String backgroundPath;
  final bool useBlur;

  const ScreenWrapper({
    super.key,
    required this.child,
    required this.backgroundPath,
    this.useBlur = false, // Changed default to false
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Changed fit to BoxFit.fill to prevent zooming
          Image.asset(backgroundPath, fit: BoxFit.fill),

          if (useBlur)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}