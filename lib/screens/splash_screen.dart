import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Branded splash — quiet fade, wordmark rise, then hands off to [next].
class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(FadeSlideRoute(page: widget.next));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _c,
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(
                    CurvedAnimation(parent: _c, curve: AppMotion.emph)),
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/brand/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: CurvedAnimation(parent: _c, curve: const Interval(0.35, 1)),
              child: Column(
                children: [
                  Text(AppConstants.appName,
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 6),
                  Eyebrow(AppConstants.tagline.toUpperCase()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
