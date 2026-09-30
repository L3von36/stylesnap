import 'package:flutter/material.dart';
import '../core/theme.dart';

/// App-wide constants.
class AppConstants {
  AppConstants._();
  static const String appName = 'StyleSnap';
  static const String tagline = 'Your AI fitting mirror';
  static const String defaultBackendUrl = 'http://10.0.2.2:8600';

  /// Instruction template sent to JoyAI-Video-Edit (RV2V).
  static const String tryOnInstructionTemplate =
      'Put the {garment} from Image 1 on the person in the video. '
      'Keep the face, pose and background unchanged.';
}

/// Uppercase eyebrow label used across the editorial layout.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(color: color ?? AppColors.inkFaint),
    );
  }
}

/// Custom page route — soft fade + rise, used for all push navigations.
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  FadeSlideRoute({required this.page})
      : super(
          transitionDuration: AppMotion.base,
          reverseTransitionDuration: AppMotion.base,
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: AppMotion.curve);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Tiny helpers.
String money(double v) => v == v.roundToDouble()
    ? '\$${v.toStringAsFixed(0)}'
    : '\$${v.toStringAsFixed(2)}';

Future<void> pushPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(FadeSlideRoute(page: page));
