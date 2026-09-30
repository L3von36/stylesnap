import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';

class StyleSnapApp extends StatelessWidget {
  const StyleSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTypography.theme(),
      home: const RootGate(),
    );
  }
}

/// Chooses splash → onboarding vs main shell (consumer so reset works live).
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // Splash always shows first; it routes onward once done.
    return SplashScreen(next: app.onboarded ? const MainShell() : const OnboardingScreen());
  }
}
