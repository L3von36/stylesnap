import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/tryon_service.dart';
import '../state/app_state.dart';
import '../widgets/ui_kit.dart';
import 'result_screen.dart';
import 'live_mirror_screen.dart';

/// Garment detail — hero image, product info, size row, try-on CTAs.
class GarmentDetailScreen extends StatefulWidget {
  final Garment garment;
  const GarmentDetailScreen({super.key, required this.garment});

  @override
  State<GarmentDetailScreen> createState() => _GarmentDetailScreenState();
}

class _GarmentDetailScreenState extends State<GarmentDetailScreen> {
  late String _size =
      context.read<AppState>().size; // pre-selected from onboarding

  Future<void> _pickAndTry(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 88,
      preferredCameraDevice: CameraDevice.front,
    );
    if (xfile == null) return;
    if (!mounted) return;
    Navigator.of(context).push(FadeSlideRoute(
      page: ProcessingScreen(
        garment: widget.garment,
        personPath: xfile.path,
      ),
    ));
  }

  void _useSampleModel() {
    Navigator.of(context).push(FadeSlideRoute(
      page: ProcessingScreen(
        garment: widget.garment,
        personPath: null, // demo sample model
      ),
    ));
  }

  void _chooseTryOnMode() {
    final app = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow('Try on · ${widget.garment.name}'),
              const SizedBox(height: 18),
              _ModeTile(
                icon: Icons.photo_camera_rounded,
                title: 'Take a photo',
                subtitle: 'Full-body shot works best',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndTry(ImageSource.camera);
                },
              ),
              _ModeTile(
                icon: Icons.photo_library_rounded,
                title: 'Choose from gallery',
                subtitle: 'Use an existing photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndTry(ImageSource.gallery);
                },
              ),
              _ModeTile(
                icon: Icons.auto_awesome,
                title: 'Use sample model',
                subtitle: app.demoMode
                    ? 'Quick demo with our sample photo'
                    : 'Quick test with our sample photo',
                onTap: () {
                  Navigator.pop(context);
                  _useSampleModel();
                },
              ),
              _ModeTile(
                icon: Icons.videocam_rounded,
                title: 'Live mirror',
                subtitle: 'Real-time try-on with your camera',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(FadeSlideRoute(
                    page: LiveMirrorScreen(garment: widget.garment),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.garment;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 420,
                backgroundColor: AppColors.beige,
                surfaceTintColor: Colors.transparent,
                leading: _circleButton(context, Icons.arrow_back_rounded, () {
                  Navigator.pop(context);
                }),
                actions: [
                  _circleButton(context, Icons.favorite_border_rounded, () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Saved to favourites')),
                    );
                  }),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'garment-${g.id}',
                    child: Image.asset(g.imageAsset, fit: BoxFit.cover),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Eyebrow(g.brand),
                                const SizedBox(height: 8),
                                Text(g.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                              ],
                            ),
                          ),
                          Text(
                            money(g.price),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Cut from ${g.material.toLowerCase()}. ${g.fit}. '
                        'Try it on virtually before you buy — the AI drapes '
                        'this piece onto your photo or live camera feed.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 26),
                      Eyebrow('Size'),
                      const SizedBox(height: 12),
                      Row(
                        children: g.sizes
                            .map((s) => Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _size = s);
                                    },
                                    child: AnimatedContainer(
                                      duration: AppMotion.fast,
                                      margin:
                                          const EdgeInsets.symmetric(horizontal: 4),
                                      height: 46,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _size == s
                                            ? AppColors.ink
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(13),
                                        border:
                                            Border.all(color: AppColors.hairline),
                                      ),
                                      child: Text(
                                        s,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontSize: 13.5,
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
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Column(
                          children: [
                            _infoRow(context, Icons.texture_rounded, 'Material',
                                g.material),
                            const Divider(height: 22),
                            _infoRow(context, Icons.straighten_rounded, 'Fit', g.fit),
                            const Divider(height: 22),
                            _infoRow(context, Icons.auto_awesome_outlined,
                                'Try-on', g.demoResultAsset != null
                                    ? 'Optimised — demo preview available'
                                    : 'Supported via photo & live modes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom CTA bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 14, 24, 24 + MediaQuery.of(context).padding.bottom * 0.4),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.96),
                border: const Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Buy now',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Checkout coming soon — ${g.name} · ${money(g.price)}')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: 'Virtual try-on',
                      icon: Icons.auto_awesome,
                      onTap: _chooseTryOnMode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.inkSoft),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 3),
              Text(v, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _circleButton(BuildContext context, IconData icon, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.92),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    ),
  );
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.cardSm + 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

/// Processing screen — staged progress while the AI works.
class ProcessingScreen extends StatefulWidget {
  final Garment garment;
  final String? personPath; // null → sample model (demo)
  const ProcessingScreen({super.key, required this.garment, this.personPath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final TryOnService _service = context.read<TryOnService>();
  double _progress = 0;
  String _stage = 'Preparing';
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final sub = _service.progress.listen((p) {
      if (mounted) setState(() { _progress = p.value; _stage = p.stage; });
    });
    try {
      final outcome = await _service.tryOnPhoto(
        garment: widget.garment,
        personPath: widget.personPath,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(FadeSlideRoute(
        page: ResultScreen(
          garment: widget.garment,
          resultPath: outcome.resultPath,
          beforePath:
              outcome.beforePath ?? widget.personPath ?? '',
          isDemo: outcome.isDemo,
          note: outcome.note,
          mode: outcome.isDemo ? 'demo' : 'photo',
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Try-on failed: $e')),
      );
      Navigator.of(context).pop();
    } finally {
      sub.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.garment;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: Tween(begin: 0.97, end: 1.03)
                    .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sage.withOpacity(0.25),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: Image.asset(g.imageAsset, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text('Dressing you in ${g.name}…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 26),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: AppMotion.base,
                  curve: AppMotion.curve,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 5,
                    backgroundColor: AppColors.sand,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.sage),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('$_stage · ${(_progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
            ],
          ),
          ),
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }
}
