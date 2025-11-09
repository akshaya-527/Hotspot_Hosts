import 'package:flutter/material.dart';
import 'dart:math';

class DiagonalWavyBackground extends StatelessWidget {
  final Widget child;
  
  const DiagonalWavyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: DiagonalWavesPainter(),
        ),
        child, 
      ],
    );
  }
}

class DiagonalWavesPainter extends CustomPainter {
  @override
  
  void paint(Canvas canvas, Size size) {
    final blackPaint = Paint()..color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
      blackPaint,
    );
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height / 2));
    canvas.translate(0, size.height/2);
    canvas.rotate(-pi / 6); 

    const spacing = 40.0;
    const waveHeight = 14.0;
    const waveLength = 30.0;

    // diagonal sine-like waves
    for (double y = -size.height; y < size.height * 1.5; y += spacing) {
      final path = Path();
      path.moveTo(0, y);
      final waves = size.width * 2 / waveLength; 

      for (int i = 0; i < waves; i++) {
        path.relativeQuadraticBezierTo(
          waveLength / 4, -waveHeight,
          waveLength / 2, 0,
        );
        path.relativeQuadraticBezierTo(
          waveLength / 4, waveHeight,
          waveLength / 2, 0,
        );
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
