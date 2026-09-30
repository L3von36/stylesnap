import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

/// Primary ink pill button with press-scale micro-interaction + haptics.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color = AppColors.ink,
    this.textColor = AppColors.surface,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap == null ? null : () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.sand : color,
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontSize: 14.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hairline-outlined secondary button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  const SecondaryButton({super.key, required this.label, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.button),
          border: Border.all(color: AppColors.hairline, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: AppColors.ink),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}

/// Soft sage chip used for category filters & selections.
class SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.chip + 6),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                color: selected ? AppColors.surface : AppColors.inkSoft,
              ),
        ),
      ),
    );
  }
}

/// Small uppercase mode badge (DEMO / LIVE).
class ModeBadge extends StatelessWidget {
  final String text;
  final Color color;
  const ModeBadge(this.text, {super.key, this.color = AppColors.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 9.5,
              letterSpacing: 1.4,
            ),
      ),
    );
  }
}

/// Uniform press-scale wrapper (0.975) with soft easing.
class _PressScale extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _PressScale({required this.child, this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.fast, value: 1);
  late final Animation<double> _scale =
      Tween(begin: 0.975, end: 1.0).animate(CurvedAnimation(parent: _c, curve: AppMotion.curve));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _c.reverse(),
      onTapUp: widget.onTap == null ? null : (_) => _c.forward(),
      onTapCancel: widget.onTap == null ? null : () => _c.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}

/// Shimmer placeholder for loading imagery.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius radius;
  const ShimmerBox({super.key, this.width, this.height, this.radius = const BorderRadius.all(Radius.circular(AppRadii.card))});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, -0.4),
              end: Alignment(0 + 2 * t, 0.4),
              colors: const [
                AppColors.beige,
                Color(0xFFF7F4EE),
                AppColors.beige,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}
