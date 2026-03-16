import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 1100
        ? 460.0
        : width > 800
        ? 420.0
        : double.infinity;

    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.95),
                          AppColors.primary.withValues(alpha: 0.82),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const _PanelDecorations(),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardWidth),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      22,
                                      22,
                                      22,
                                      16,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white.withValues(alpha: 0.14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subtitle,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 34,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              height: 1.05,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          child,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.secondary.withValues(alpha: 0.9),
            AppColors.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -110,
            top: -80,
            child: _SoftCircle(
              size: 280,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            right: -90,
            bottom: -120,
            child: _SoftCircle(
              size: 340,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelDecorations extends StatelessWidget {
  const _PanelDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 48,
            top: 100,
            child: _Ribbon(width: 88, height: 18, rotate: -0.78),
          ),
          Positioned(
            left: 88,
            top: 145,
            child: _Ribbon(width: 54, height: 14, rotate: -0.72),
          ),
          Positioned(
            right: 90,
            top: 72,
            child: _Loop(size: 160),
          ),
          Positioned(
            right: 140,
            bottom: 58,
            child: _WavePair(),
          ),
          Positioned(
            left: 42,
            bottom: 42,
            child: _Loop(size: 110),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Ribbon extends StatelessWidget {
  final double width;
  final double height;
  final double rotate;

  const _Ribbon({
    required this.width,
    required this.height,
    required this.rotate,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.75),
              Colors.white.withValues(alpha: 0.45),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x66073A6B).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loop extends StatelessWidget {
  final double size;

  const _Loop({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: Colors.black.withValues(alpha: 0.16), width: 10),
      ),
    );
  }
}

class _WavePair extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _wave(),
        const SizedBox(width: 8),
        _wave(),
      ],
    );
  }

  Widget _wave() {
    return Container(
      width: 42,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 6),
      ),
    );
  }
}