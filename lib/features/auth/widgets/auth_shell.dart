import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/brand_logo.dart';

/// Responsive auth layout.
/// * Wide: brand panel on the left, form on the right.
/// * Narrow: brand header with the form in a rounded sheet below.
class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final form = _FormPane(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      child: child,
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            const Expanded(flex: 5, child: _BrandPanel()),
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Gap.xxl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: FadeSlideIn(child: form),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF007E6E),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.brand),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, Gap.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BrandLogo(size: 40, showWordmark: true, light: true),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(Radii.xl + 8),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      Gap.xl,
                      Gap.xxl,
                      Gap.xl,
                      Gap.xl + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: FadeSlideIn(child: form),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormPane extends StatelessWidget {
  const _FormPane({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.headlineLarge),
                  const SizedBox(height: Gap.xs),
                  Text(
                    subtitle == 'True Root'
                        ? (title == 'Login'
                            ? 'Welcome back. Sign in to continue.'
                            : 'Create your True Root account.')
                        : subtitle,
                    style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: Gap.xl),
        child,
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.brand),
      child: Stack(
        children: [
          Positioned(
            right: -120,
            top: -120,
            child: _Glow(size: 420, opacity: 0.10),
          ),
          Positioned(
            left: -140,
            bottom: -160,
            child: _Glow(size: 480, opacity: 0.08),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLogo(size: 48, showWordmark: true, light: true),
                const Spacer(),
                const Text(
                  'Trace every harvest,\nfrom root to shelf.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: Gap.lg),
                Text(
                  'Verifiable batch history, ownership transfers and QR '
                  'provenance for every link in your agricultural supply chain.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: Gap.xxl),
                const _Feature(Icons.qr_code_2_rounded, 'Scan & verify batches instantly'),
                const _Feature(Icons.swap_horiz_rounded, 'Transparent ownership transfers'),
                const _Feature(Icons.timeline_rounded, 'Complete, tamper-evident history'),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: Radii.smAll,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: Gap.md),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}
