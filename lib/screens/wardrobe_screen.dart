import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/ui_kit.dart';
import 'result_screen.dart';

/// Wardrobe — saved looks with quiet editorial cards.
class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final looks = wardrobe.looks;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wardrobe',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.8,
                          color: AppColors.ink)),
                  SizedBox(height: 2),
                  Eyebrow('Saved looks'),
                ],
              ),
            ),
          ),
          if (looks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _LookCard(look: looks[i]),
                  childCount: looks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LookCard extends StatelessWidget {
  final TryOnLook look;
  const _LookCard({required this.look});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(look.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 26),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) {
        context.read<WardrobeProvider>().remove(look.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Look removed')),
        );
      },
      child: GestureDetector(
        onTap: () => pushPage(
          context,
          ResultScreen(
            garment: _garmentFor(look),
            resultPath: look.resultPath,
            beforePath: look.beforePath ?? '',
            isDemo: look.mode == 'demo',
            mode: look.mode,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            color: AppColors.surface,
            border: Border.all(color: AppColors.hairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadii.card - 1)),
                child: SizedBox(
                  width: 96,
                  height: 108,
                  child: Image.file(File(look.resultPath), fit: BoxFit.cover),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Eyebrow(_modeLabel(look.mode)),
                          const Spacer(),
                          Text(
                            _dateLabel(look.createdAt),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10.5,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(look.garmentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'View result',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.sageDeep,
                                  letterSpacing: 0.8,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 13, color: AppColors.sageDeep),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _modeLabel(String m) =>
      m == 'live' ? 'Live mirror' : m == 'demo' ? 'Demo try-on' : 'Photo try-on';

  String _dateLabel(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

Garment _garmentFor(TryOnLook look) {
  // Reconstruct a minimal garment shell for the result screen header.
  return Garment(
    id: look.garmentId,
    name: look.garmentName,
    brand: 'StyleSnap',
    category: 'Tops',
    price: 0,
    imageAsset: 'assets/garments/white_tee.png',
    material: '',
    fit: '',
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.checkroom_rounded,
                size: 30, color: AppColors.inkFaint),
          ),
          const SizedBox(height: 20),
          Text('Nothing saved yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: Text(
              'Try on a garment and tap “Save look” — your AI fitting results will live here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
