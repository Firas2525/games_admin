import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ultra-smooth hardware-accelerated Shimmer Effect for Admin
class SpecialShimmer extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final Duration duration;

  const SpecialShimmer({
    super.key,
    required this.child,
    this.isDark = true,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<SpecialShimmer> createState() => _SpecialShimmerState();
}

class _SpecialShimmerState extends State<SpecialShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? const Color(0xFF131D31)
        : const Color(0xFFE2E8F0);
    final highlightColor = widget.isDark
        ? const Color(0xFF1E2D4A)
        : const Color(0xFFF8FAFC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double progress = _controller.value;

            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                const Color(0xFF38BDF8).withValues(alpha: widget.isDark ? 0.35 : 0.25),
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: _SlidingGradientTransform(slidePercent: progress),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double translation = (slidePercent * 2.5 - 1.0) * bounds.width;
    return Matrix4.translationValues(translation, 0.0, 0.0);
  }
}

/// Mesmerizing Glowing Neon Gaming Portal Loader for Admin
class GlowGamingLoader extends StatefulWidget {
  final String message;
  final String? subtitle;
  final double size;
  final bool isDark;

  const GlowGamingLoader({
    super.key,
    this.message = 'جاري مزامنة وتحديث بيانات الإدارة...',
    this.subtitle = 'يتم فحص وتحديث السجلات والعمليات فوراً',
    this.size = 80.0,
    this.isDark = true,
  });

  @override
  State<GlowGamingLoader> createState() => _GlowGamingLoaderState();
}

class _GlowGamingLoaderState extends State<GlowGamingLoader>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    const primaryColor = Color(0xFF0284C7);
    const accentColor = Color(0xFF38BDF8);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Holographic Portal
            SizedBox(
              width: widget.size + 40,
              height: widget.size + 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Ambient Glow Backlight
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: widget.size * 0.9,
                      height: widget.size * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.22),
                            blurRadius: 36,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Outer Rotating Neon Arc
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: CustomPaint(
                          size: Size(widget.size + 20, widget.size + 20),
                          painter: _ArcPainter(
                            color: accentColor,
                            strokeWidth: 3.0,
                            sweepAngle: math.pi * 1.3,
                            startAngle: 0,
                          ),
                        ),
                      );
                    },
                  ),

                  // 3. Counter-Rotating Inner Neon Arc
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_rotationController.value * 2 * math.pi * 1.5,
                        child: CustomPaint(
                          size: Size(widget.size - 4, widget.size - 4),
                          painter: _ArcPainter(
                            color: const Color(0xFF10B981),
                            strokeWidth: 2.2,
                            sweepAngle: math.pi * 0.9,
                            startAngle: math.pi * 0.4,
                          ),
                        ),
                      );
                    },
                  ),

                  // 4. Center Core: Pulsing Admin Shield Icon with Gradient Glass
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: widget.size * 0.62,
                      height: widget.size * 0.62,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.5),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  // 5. Orbiting Particle Dot
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      final angle = _rotationController.value * 2 * math.pi;
                      final radius = (widget.size + 14) / 2;
                      return Transform.translate(
                        offset: Offset(
                          radius * math.cos(angle),
                          radius * math.sin(angle),
                        ),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor,
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Message Title with soft badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF38BDF8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.message,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  fontSize: 11.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double sweepAngle;
  final double startAngle;

  _ArcPainter({
    required this.color,
    required this.strokeWidth,
    required this.sweepAngle,
    required this.startAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.sweepAngle != sweepAngle ||
      oldDelegate.startAngle != startAngle;
}
