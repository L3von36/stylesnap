import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/ui_kit.dart';
import 'onboarding_screen.dart';

/// Profile & settings — backend connection, demo toggle, about.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl =
        TextEditingController(text: context.read<AppState>().backendUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.hairline, width: 1.5),
                  color: AppColors.surface,
                ),
                child: const Icon(Icons.person_outline_rounded,
                    size: 26, color: AppColors.inkSoft),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guest stylist',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 3),
                    Eyebrow('Size ${app.size} · ${app.stylePrefs.join(' · ')}'
                        .toUpperCase()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ----- Engine section -----
          Eyebrow('Try-on engine'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Demo mode',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 3),
                          Text(
                            'Simulated results without a GPU server',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: app.demoMode,
                      activeColor: AppColors.sage,
                      onChanged: (v) {
                        app.setDemoMode(v);
                        if (!v) app.checkServer();
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    // Status dot
                    AnimatedContainer(
                      duration: AppMotion.fast,
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: switch (app.serverStatus) {
                          ServerStatus.online => AppColors.success,
                          ServerStatus.offline => AppColors.danger,
                          ServerStatus.checking => AppColors.gold,
                          _ => AppColors.inkFaint,
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        switch (app.serverStatus) {
                          ServerStatus.online =>
                            'Bridge online · engine: ${app.serverInfo.isEmpty ? 'unknown' : app.serverInfo}',
                          ServerStatus.offline => 'Bridge unreachable',
                          ServerStatus.checking => 'Checking…',
                          _ => 'Not checked yet',
                        },
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => app.checkServer(),
                      child: const Text('Test'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlCtrl,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Bridge server URL',
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    hintText: 'http://192.168.1.20:8600',
                  ),
                  onSubmitted: (v) => app.setBackendUrl(v),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => app.setBackendUrl(_urlCtrl.text),
                    child: const Text('Save URL'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sageSoft,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.memory_rounded,
                    size: 19, color: AppColors.sageDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Real try-on needs the StyleSnap bridge running next to '
                    'JoyAI-Video-Edit on a GPU machine (≥ RTX 5090 32 GB). '
                    'See the project README for deployment steps.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.sageDeep,
                        ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ----- About -----
          Eyebrow('About'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.replay_rounded, size: 21),
                  title: Text('Replay onboarding',
                      style: Theme.of(context).textTheme.titleMedium),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.inkFaint),
                  onTap: () {
                    context.read<AppState>().resetOnboarding();
                    Navigator.of(context, rootNavigator: true)
                        .pushReplacement(FadeSlideRoute(
                            page: const OnboardingScreen()));
                  },
                ),
                const Divider(indent: 56, height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined, size: 21),
                  title: Text('Powered by JoyAI-Video-Edit',
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(
                    'Real-time open-ended video editing · Apache 2.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConstants.appName} ${AppConstants.tagline}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.inkFaint),
            ),
          ),
        ],
      ),
    );
  }
}
