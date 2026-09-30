import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import 'main_shell.dart';
import '../widgets/ui_kit.dart';

/// 3-step onboarding: style vibe → size → mode explainer.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  final Set<String> _styles = {};
  String _size = 'M';

  static const _styleOptions = {
    'Minimal': 'Clean lines, neutral palette',
    'Classic': 'Timeless tailoring',
    'Street': 'Relaxed, casual energy',
    'Romantic': 'Soft tones, florals',
    'Bold': 'Statement pieces',
    'Vintage': 'Retro cuts & prints',
  };

  static const _sizes = ['XS', 'S', 'M', 'L', 'XL'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Eyebrow('Welcome'),
                  TextButton(
                    onPressed: _finish,
                    child: Text('Skip',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.inkFaint)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _styleStep(),
                  _sizeStep(),
                  _modeStep(),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  // ---- Step 1: style ----
  Widget _styleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is your\nstyle vibe?',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 10),
          Text('Pick as many as you like — we tune the catalog for you.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _styleOptions.entries
                .map((e) => SelectChip(
                      label: e.key,
                      selected: _styles.contains(e.key),
                      onTap: () =>
                          setState(() => _styles.contains(e.key)
                              ? _styles.remove(e.key)
                              : _styles.add(e.key)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          if (_styles.isNotEmpty)
            Text(
              _styles.map((s) => _styleOptions[s]).join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  // ---- Step 2: size ----
  Widget _sizeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your usual size?',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 10),
          Text('Used to pre-select sizes on garments.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          Row(
            children: _sizes
                .map((s) => Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _size = s);
                        },
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                _size == s ? AppColors.ink : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Text(
                            s,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: _size == s
                                      ? AppColors.surface
                                      : AppColors.inkSoft,
                                ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ---- Step 3: modes ----
  Widget _modeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Two ways to\ntry things on',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 22),
          _modeCard(
            icon: Icons.bolt_rounded,
            title: 'Photo Try-On',
            desc: 'Snap or upload a full-body photo, choose a garment, and the AI dresses you. Results land in your wardrobe.',
          ),
          const SizedBox(height: 14),
          _modeCard(
            icon: Icons.videocam_rounded,
            title: 'Live Mirror',
            desc: 'Point the camera at yourself and watch outfits appear on you in real time — streamed through a GPU server.',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sageSoft,
              borderRadius: BorderRadius.circular(AppRadii.cardSm + 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.sageDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Starts in Demo mode with sample results — connect your GPU server in Profile anytime.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.sageDeep,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeCard(
      {required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.beige,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: AppColors.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(desc, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          // Progress dots
          Row(
            children: List.generate(3, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: AppMotion.fast,
                margin: const EdgeInsets.only(right: 6),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : AppColors.sand,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),
          PrimaryButton(
            label: _page == 2 ? 'Start styling' : 'Continue',
            icon: _page == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
            expand: false,
            onTap: () {
              if (_page < 2) {
                _pageCtrl.nextPage(
                    duration: AppMotion.base, curve: AppMotion.curve);
              } else {
                _finish();
              }
            },
          ),
        ],
      ),
    );
  }

  void _finish() {
    context.read<AppState>().completeOnboarding(
          size: _size,
          stylePrefs: _styles.toList(),
        );
    Navigator.of(context).pushReplacement(FadeSlideRoute(page: const MainShell()));
  }
}
