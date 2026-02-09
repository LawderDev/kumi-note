import 'package:flutter/material.dart';
import 'package:kumi_app/core/theme/kumi_colors.dart';
import 'package:kumi_app/insights/insights.dart';
import 'package:kumi_app/journal/journal.dart';
import 'package:kumi_app/kumi_chat/kumi_chat.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Main app shell with bottom navigation for Journal, Kumi chat, and Insights
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 1; // Start on Kumi tab (center)

  final List<Widget> _pages = const [
    JournalPage(),
    ChatPage(),
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
          backgroundColor: Colors.white,
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
          items: [
            // Journal tab
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0
                      ? KumiColors.orangeAccent.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.bookOpen, size: 24),
              ),
              label: 'Flux',
            ),
            
            // Kumi chat tab (center, elevated)
            BottomNavigationBarItem(
              icon: Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1
                      ? KumiColors.orangeAccent
                      : KumiColors.orangeAccent.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: KumiColors.orangeAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '🐕',
                    style: TextStyle(
                      fontSize: 28,
                      shadows: _currentIndex == 1
                          ? [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              label: 'Kumi',
            ),
            
            // Insights tab
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2
                      ? KumiColors.orangeAccent.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.barChart3, size: 24),
              ),
              label: 'Insights',
            ),
          ],
        ),
      ),
    );
  }
}
