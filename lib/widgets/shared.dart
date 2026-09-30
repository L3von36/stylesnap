import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';

/// Catalog card — editorial image, quiet caption, subtle press interaction.
class GarmentCard extends StatelessWidget {
  final Garment garment;
  final VoidCallback onTap;

  const GarmentCard({super.key, required this.garment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: 'garment-${garment.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  color: AppColors.beige,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.045),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        garment.imageAsset,
                        fit: BoxFit.cover,
                      ),
                      if (garment.demoResultAsset != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 11, color: AppColors.sageDeep),
                                const SizedBox(width: 4),
                                Text(
                                  'TRY-ON READY',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        fontSize: 8.5,
                                        color: AppColors.sageDeep,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(garment.name,
              style: Theme.of(context).textTheme.titleMedium, maxLines: 1),
          const SizedBox(height: 2),
          Text(
            '${garment.brand} · ${money(garment.price)}',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

/// Interactive before/after comparison slider (drag the handle).
class BeforeAfterSlider extends StatefulWidget {
  final String beforePath;
  final String afterPath;
  final String beforeLabel;
  final String afterLabel;

  const BeforeAfterSlider({
    super.key,
    required this.beforePath,
    required this.afterPath,
    this.beforeLabel = 'BEFORE',
    this.afterLabel = 'AFTER',
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return GestureDetector(
        onHorizontalDragUpdate: (d) =>
            setState(() => _split = (_split + d.delta.dx / w).clamp(0.05, 0.95)),
        onTapDown: (d) =>
            setState(() => _split = (d.localPosition.dx / w).clamp(0.05, 0.95)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // AFTER (full)
              Image.file(File(widget.afterPath),
                  fit: BoxFit.cover, gaplessPlayback: true),
              // BEFORE (clipped)
              ClipRect(
                clipper: _SplitClip(0, _split),
                child: Image.file(File(widget.beforePath),
                    fit: BoxFit.cover, gaplessPlayback: true),
              ),
              // Divider + handle
              Positioned(
                left: _split * w - 14,
                top: 0,
                bottom: 0,
                width: 28,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.code_rounded,
                        size: 15, color: AppColors.ink),
                  ),
                ),
              ),
              Positioned(
                left: _split * w - 0.75,
                top: 0,
                bottom: 0,
                width: 1.5,
                child: Container(color: AppColors.surface),
              ),
              // Labels
              Positioned(
                top: 12,
                left: 12,
                child: _pill(context, widget.beforeLabel),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _pill(context, widget.afterLabel),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _pill(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.surface,
              fontSize: 9,
              letterSpacing: 1.4,
            ),
      ),
    );
  }
}

class _SplitClip extends CustomClipper<Rect> {
  final double from; // 0..1
  final double to;
  _SplitClip(this.from, this.to);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(size.width * from, 0, size.width * (to - from), size.height);

  @override
  bool shouldReclip(_SplitClip old) => old.from != from || old.to != to;
}
