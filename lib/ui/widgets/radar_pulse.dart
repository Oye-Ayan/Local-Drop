import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RadarPulse extends StatefulWidget {
  final double size;
  final Widget? centerWidget;

  const RadarPulse({super.key, this.size = 130, this.centerWidget});

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric animated expanding radar rings
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RadarPainter(
                  progress: _controller.value,
                  color: AppTheme.primary,
                ),
              );
            },
          ),
          // Central glowing beacon
          widget.centerWidget ??
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceDark,
                  border: Border.all(
                    color: AppTheme.primaryLight.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wifi_tethering_rounded,
                  color: AppTheme.primaryLight,
                  size: 24,
                ),
              ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    const ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (progress + (i / ringCount)) % 1.0;
      final currentRadius = ringProgress * maxRadius;
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, currentRadius, paint);

      if (ringProgress > 0.3) {
        final fillPaint = Paint()
          ..color = color.withValues(alpha: opacity * 0.04)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, currentRadius, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
