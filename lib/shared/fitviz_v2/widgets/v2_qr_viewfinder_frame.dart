import 'package:flutter/material.dart';
import '../theme/fitviz_v2_colors.dart';

/// White rounded card holding a QR code, framed by four independent
/// corner brackets outside the card — a viewfinder motif.
class V2QrViewfinderFrame extends StatelessWidget {
  final Widget child;

  const V2QrViewfinderFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: child,
          ),
          Positioned(top: -22, left: -22, child: _corner(topLeft: true)),
          Positioned(top: -22, right: -22, child: _corner(topRight: true)),
          Positioned(bottom: -22, left: -22, child: _corner(bottomLeft: true)),
          Positioned(bottom: -22, right: -22, child: _corner(bottomRight: true)),
        ],
      ),
    );
  }

  Widget _corner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return CustomPaint(
      size: const Size(26, 26),
      painter: _CornerBracketPainter(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerBracketPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FitVizV2Colors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path();
    const r = 8.0; // corner radius
    if (topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
      path.lineTo(size.width, 0);
    } else if (topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width - r, 0);
      path.quadraticBezierTo(size.width, 0, size.width, r);
      path.lineTo(size.width, size.height);
    } else if (bottomLeft) {
      path.moveTo(size.width, size.height);
      path.lineTo(r, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - r);
      path.lineTo(0, 0);
    } else if (bottomRight) {
      path.moveTo(0, size.height);
      path.lineTo(size.width - r, size.height);
      path.quadraticBezierTo(size.width, size.height, size.width, size.height - r);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) => false;
}
