import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import 'home_screen.dart';
import 'wardrobe_screen.dart';
import 'profile_screen.dart';
import 'live_mirror_screen.dart';
import 'garment_detail_screen.dart';
import '../data/catalog.dart';

/// Bottom-nav shell: Home · Wardrobe · (FAB) · Live · Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // Page slots: 0 Home · 1 Wardrobe · 2 Live · 3 Profile
    // Nav indexes: 0, 1, [FAB], 3 → Live, 4 → Profile
    final page = switch (_index) {
      0 => 0,
      1 => 1,
      3 => 2,
      _ => 3,
    };

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: page,
        children: const [
          HomeScreen(),
          WardrobeScreen(),
          LiveMirrorScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _Fab(
        active: _index == 3,
        onTap: () => setState(() => _index = 3),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _NavBar(
        index: _index,
        demoMode: app.demoMode,
        onSelect: (i) {
          if (i == 2) {
            // FAB slot — quick try-on from the first catalog item.
            final g = kCatalog.first;
            pushPage(context, GarmentDetailScreen(garment: g));
          } else {
            setState(() => _index = i);
          }
        },
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final bool demoMode;
  final ValueChanged<int> onSelect;
  const _NavBar(
      {required this.index, required this.demoMode, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            _item(context, 0, Icons.storefront_outlined, Icons.storefront, 'Shop'),
            _item(context, 1, Icons.checkroom_outlined, Icons.checkroom, 'Wardrobe'),
            const Spacer(),
            _item(context, 3, Icons.videocam_outlined, Icons.videocam, 'Live'),
            _item(context, 4, Icons.person_outline_rounded, Icons.person, 'You'),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i, IconData outline, IconData filled,
      String label) {
    final active = index == i;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? filled : outline,
                size: 22, color: active ? AppColors.ink : AppColors.inkFaint),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9.5,
                    color: active ? AppColors.ink : AppColors.inkFaint,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _Fab({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.camera_alt_rounded,
            color: AppColors.surface, size: 22),
      ),
    );
  }
}
