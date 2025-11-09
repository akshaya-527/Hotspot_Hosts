import 'dart:ui';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final double progressPercent;
  final Widget? leading, trailing, center;
  final bool showBackButton;
  final bool useGradient;

  const CustomAppBar({
    required this.progressPercent,
    this.leading,
    this.trailing,
    this.center,
    this.showBackButton = true,
    this.useGradient = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 95,
      child: Stack(
        children: [
          ClipRRect(
            child: Container(
              height: 95,
              decoration: BoxDecoration(
                gradient: useGradient
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF181820),
                          Color.fromARGB(255, 71, 71, 72),
                          Color(0xFF0F0F15),
                        ],
                      )
                    : null,
                color: useGradient ? null : const Color(0xFF0F0F15),
              ),
              child: useGradient
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(color: Colors.white.withOpacity(0.05)),
                    )
                  : null,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leading ??
                      (showBackButton
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  size: 22, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            )
                          : const SizedBox(width: 44)),

                  Expanded(
                    child: SizedBox(
                      height: 8,
                      child: CustomPaint(
                        painter: WavyProgressLinePainter(progressPercent),
                      ),
                    ),
                  ),

                  // Close icon
                  trailing ??
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 22, color: Colors.white),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
//wave line
class WavyProgressLinePainter extends CustomPainter {
  final double progress; 

  WavyProgressLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const waveHeight = 6.0;
    const waveLength = 20.0;

    Path createWave(double width) {
      final path = Path();
      path.moveTo(0, size.height / 2);
      for (double i = 0; i < width; i += waveLength) {
        path.relativeQuadraticBezierTo(
            waveLength / 4, -waveHeight, waveLength / 2, 0);
        path.relativeQuadraticBezierTo(
            waveLength / 4, waveHeight, waveLength / 2, 0);
      }
      return path;
    }

    final paintBg = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9D7BFF), Color(0xFF6A4CFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width * progress, size.height))
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(createWave(size.width), paintBg);
    canvas.drawPath(createWave(size.width * progress.clamp(0.0, 1.0)), paintFg);
  }

  @override
  bool shouldRepaint(covariant WavyProgressLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
