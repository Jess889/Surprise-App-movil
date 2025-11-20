import 'package:flutter/material.dart';
import 'dart:math' as math; 

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFDBEAFE), 
              Color(0xFFF3E8FF), 
              Color(0xFFFCE7F3), 
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Surprise',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '¿Alguien dijo regalos?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 30),

                const _FeatureCard(
                  borderColor: Color(0xFF8B5CF6),
                  iconType: _IconType.star,
                  title: 'Productos Únicos',
                  subtitle: 'Peluches, gorras y más',
                ),
                const SizedBox(height: 12),
                const _FeatureCard(
                  borderColor: Color(0xFF3B82F6), 
                  iconType: _IconType.fourPointStar,
                  title: 'Personalización Total',
                  subtitle: 'Diseños a tu medida',
                ),
                const SizedBox(height: 12),
                const _FeatureCard(
                  borderColor: Color(0xFFEC4899), 
                  iconType: _IconType.heart,
                  title: 'Calidad Premium',
                  subtitle: 'Materiales de primera',
                ),
                const SizedBox(height: 40),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA78BFA), Color(0xFF60A5FA)], 
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Comenzar',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Bienvenido a tu nueva experiencia de gestión de inventarios y ventas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _IconType { star, fourPointStar, heart }

class _FeatureCard extends StatelessWidget {
  final Color borderColor;
  final _IconType iconType;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.borderColor,
    required this.iconType,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              size: const Size(24, 24),
              painter: _OutlineIconPainter(iconType, borderColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ICONOS PERSONALIZADOS (SOLO TRAZO)
// =====================================================

class _OutlineIconPainter extends CustomPainter {
  final _IconType iconType;
  final Color color;

  _OutlineIconPainter(this.iconType, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    switch (iconType) {
      case _IconType.star:
        _drawStar(path, size);
        break;
      case _IconType.fourPointStar:
        _drawFourPointStar(path, size);
        break;
      case _IconType.heart:
        _drawHeart(path, size);
        break;
    }
    canvas.drawPath(path, paint);
  }

  void _drawStar(Path path, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    const int points = 5;
    final double radiusOuter = size.width / 2;
    final double radiusInner = radiusOuter / 2.5;

    for (int i = 0; i <= points * 2; i++) {
      double angle = (i * math.pi) / points;
      double radius = i.isEven ? radiusOuter : radiusInner;
      double x = cx + radius * math.cos(angle - math.pi / 2);
      double y = cy + radius * math.sin(angle - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  void _drawFourPointStar(Path path, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    path.moveTo(cx, cy - r);
    path.lineTo(cx + r / 2, cy);
    path.lineTo(cx, cy + r);
    path.lineTo(cx - r / 2, cy);
    path.close();
  }

  void _drawHeart(Path path, Size size) {
    final double w = size.width;
    final double h = size.height;

    path.moveTo(w / 2, h * 0.75);
    path.cubicTo(w * 1.1, h * 0.4, w * 0.75, h * 0.1, w / 2, h * 0.3);
    path.cubicTo(w * 0.25, h * 0.1, w * -0.1, h * 0.4, w / 2, h * 0.75);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
