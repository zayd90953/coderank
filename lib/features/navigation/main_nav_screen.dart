import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/app_colors.dart';
import '../../core/theme/color_palette.dart';
import '../home/presentation/home_screen.dart';
import '../practice/presentation/practice_screen.dart';
import '../leaderboard/presentation/leaderboard_screen.dart';
import '../analytics/presentation/analytics_screen.dart';

class MainNavScreen extends StatefulWidget {
  final int initialTab;

  const MainNavScreen({
    super.key,
    this.initialTab = 0,
  });

  static void switchTab(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<_MainNavScreenState>();
    if (state != null) {
      state.setTab(tabIndex);
    }
  }

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Shows a confirmation dialog and exits the app if the user confirms.
  /// Returns `true` if the back press was handled (dialog dismissed or app
  /// exited), `false` if the dialog is still open.
  Future<bool> _handleExitRequest() async {
    final palette = ColorPaletteController.instance.current;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: palette.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              "Exit CodeRank?",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to close the app?",
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant),
            child: const Text(
              "Cancel",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Exit",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      // Closing the activity is the supported way to exit on Android.
      SystemNavigator.pop();
      return true;
    }
    return true; // back is consumed either way
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const PracticeScreen(),
      const LeaderboardScreen(),
      const AnalyticsScreen(),
    ];

    return PopScope(
      // Only allow pop on the home tab. On other tabs we intercept and
      // switch to home. On the home tab we show the exit dialog.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setTab(0);
        } else {
          await _handleExitRequest();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    key: const ValueKey('nav_home'),
                    icon: Icons.home_rounded,
                    label: "Home",
                    isSelected: _currentIndex == 0,
                    onTap: () => setTab(0),
                  ),
                  _NavItem(
                    key: const ValueKey('nav_practice'),
                    icon: Icons.menu_book_rounded,
                    label: "Practice",
                    isSelected: _currentIndex == 1,
                    onTap: () => setTab(1),
                  ),
                  _NavItem(
                    key: const ValueKey('nav_rank'),
                    icon: Icons.emoji_events_rounded,
                    label: "Rank",
                    isSelected: _currentIndex == 2,
                    onTap: () => setTab(2),
                  ),
                  _NavItem(
                    key: const ValueKey('nav_analytics'),
                    icon: Icons.insights_rounded,
                    label: "Analytics",
                    isSelected: _currentIndex == 3,
                    onTap: () => setTab(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.primarySubtle
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? palette.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: palette.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
