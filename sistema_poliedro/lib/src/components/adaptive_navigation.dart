import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../styles/cores.dart';

class AdaptiveNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavigationItem> items;
  final bool isDesktop;

  const AdaptiveNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Mobile: BottomNavigationBar
    if (!isDesktop) {
      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: AppColors.azulClaro,
        selectedItemColor: AppColors.preto,
        unselectedItemColor: AppColors.branco,
        type: BottomNavigationBarType.fixed,
        items: items
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      );
    }

    // Desktop: Custom NavigationRail-like vertical menu
    return Container(
      width: 130,
      color: AppColors.azulEscuro,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'assets/images/logo.png',
            width: 70,
            height: 70,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: items.asMap().entries.map((entry) {
                int idx = entry.key;
                NavigationItem item = entry.value;
                return GestureDetector(
                  onTap: () => onTap(idx),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 32,
                          color: currentIndex == idx
                              ? AppColors.preto
                              : AppColors.branco,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: currentIndex == idx
                                ? AppColors.preto
                                : AppColors.branco,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;

  NavigationItem({required this.label, required this.icon});
}
