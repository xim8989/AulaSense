import 'package:flutter/material.dart';

class AulaStyle {
  static const background = Color(0xFF0D0B2B);
  static const card = Color(0xFF1D1B45);
  static const purple = Color(0xFF9333EA);
  static const lightPurple = Color(0xFFB366FF);

  static ButtonStyle get button => ElevatedButton.styleFrom(
    backgroundColor: purple,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class AulaCard extends StatelessWidget {
  const AulaCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AulaStyle.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AulaStyle.purple.withAlpha(102)),
    ),
    child: Material(color: Colors.transparent, child: child),
  );
}

class AulaNavigation extends StatelessWidget {
  const AulaNavigation({super.key, this.currentIndex, required this.onTap});
  final int? currentIndex;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: currentIndex ?? 0,
    type: BottomNavigationBarType.fixed,
    backgroundColor: AulaStyle.card,
    selectedItemColor: currentIndex == null
        ? Colors.white54
        : AulaStyle.lightPurple,
    unselectedItemColor: Colors.white54,
    showUnselectedLabels: true,
    onTap: onTap,
    items: [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: Icon(
          currentIndex == null ? Icons.home_outlined : Icons.home,
        ),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.location_on_outlined),
        activeIcon: Icon(Icons.location_on),
        label: 'Zonas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Gráficas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.psychology_outlined),
        activeIcon: Icon(Icons.psychology),
        label: 'Análisis IA',
      ),
    ],
  );
}
