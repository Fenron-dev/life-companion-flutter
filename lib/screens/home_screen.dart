import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/auto_logger.dart';
import '../utils/theme.dart';
import '../widgets/note_modal.dart';
import 'companion_screen.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _runAutoLog();
  }

  Future<void> _runAutoLog() async {
    final db = ref.read(databaseProvider);
    final consent = ref.read(locationConsentProvider);
    final logger = AutoLogger(db);
    await logger.logToday(locationConsent: consent);
  }

  void _showNoteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NoteModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(activeTabProvider);

    final screens = [
      const DashboardScreen(),
      const JournalScreen(),
      const CompanionScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: currentTab,
          children: screens,
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: currentTab,
        onTabChanged: (i) => ref.read(activeTabProvider.notifier).state = i,
        onAddPressed: _showNoteModal,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onAddPressed;

  const _BottomNav({
    required this.currentIndex,
    required this.onTabChanged,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'DASHBOARD',
              isActive: currentIndex == 0,
              onTap: () => onTabChanged(0),
            ),
            _NavItem(
              icon: Icons.book_outlined,
              activeIcon: Icons.book,
              label: 'JOURNAL',
              isActive: currentIndex == 1,
              onTap: () => onTabChanged(1),
            ),

            // Center FAB
            GestureDetector(
              onTap: onAddPressed,
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    border: Border.all(color: AppColors.background, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ),

            _NavItem(
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: 'COMPANION',
              isActive: currentIndex == 2,
              onTap: () => onTabChanged(2),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'SETTINGS',
              isActive: currentIndex == 3,
              onTap: () => onTabChanged(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 24,
            color: isActive ? AppColors.accent : AppColors.mutedText,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: isActive ? AppColors.accent : AppColors.mutedText,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
