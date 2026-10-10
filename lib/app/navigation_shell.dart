import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/sync/outbox_sync_engine.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/messages/presentation/messages_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

class NavigationShell extends StatefulWidget {
  final OutboxSyncEngine syncEngine;

  const NavigationShell({
    super.key,
    required this.syncEngine,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        syncEngine: widget.syncEngine,
        onNavigateTab: _onTabTapped,
      ),
      const MapScreen(),
      MessagesScreen(syncEngine: widget.syncEngine),
      const CommunityScreen(),
      SettingsScreen(syncEngine: widget.syncEngine),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D101A),
          border: Border(top: BorderSide(color: Color(0xFF1E2536), width: 1.0)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', const Color(0xFFFF2A3C)),
                _buildNavItem(1, Icons.map_rounded, 'Map', const Color(0xFF38BDF8)),
                _buildNavItem(2, Icons.notifications_none_rounded, 'Alerts', const Color(0xFFF59E0B)),
                _buildNavItem(3, Icons.people_outline_rounded, 'Community', const Color(0xFF10B981)),
                _buildNavItem(4, Icons.person_outline_rounded, 'Profile', const Color(0xFF818CF8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
