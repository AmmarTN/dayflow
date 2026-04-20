import 'dart:math' as math;

import 'package:dayflow/presentation/common/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MainSplashContent extends StatefulWidget {
  const MainSplashContent({super.key, required this.controller});
  final AnimationController controller;

  @override
  State<MainSplashContent> createState() => _MainSplashContentState();
}

class _MainSplashContentState extends State<MainSplashContent> with TickerProviderStateMixin {
  static const _easeOutCubic = Cubic(0.33, 1, 0.68, 1);
  // ~42% from top as an Alignment.y value: 2 * 0.42 - 1.
  static const _opticalCenterY = -0.16;

  late final AnimationController _entranceController;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _ambientController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _RadialWash(),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (_, __) => CustomPaint(painter: _FlowMotifPainter(progress: _ambientController.value)),
            ),
          ),
          Align(
            alignment: const Alignment(0, _opticalCenterY),
            child: AnimatedBuilder(
              animation: Listenable.merge([_entranceController, widget.controller]),
              builder: (_, child) {
                final entrance = _easeOutCubic.transform(_entranceController.value);
                final exit = widget.controller.value.clamp(0.0, 1.0);
                final opacity = (entrance * exit).clamp(0.0, 1.0);
                final translateY = (1 - entrance) * 6.0;
                final scale = 0.96 + 0.04 * exit;
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, translateY),
                    child: Transform.scale(scale: scale, child: child),
                  ),
                );
              },
              child: const _Wordmark(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 70.h,
            child: AnimatedBuilder(
              animation: Listenable.merge([_entranceController, widget.controller]),
              builder: (_, child) {
                final t = _easeOutCubic.transform(_entranceController.value);
                return Opacity(opacity: (t * widget.controller.value).clamp(0.0, 1.0), child: child);
              },
              child: Text(
                'YOUR DAY, IN FLOW',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  color: AppColors.darkTextMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.urbanist(
      fontSize: 44.75.sp,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
      height: 1,
      color: AppColors.darkTextPrimary,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'DayFlow'),
          TextSpan(text: '.', style: base.copyWith(color: AppColors.accentGreen)),
        ],
      ),
    );
  }
}

class _RadialWash extends StatelessWidget {
  const _RadialWash();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.16),
          radius: 0.7,
          colors: [Color(0x2D1EE468), Color(0x000A0A0A)],
          stops: [0.0, 1.0],
        ),
      ),
    );
  }
}

class _FlowMotifPainter extends CustomPainter {
  _FlowMotifPainter({required this.progress});
  final double progress;

  static const _lineCount = 7;
  static const _maxOpacity = 0.30;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.42;
    final spacing = 42.0;
    final tau = 2 * math.pi;

    for (int i = 0; i < _lineCount; i++) {
      final relative = i - (_lineCount - 1) / 2;
      final yBase = centerY + relative * spacing;
      final amplitude = 18.0 + (i % 3) * 6.0;
      final wavelength = size.width * (0.9 + (i % 2) * 0.25);
      final phase = progress * tau + i * 0.9;
      final breathe = math.sin(progress * tau + i * 0.6) * 8.0;

      final distanceFalloff = 1 - (relative.abs() / ((_lineCount - 1) / 2 + 0.5));
      final opacity = (_maxOpacity * (0.25 + 0.75 * distanceFalloff)).clamp(0.0, _maxOpacity);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accentGreen.withValues(alpha: opacity);

      final path = Path();
      const steps = 80;
      for (int s = 0; s <= steps; s++) {
        final x = size.width * s / steps;
        final t = x / wavelength;
        final y = yBase + breathe + math.sin(t * tau + phase) * amplitude;
        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlowMotifPainter old) => old.progress != progress;
}
