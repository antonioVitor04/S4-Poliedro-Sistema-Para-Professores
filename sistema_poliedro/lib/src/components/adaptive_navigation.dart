import 'package:flutter/material.dart';
import '../styles/cores.dart';

class AdaptiveNavigation extends StatefulWidget {
  final String currentRoute;
  final List<NavigationItem> items;
  final bool isWeb;
  final Function(String)? onTap;
  final bool profileSelected; // novo

  const AdaptiveNavigation({
    Key? key,
    required this.currentRoute,
    required this.items,
    this.isWeb = false,
    this.onTap,
    this.profileSelected = false,
  }) : super(key: key);

  @override
  State<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}

class _AdaptiveNavigationState extends State<AdaptiveNavigation> {
  String? _hoveredItem;

  @override
  Widget build(BuildContext context) {
    if (!widget.isWeb) {
      // Filtra itens para mobile, excluindo o perfil
      List<NavigationItem> filteredItems = widget.items
          .where((item) => item.route != '/perfil')
          .toList();

      // Calcula o índice atual apenas entre os itens filtrados
      int currentIndex = filteredItems.indexWhere(
        (i) => i.route == widget.currentRoute,
      );

      return BottomNavigationBar(
        currentIndex: currentIndex == -1
            ? 0
            : currentIndex, // Default para 0 se não encontrar
        onTap: (index) => widget.onTap?.call(filteredItems[index].route),
        backgroundColor: AppColors.azulEscuro,
        selectedItemColor: AppColors.preto,
        unselectedItemColor: AppColors.branco,
        type: BottomNavigationBarType.fixed,
        items: filteredItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      );
    }

    return Container(
      width: 110,
      color: AppColors.azulEscuro,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset('assets/images/logo.png', width: 70, height: 70),
          const SizedBox(height: 30),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: widget.items.map((item) {
                bool selected = widget.currentRoute == item.route;
                if (item.route == '/perfil' && widget.profileSelected) {
                  selected = true;
                }

                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredItem = item.route),
                  onExit: (_) => setState(() => _hoveredItem = null),
                  child: GestureDetector(
                    onTap: () => widget.onTap?.call(item.route),
                    child: SizedBox(
                      width: double.infinity,
                      height: 98, // altura fixa p/ não puxar os textos
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Fundo animado - alterado para branco no selecionado
                          Positioned.fill(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : (_hoveredItem == item.route
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.transparent),
                              ),
                            ),
                          ),

                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: 32,
                                color: selected
                                    ? AppColors.preto
                                    : AppColors.branco,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.preto
                                      : AppColors.branco,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
  final String route;

  NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
