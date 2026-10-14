import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'services/permission_service.dart';
import 'services/referral_service.dart';
import 'features/swipe/swipe_screen_simple.dart';
import 'features/chat/chat_list_screen_simple.dart';
import 'features/profile/profile_screen_simple.dart';
import 'features/likes/likes_screen.dart';
import 'features/tools/more_screen.dart';
import 'services/rating_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  // Tab indices — used by navigation helpers and by widgets that need to
  // jump to a specific tab (e.g. the match overlay opening Mensajes).
  static const int tabDiscover = 0;
  static const int tabLikes = 1;
  static const int tabMessages = 2;
  static const int tabProfile = 3;
  static const int tabMore = 4;

  /// Switches the main navigation to [index]. Safe to call from any
  /// widget below the root (overlay buttons, deep links, notifications).
  static void selectTab(int index) => _tabSelection.value = index;

  static final ValueNotifier<int> _tabSelection = ValueNotifier(tabDiscover);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Lazy IndexedStack: each tab is built only when first visited, and stays
  // mounted afterwards so switching tabs is instant and doesn't refetch data.
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    // External tab requests (match overlay, deep links) flow through here.
    MainScreen._tabSelection.addListener(_onExternalTabRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await RatingService.showIfNeeded(context);
      if (!mounted) return;
      await ReferralService.checkAndApply();
      if (!mounted) return;
      await PermissionService.requestNotifications(context);
      if (!mounted) return;
      await PermissionService.requestLocation(context);
    });
  }

  @override
  void dispose() {
    MainScreen._tabSelection.removeListener(_onExternalTabRequest);
    super.dispose();
  }

  void _onExternalTabRequest() {
    final index = MainScreen._tabSelection.value;
    if (index < 0 || index > 4) return;
    _onTabTapped(index);
  }

  Widget _buildTab(int index) {
    if (!_visitedTabs.contains(index)) return const SizedBox.shrink();
    switch (index) {
      case 0:
        return const SwipeScreen();
      case 1:
        return const LikesScreen();
      case 2:
        return const ChatListScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const MoreScreen();
    }
  }

  void _onTabTapped(int index) {
    // Keep the notifier in sync so external consumers see the real tab.
    if (MainScreen._tabSelection.value != index) {
      MainScreen._tabSelection.value = index;
    }
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, _buildTab),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.explore,
                    label: 'Descubrir',
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.favorite_outline,
                    label: 'Likes',
                    index: 1,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Mensajes',
                    index: 2,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_outline,
                    label: 'Perfil',
                    index: 3,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.grid_view,
                    label: 'Más',
                    index: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
        highlightColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: isDarkMode ? 0.2 : 0.1)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryBlue : (isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary),
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? AppTheme.primaryBlue : (isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
