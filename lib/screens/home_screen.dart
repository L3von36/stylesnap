import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../data/catalog.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/ui_kit.dart';
import '../widgets/shared.dart';
import 'garment_detail_screen.dart';

/// Home — editorial header, featured garment, category filters, catalog grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = _category == 'All'
        ? kCatalog
        : kCatalog.where((g) => g.category == _category).toList();
    final featured = kCatalog.firstWhere((g) => g.demoResultAsset != null);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('StyleSnap',
                            style:
                                Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 2),
                        Eyebrow('Virtual fitting room'),
                      ],
                    ),
                  ),
                  app.demoMode
                      ? const ModeBadge('Demo mode')
                      : ModeBadge('Live',
                          color: app.serverStatus == ServerStatus.online
                              ? AppColors.success
                              : AppColors.danger),
                ],
              ),
            ),
          ),
          // Featured hero
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: _FeaturedCard(
                garment: featured,
                onTry: () => pushPage(
                    context, GarmentDetailScreen(garment: featured)),
              ),
            ),
          ),
          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 0, 6),
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => SelectChip(
                    label: kCategories[i],
                    selected: _category == kCategories[i],
                    onTap: () =>
                        setState(() => _category = kCategories[i]),
                  ),
                ),
              ),
            ),
          ),
          // Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 110),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 26,
                crossAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _StaggeredIn(index: i, child: GarmentCard(
                  garment: items[i],
                  onTap: () => pushPage(context,
                      GarmentDetailScreen(garment: items[i])),
                )),
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Garment garment;
  final VoidCallback onTry;
  const _FeaturedCard({required this.garment, required this.onTry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTry,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          color: AppColors.ink,
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Eyebrow('Try-on ready', color: AppColors.sage),
                    const SizedBox(height: 10),
                    Text(
                      garment.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: AppColors.surface),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Try it now',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppColors.surface),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 16, color: AppColors.surface),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(AppRadii.card)),
              child: SizedBox(
                width: 130,
                child: Image.asset(garment.imageAsset, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft staggered entrance for grid cards.
class _StaggeredIn extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredIn({required this.index, required this.child});

  @override
  State<_StaggeredIn> createState() => _StaggeredInState();
}

class _StaggeredInState extends State<_StaggeredIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
      value: 0);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * (widget.index % 6)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(curved),
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}
