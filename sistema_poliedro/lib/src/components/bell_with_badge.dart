import 'package:flutter/material.dart';

class BellWithBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color? bellColor;
  final IconData iconData; // <= usa seu ícone antigo

  const BellWithBadge({
    super.key,
    required this.count,
    this.size = 24,                 // tamanho padrão igual ao Icon “normal”
    this.bellColor,
    this.iconData = Icons.notifications, // <= default: seu ícone antigo (preenchido)
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData, size: size, color: bellColor),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
