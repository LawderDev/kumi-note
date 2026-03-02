import 'package:flutter/material.dart';
import 'package:kumi_note/core/theme/kumi_colors.dart';
import 'package:kumi_note/insights/insights.dart';
import 'package:kumi_note/journal/view/journal_page.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Main app shell with bottom navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    JournalPage(),
    InsightsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: KumiColors.warmGray.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: KumiColors.creamBackground,
          selectedItemColor: KumiColors.orangeAccent,
          unselectedItemColor: KumiColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bookOpen, size: 24),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.barChart3, size: 24),
              label: 'Insights',
            ),
          ],
        ),
      ),
    );
  }
}
