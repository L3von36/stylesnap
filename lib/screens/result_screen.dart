import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/shared.dart';
import '../widgets/ui_kit.dart';

/// Result — before/after slider, save to wardrobe, share, download.
class ResultScreen extends StatelessWidget {
  final Garment garment;
  final String resultPath;
  final String beforePath;
  final bool isDemo;
  final String note;
  final String mode;

  const ResultScreen({
    super.key,
    required this.garment,
    required this.resultPath,
    required this.beforePath,
    required this.isDemo,
    required this.mode,
    this.note = '',
  });

  Future<void> _save(BuildContext context) async {
    final wardrobe = context.read<WardrobeProvider>();
    await wardrobe.add(TryOnLook(
      id: 'look_${DateTime.now().millisecondsSinceEpoch}',
      garmentId: garment.id,
      garmentName: garment.name,
      resultPath: resultPath,
      beforePath: beforePath.isNotEmpty ? beforePath : null,
      createdAt: DateTime.now(),
      mode: mode,
    ));
    HapticFeedback.mediumImpact();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your wardrobe')),
      );
    }
  }

  void _share(BuildContext context) {
    Share.shareXFiles(
      [XFile(resultPath)],
      text: 'Tried on the ${garment.name} with StyleSnap ✨',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.ink),
                    ),
                  ),
                  const Spacer(),
                  if (isDemo) const ModeBadge('Demo result'),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: beforePath.isNotEmpty && File(beforePath).existsSync()
                    ? Hero(
                        tag: 'result-$resultPath',
                        child: BeforeAfterSlider(
                          beforePath: beforePath,
                          afterPath: resultPath,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        child: Image.file(File(resultPath), fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow('Wearing'),
                        const SizedBox(height: 6),
                        Text(garment.name,
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                  if (beforePath.isNotEmpty && File(beforePath).existsSync())
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.sageSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swipe_rounded,
                              size: 13, color: AppColors.sageDeep),
                          const SizedBox(width: 5),
                          Text(
                            'Slide to compare',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: AppColors.sageDeep, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(note, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Share',
                      icon: Icons.ios_share_rounded,
                      onTap: () => _share(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Save look',
                      icon: Icons.bookmark_add_outlined,
                      onTap: () => _save(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
